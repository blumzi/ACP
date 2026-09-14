"""
QHY550P Python COM Server
Exposes a COM object with progid "Wise.H80.QHY550P" that wraps
the ASCOM QHYCCD_GUIDER camera driver and saves images as FITS.

Register:   python qhy550p_com.py --register
Unregister: python qhy550p_com.py --unregister
"""

import time
import traceback
from typing import Literal
import numpy as np
import pythoncom
import win32com.client
from astropy.io import fits


class QHY550P:
    # --- COM registration ---
    _reg_clsid_      = "{b47a9cea-f5d1-4454-8633-23adaa4b4faa}"
    _reg_desc_       = "QHY550P ASCOM Camera COM Server (python)"
    _reg_progid_     = "Wise.H80.QHY550P"
    _reg_threading_  = "Apartment"
    _reg_policy_     = None
    _reg_class_spec_ = "QHY550P.QHY550P"
    _reg_clsctx_ = pythoncom.CLSCTX_LOCAL_SERVER

    _public_methods_ = ["take_exposures", "cooldown", "warmup",
                        "begin_exposures", "start_next_frame",
                        "read_current_frame", "abort_exposures", "park_mirror"]
    _public_attrs_ = ["set_point", "image_ready", "camera_state"]
    _label = "QHY550P: "

    def __init__(self):
        self._cam = None
        self._set_point = -5.0
        self.connected = False
        self._flip_mirror = None
        self._wise_util = win32com.client.Dispatch("Wise.Util")
        # State for the interruptible (pollable) exposure sequence. See
        # begin_exposures()/start_next_frame()/read_current_frame() below.
        self._plan = []             # list of {frame_type, n, m[, exp_duration]}
        self._plan_index = 0
        self._current_frame = None
        self._seq = None            # common params for the running sequence
        self._aborted = False

    # ------------------------------------------------------------------
    # Public COM methods
    # ------------------------------------------------------------------

    @property
    def set_point(self) -> float:
        return self._set_point
    
    @set_point.setter
    def set_point(self, value: float):
        self._set_point = value

    @property
    def image_ready(self) -> bool:
        """True once the in-progress exposure has been read off the sensor.

        Cheap to poll; the JScript sequence loop calls this between
        Util.WaitForMilliseconds waits so ACP can deliver an Abort mid-exposure.
        """
        try:
            cam = self._cam
            return bool(cam is not None and cam.Connected and cam.ImageReady)
        except Exception:
            return False

    @property
    def camera_state(self) -> str:
        """The driver's CameraState as a short word ("exposing", "readingout", ...).

        Cheap to poll; the JScript sequence loop reads it every few seconds to
        report progress while an exposure is integrating.
        """
        try:
            cam = self._cam
            if cam is None or not cam.Connected:
                return "disconnected"
            return self._state_text(cam.CameraState)
        except Exception:
            return "unknown"

    @staticmethod
    def _state_text(state) -> str:
        """ASCOM CameraStates value -> short word."""
        match state:
            case 0: return "idle"
            case 1: return "waiting"
            case 2: return "exposing"
            case 3: return "readingout"
            case 4: return "downloading"
            case 5: return "error"
            case _: return f"unknown({state})"

    def connect(self) -> bool:
        """Connect to the ASCOM QHYCCD_GUIDER camera driver."""
        try:
            self._cam = win32com.client.Dispatch("ASCOM.QHYCCD_GUIDER.Camera")
            self._cam.Connected = True
            self.connected = True
            return True
        except Exception as e:
            self.error(f"connect failed: {e}")
            self.connected = False
            return False

    def _engage_cooler(self, target_temp: float | None = None) -> bool:
        """
        Turn the cooler on at `target_temp` (default: self.set_point) on the
        current connection. Idempotent; safe to call repeatedly.

        The QHYCCD_GUIDER driver reports a fixed 25.0 placeholder for
        CCDTemperature (and 0.0 for the set-point) until the cooler is engaged
        on THIS connection -- cooler state is not shared across connections.
        cooldown() and expose() use separate connections, so each must engage
        the cooler to read a valid temperature.
        """
        try:
            cam = self._cam
            if cam is None:
                return False
            if not cam.CanSetCCDTemperature:
                self.warning("driver cannot set CCD temperature; leaving cooler as-is")
                return False
            if target_temp is None:
                target_temp = self._set_point
            cam.SetCCDTemperature = float(target_temp)  # ASCOM set-point property
            cam.CoolerOn = True
            return True
        except Exception as e:
            self.warning(f"could not engage cooler: {e}")
            return False

    def disconnect(self) -> bool:
        """Disconnect from the camera."""
        try:
            if self._cam is not None:
                self._cam.Connected = False
                self._cam = None
            self.connected = False
            return True
        except Exception as e:
            self.error(f"disconnect failed: {e}")
            return False
        
    def cooldown(self, target_temp: float | None = None) -> bool:
        """
        Command the cooler to a target set-point (degrees Celsius).

        Fire-and-forget: this sets the set-point and returns immediately; it does
        not wait for the sensor to reach temperature.
        """
        try:
            if self._cam is None or not self._cam.Connected:
                if not self.connect():
                    return False

            if target_temp is None:
                target_temp = self._set_point

            self.info(f"setting cooler set point to {target_temp} deg C")
            return self._engage_cooler(target_temp)

        except Exception as e:
            # e.g. the driver raises InvalidValueException for an out-of-range set-point
            self.error(f"cooldown failed: {e}")
            return False

    def warmup(self) -> bool:
        """
        Warm the sensor back toward ambient: raise the set-point and switch the
        cooler off.

        The QHY550P runs at a mild set-point (~-5 C), so no gradual hardware
        ramp is needed; turning the cooler off lets it drift up to ambient
        safely. Fire-and-forget: returns immediately, it does not wait to reach
        ambient.
        """
        try:
            if self._cam is None or not self._cam.Connected:
                if not self.connect():
                    return False

            cam = self._cam
            assert cam is not None and cam.connected, "camera not connected"

            try:
                if cam.CanSetCCDTemperature:
                    self.info("warmup: raising set point to 5 deg C")
                    cam.SetCCDTemperature = 5.0
            except Exception as ex:
                self.warning(f"warmup: could not raise set-point: {ex}")

            cam.CoolerOn = False
            self.info("warmup: cooler off; sensor will drift to ambient")
            return True

        except Exception as e:
            self.error(f"warmup failed: {e}")
            return False

    def info(self, msg: str):
        self._wise_util.info(self._label + msg)

    def debug(self, msg: str):
        self._wise_util.debug(self._label + msg)

    def warning(self, msg: str):
        self._wise_util.warning(self._label + msg)

    def error(self, msg: str):
        self._wise_util.error(self._label + msg)

    def flip_mirror_to_camera(self, camera: str, timeout: float = 120.0) -> bool:
        """
        Move the Baader flip mirror so it directs light to `camera` ("main" or
        "polar") and wait until it reports arrival.

        Pointing at "polar" sends the beam to the QHY550P for a light frame;
        pointing at "main" leaves the polar sensor in the dark, acting as a
        "closed shutter" for dark/bias frames (the QHY550P is shutterless).

        Dispatches its own Wise.H80.FlipMirror instance (a stateless HTTP shim
        to the device), so it does not depend on the caller's COM object.

        Returns True once the mirror is at `camera`, False on timeout.
        """
        try:
            if self._flip_mirror is None:
                self._flip_mirror = win32com.client.Dispatch("Wise.H80.FlipMirror")
            fm = self._flip_mirror

            if fm.CurrentCamera() == camera:
                return True

            self.info(f"flip mirror -> '{camera}'")
            fm.SelectCamera(camera)

            start = time.time()
            while fm.CurrentCamera() != camera:
                if time.time() - start > timeout:
                    self.error(f"flip mirror: timeout after {timeout}s waiting to reach '{camera}'")
                    return False
                time.sleep(1.0)

            self.info(f"flip mirror: at '{camera}'")
            return True

        except Exception as e:
            self.error(f"flip_mirror_to_camera failed: {e}")
            return False

    def take_exposures(self,
                    duration: float,
                    base_fits_file_name: str,
                    gain: int | None = None,
                    offset: int | None = None,
                    number_of_exposures: int = 1,
                    take_dark: bool = False,
                    take_bias: bool = False,
                    object_name: str = "") -> bool:
        """
        Take `number_of_exposures` exposures in sequence, each a light frame
        (plus an optional matching dark and/or bias), saving every frame as a
        FITS file.

        This owns the frame sequence; each frame delegates to expose(). The
        light frames are numbered n-of-m; the optional dark and bias are taken
        once each (unnumbered). The mirror is left parked at "main".

        Returns True if every frame succeeded, False on the first failure.
        """
        m = int(number_of_exposures) if number_of_exposures else 1

        # Light frames.
        for n in range(1, m + 1):
            self.info(f"polar: light {n} of {m}")
            if not self.expose(duration, base_fits_file_name, gain, offset,
                               n, m, "light", object_name):
                return False

        # One matching dark (optional).
        if take_dark:
            self.info("polar: dark")
            if not self.expose(duration, base_fits_file_name, gain, offset,
                               None, None, "dark", object_name):
                return False

        # One bias (optional).
        if take_bias:
            self.info("polar: bias")
            if not self.expose(duration, base_fits_file_name, gain, offset,
                               None, None, "bias", object_name):
                return False

        # Park the mirror at "main".
        if not self.flip_mirror_to_camera("main"):
            return False

        return True

    # ------------------------------------------------------------------
    # Interruptible (pollable) exposure sequence
    #
    # take_exposures() runs a whole sequence in one blocking COM call, so ACP
    # cannot deliver an Abort until it returns (up to number_of_exposures *
    # duration seconds). These four entry points let the ACP (JScript) side
    # drive the sequence one frame at a time and, crucially, poll image_ready
    # between Util.WaitForMilliseconds waits -- which is where ACP delivers an
    # Abort (user button or Scheduler dawn-stop). The camera is only ever
    # touched by this single COM apartment thread; no background threads.
    #
    #   begin_exposures(...)              # plan the frames, connect, cool
    #   while start_next_frame() != "":   # StartExposure for the next frame
    #       while not image_ready: wait   # <-- ACP Abort delivered in this wait
    #       read_current_frame()          # read + save the FITS
    #   abort_exposures()                 # AbortExposure + park mirror (on stop)
    # ------------------------------------------------------------------

    def begin_exposures(self,
                        duration: float,
                        base_fits_file_name: str,
                        gain: int | None = None,
                        offset: int | None = None,
                        number_of_exposures: int = 1,
                        take_dark: bool = False,
                        take_bias: bool = False,
                        object_name: str = "") -> bool:
        """
        Plan (but do not yet start) an interruptible frame sequence: a light
        frame numbered n-of-m for each of number_of_exposures, plus an optional
        single dark and/or bias. Connects and re-asserts the cooler up front.

        Non-blocking. Drive the sequence with start_next_frame() / image_ready /
        read_current_frame(); stop it early with abort_exposures().
        """
        try:
            m = int(number_of_exposures) if number_of_exposures else 1
            plan = [{"frame_type": "light", "n": n, "m": m} for n in range(1, m + 1)]
            if take_dark:
                plan.append({"frame_type": "dark", "n": None, "m": None})
            if take_bias:
                plan.append({"frame_type": "bias", "n": None, "m": None})

            self._plan = plan
            self._plan_index = 0
            self._current_frame = None
            self._aborted = False
            self._seq = {"duration": float(duration),
                         "base": base_fits_file_name,
                         "gain": gain,
                         "offset": offset,
                         "object": object_name}

            if self._cam is None or not self._cam.Connected:
                if not self.connect():
                    return False
            self._engage_cooler()

            self.info(f"polar: sequence of {len(plan)} frame(s) prepared")
            return True
        except Exception:
            self.error(traceback.format_exc())
            self._aborted = True
            return False

    def start_next_frame(self) -> str:
        """
        Start the next frame's exposure (mirror move + StartExposure) and return
        a short label like "light 2 of 5" (or "dark"/"bias"). Returns "" when the
        plan is exhausted or the sequence was aborted.

        Apart from the bounded flip-mirror move, this returns immediately after
        StartExposure -- the caller polls image_ready while the sensor integrates.
        """
        try:
            if self._aborted or self._plan_index >= len(self._plan):
                return ""

            fr = self._plan[self._plan_index]
            seq = self._seq
            exp = self._start_frame(seq["duration"], seq["gain"], seq["offset"],
                                    fr["frame_type"])
            if exp is None:
                self._aborted = True
                return ""

            fr["exp_duration"] = exp
            self._current_frame = fr
            self._plan_index += 1

            n, m, ft = fr["n"], fr["m"], fr["frame_type"]
            return f"{ft} {n} of {m}" if (n and m) else ft
        except Exception:
            self.error(traceback.format_exc())
            self._aborted = True
            return ""

    def read_current_frame(self) -> bool:
        """
        Read out and save the frame started by start_next_frame(). Call once
        image_ready is True. Returns True on success.
        """
        try:
            fr = self._current_frame
            if fr is None:
                return False
            seq = self._seq
            ok = self._readout(self._cam, fr["exp_duration"], seq["base"],
                               fr["frame_type"], fr["n"], fr["m"], seq["object"])
            self._current_frame = None
            return ok
        except Exception:
            self.error(traceback.format_exc())
            return False

    def abort_exposures(self) -> bool:
        """
        Abort any in-progress exposure and end the sequence, then park the mirror
        at "main". Idempotent and safe to call at any time (e.g. from the ACP
        side when a run is being aborted). Never raises.
        """
        self._aborted = True
        self._current_frame = None
        try:
            cam = self._cam
            if cam is not None and cam.Connected and getattr(cam, "CanAbortExposure", False):
                cam.AbortExposure()
                self.info("polar: exposure aborted")
        except Exception as e:
            self.warning(f"abort_exposures: could not abort exposure: {e}")
        try:
            self.flip_mirror_to_camera("main")
        except Exception as e:
            self.warning(f"abort_exposures: could not park mirror: {e}")
        return True

    def park_mirror(self) -> bool:
        """Park the flip mirror at the main camera. Returns True on success."""
        return self.flip_mirror_to_camera("main")

    def _start_frame(self,
                     duration: float,
                     gain: int | None,
                     offset: int | None,
                     frame_type: Literal["light", "dark", "bias"] = "light") -> float | None:
        """
        Configure the camera for one frame and START the exposure. Returns the
        actual exposure duration used (seconds), or None on failure.

        This is the non-blocking front half of a single frame: it does NOT wait
        for or read out the image. frame_type drives mirror position, the ASCOM
        Light flag and the exposure duration:
          - "light": mirror -> polar, Light=True,  exposure = duration
          - "dark" : mirror -> main,  Light=False, exposure = duration
          - "bias" : mirror -> main,  Light=False, exposure = ExposureMin
        With the mirror at "main" the (shutterless) polar sensor sees no light,
        so it acts as a closed shutter for dark/bias frames.
        """
        try:
            if self._cam is None or not self._cam.Connected:
                self.info("camera not connected, attempting to connect...")
                if not self.connect():
                    return None

            cam = self._cam
            assert cam is not None and cam.connected, "camera not connected"

            # Engage the cooler on this connection so the driver reports the
            # real CCDTemperature (see _engage_cooler) rather than its 25.0
            # placeholder; the sensor is already held cold by the cooldown at
            # ScriptStart, so this just re-asserts on the exposure connection.
            self._engage_cooler()

            self.info(f"name: {cam.Name}")
            self.info(f"size: {cam.CameraXSize}x{cam.CameraYSize}")
            self.info(f"driver version: {cam.DriverVersion}")

            if duration < cam.ExposureMin or duration > cam.ExposureMax:
                self.error(f"duration {duration} is out of range [{cam.ExposureMin}, {cam.ExposureMax}]")
                return None

            self.info(f"setting binning = 1")
            cam.BinX = 1
            cam.BinY = 1

            self.info(f"setting full frame")
            cam.StartX = 0
            cam.StartY = 0
            cam.NumX = cam.CameraXSize
            cam.NumY = cam.CameraYSize

            # Set gain if the driver supports it
            if gain is not None:
                if (gain < cam.GainMin) or (gain > cam.GainMax):
                    self.warning(f"gain {gain} is out of range [{cam.GainMin}, {cam.GainMax}], ignoring.")
                else:
                    try:
                        self.info(f"setting gain to {gain}")
                        cam.Gain = gain
                    except Exception as ex:
                        self.warning(f"failed to set gain: {ex=}")

            # This driver does not support offset.
            # try:
            #     self.info(f"setting offset to {offset}")
            #     cam.Offset = offset
            # except Exception as ex:
            #     self.warning(f"failed to set offset: {ex=}")

            TOO_HOT = 0.5  # deg C above set-point
            if cam.CCDTemperature - self.set_point > TOO_HOT:
                self.warning(f"camera temperature ({cam.CCDTemperature} deg C) is more than {TOO_HOT} deg C above set point ({self.set_point} deg C)")

            # Frame-type-specific exposure parameters.
            if frame_type == "light":
                camera, light_flag, exp_duration = "polar", True, float(duration)
            elif frame_type == "dark":
                camera, light_flag, exp_duration = "main", False, float(duration)
            elif frame_type == "bias":
                camera, light_flag, exp_duration = "main", False, float(cam.ExposureMin)
            else:
                self.error(f"unknown frame_type '{frame_type}'")
                return None

            # Point ("polar") or block ("main") the beam, then expose.
            if not self.flip_mirror_to_camera(camera):
                return None
            self.info(f"starting {exp_duration} seconds {frame_type} exposure")
            cam.StartExposure(exp_duration, light_flag)
            return exp_duration

        except Exception:
            self.error(traceback.format_exc())
            return None

    def expose(self,
               duration: float,
               base_fits_file_name: str,
               gain: int | None = None,
               offset: int | None = None,
               n: int | None = None,
               m: int | None = None,
               frame_type: Literal["light", "dark", "bias"] = "light",
               object_name: str = "") -> bool:
        """
        Take a single exposure of the given frame type and save it as a FITS file.

        Blocking convenience wrapper used by take_exposures(): start the frame,
        wait for it (inside _readout), then save. For the interruptible path the
        ACP side calls _start_frame()'s public cousins instead (start_next_frame /
        image_ready / read_current_frame).

        Returns True on success, False on failure.
        """
        exp_duration = self._start_frame(duration, gain, offset, frame_type)
        if exp_duration is None:
            return False
        return self._readout(self._cam, exp_duration, base_fits_file_name,
                             frame_type, n, m, object_name)

    def _readout(self,
                 cam,
                 duration: float,
                 base_fits_file_name: str,
                 frame_type: Literal["light", "dark", "bias"] = "light",
                 n: int | None = None,
                 m: int | None = None,
                 object_name: str = "") -> bool:
        """
        Wait for the in-progress exposure to finish, retrieve the image array,
        build the FITS header and write the file.

        Assumes StartExposure has already been called on `cam`.
        """
        try:
            # Wait for image to be ready
            timeout = duration + 30.0  # generous timeout
            start = time.time()
            last_console_log_time = 0.0
            last_state = None
            last_state_str = None

            while not cam.ImageReady:
                state = cam.CameraState
                state_str = self._state_text(state)

                if last_state != state:
                    self.info(f"state: changed from {last_state_str} to {state_str}")
                    last_console_log_time = time.time()
                    last_state = state
                    last_state_str = state_str

                elif time.time() - last_console_log_time > 5.0:  # Log every 5 seconds
                    self.info(f"state: {state_str} (elapsed: {int(time.time() - start)}s)")
                    last_console_log_time = time.time()

                if time.time() - start > timeout:
                    self.error(f"Timeout after {timeout} seconds waiting for ImageReady ")
                    return False

                time.sleep(1.0)
            self.debug("image is ready")

            # Retrieve image array
            img_variant = cam.ImageArrayVariant
            vbarray_data = img_variant  # comes in as a nested tuple via pythoncom

            # Convert to numpy array as 16-bit unsigned ints.
            arr = np.array(vbarray_data, dtype=np.uint16)

            # Reorient to match the MaxIm DL frame. The QHY550P/ASCOM readout
            # comes off the sensor mirrored and rotated relative to how MaxIm DL
            # presents the same camera. Flip left-right, then rotate 90 deg
            # clockwise, so polar frames share the orientation of the main-camera
            # (MaxIm DL) images of the same field.
            arr = np.ascontiguousarray(np.rot90(np.fliplr(arr), 3))

            # Conventional IMAGETYP values (MaxIm DL / ACP convention).
            image_type = {
                "light": "Light Frame",
                "dark":  "Dark Frame",
                "bias":  "Bias Frame",
            }.get(frame_type, "Light Frame")

            # Build FITS header
            hdr = fits.Header()
            hdr["SIMPLE"]   = True
            hdr["INSTRUME"] = "QHY550P"
            hdr["IMAGETYP"] = (image_type, "Frame type")
            hdr["OBJECT"]   = (object_name, "Target / object name")
            hdr["EXPTIME"]  = (float(duration), "Exposure time in seconds")
            hdr["EXPOSURE"] = (float(duration), "Exposure time in seconds")
            hdr["DATE-OBS"] = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())
            hdr["GAIN"]     = (cam.Gain, "Camera gain setting")

            # try:
            #     hdr["OFFSET"] = (cam.Offset, "Camera offset setting")
            # except Exception:
            #     pass

            try:
                hdr["CCD-TEMP"] = (cam.CCDTemperature, "CCD temperature deg C")
            except Exception:
                pass

            try:
                hdr["SET-TEMP"] = (float(self.set_point), "CCD temperature set point deg C")
            except Exception:
                pass

            try:
                hdr["XPIXSZ"] = (cam.PixelSizeX, "Pixel size X microns")
                hdr["YPIXSZ"] = (cam.PixelSizeY, "Pixel size Y microns")
            except Exception:
                pass

            try:
                hdr["XBINNING"] = cam.BinX
                hdr["YBINNING"] = cam.BinY
            except Exception:
                pass

            parts = base_fits_file_name.split("-")

            filter = parts[2].strip()
            hdr["FILTER"] = filter

            # Write FITS
            parts[2] = f"{int(duration):03d}s"
            fits_file = '-'.join(parts).replace(".fts", "-polar.fts")
            if n is not None and m is not None:
                fits_file = fits_file.replace(".fts", f"-{n}_of_{m}.fts")
            if frame_type in ("dark", "bias"):
                fits_file = fits_file.replace(".fts", f"_{frame_type}.fts")
            hdu = fits.PrimaryHDU(data=arr, header=hdr)
            hdu.writeto(str(fits_file), overwrite=True)
            self.debug(f"wrote {fits_file=}")

            return True

        except Exception as e:
            self.error(traceback.format_exc())
            return False

# ------------------------------------------------------------------
# Registration entry point
# ------------------------------------------------------------------
import sys
import os
import winreg

CLSID  = "{b47a9cea-f5d1-4454-8633-23adaa4b4faa}"
PROGID = "Wise.H80.QHY550P"
DESC   = "QHY550P ASCOM Camera COM Server (python)"
SCRIPT = os.path.abspath(__file__)
PYTHON = sys.executable.replace("python.exe", "pythonw.exe")

ACCESS = winreg.KEY_SET_VALUE | winreg.KEY_CREATE_SUB_KEY | winreg.KEY_WOW64_32KEY

def _write(subkey, value):
    key = winreg.CreateKeyEx(
        winreg.HKEY_LOCAL_MACHINE,
        f"SOFTWARE\\Classes\\{subkey}",
        0,
        ACCESS
    )
    winreg.SetValueEx(key, "", 0, winreg.REG_SZ, value)
    winreg.CloseKey(key)
    print(f"  wrote: HKLM\\SOFTWARE\\WOW6432Node\\Classes\\{subkey} = {value}")

def register():
    print("Registering...")
    _write(PROGID,                              DESC)
    _write(f"{PROGID}\\CLSID",                 CLSID)
    _write(f"CLSID\\{CLSID}",                  DESC)
    _write(f"CLSID\\{CLSID}\\ProgID",          PROGID)
    _write(f"CLSID\\{CLSID}\\LocalServer32",   f'"{PYTHON}" "{SCRIPT}"')
    _write(f"CLSID\\{CLSID}\\PythonCOM",       "qhy550p_com.QHY550P")
    print("Done.")

def unregister():
    import contextlib
    print("Unregistering...")
    for subkey in [
        f"CLSID\\{CLSID}\\LocalServer32",
        f"CLSID\\{CLSID}\\ProgID",
        f"CLSID\\{CLSID}\\PythonCOM",
        f"CLSID\\{CLSID}",
        f"{PROGID}\\CLSID",
        PROGID,
    ]:
        with contextlib.suppress(Exception):
            winreg.DeleteKeyEx(
                winreg.HKEY_LOCAL_MACHINE,
                f"SOFTWARE\\Classes\\{subkey}",
                winreg.KEY_WOW64_32KEY,
                0
            )
            print(f"  deleted: {subkey}")
    print("Done.")

if __name__ == "__main__":
    if "--register" in sys.argv:
        register()
    elif "--unregister" in sys.argv:
        unregister()
    else:
        import win32com.server.localserver
        win32com.server.localserver.serve([CLSID])