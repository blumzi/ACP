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

    _public_methods_ = ["take_exposures", "cooldown"]
    _public_attrs_ = ["set_point"]
    _label = "QHY550P: "

    def __init__(self):
        self._cam = None
        self._set_point = -5.0
        self.connected = False
        self._flip_mirror = None
        self._wise_util = win32com.client.Dispatch("Wise.Util")

    # ------------------------------------------------------------------
    # Public COM methods
    # ------------------------------------------------------------------

    @property
    def set_point(self) -> float:
        return self._set_point
    
    @set_point.setter
    def set_point(self, value: float):
        self._set_point = value

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

            cam = self._cam

            if target_temp is None:
                target_temp = self._set_point

            if not cam.CanSetCCDTemperature:
                self.error("driver does not support setting the CCD temperature")
                return False

            self.info(f"setting cooler set point to {target_temp} deg C")
            cam.CoolerOn = True
            cam.SetCCDTemperature = float(target_temp)  # ASCOM set-point property
            return True

        except Exception as e:
            # e.g. the driver raises InvalidValueException for an out-of-range set-point
            self.error(f"cooldown failed: {e}")
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
                    take_bias: bool = False) -> bool:
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
                               n, m, "light"):
                return False

        # One matching dark (optional).
        if take_dark:
            self.info("polar: dark")
            if not self.expose(duration, base_fits_file_name, gain, offset,
                               None, None, "dark"):
                return False

        # One bias (optional).
        if take_bias:
            self.info("polar: bias")
            if not self.expose(duration, base_fits_file_name, gain, offset,
                               None, None, "bias"):
                return False

        # Park the mirror at "main".
        if not self.flip_mirror_to_camera("main"):
            return False

        return True

    def expose(self,
               duration: float,
               base_fits_file_name: str,
               gain: int | None = None,
               offset: int | None = None,
               n: int | None = None,
               m: int | None = None,
               frame_type: Literal["light", "dark", "bias"] = "light") -> bool:
        """
        Take a single exposure of the given frame type and save it as a FITS file.

        frame_type drives mirror position, the ASCOM Light flag and the exposure
        duration:
          - "light": mirror -> polar, Light=True,  exposure = duration
          - "dark" : mirror -> main,  Light=False, exposure = duration
          - "bias" : mirror -> main,  Light=False, exposure = ExposureMin
        With the mirror at "main" the (shutterless) polar sensor sees no light,
        so it acts as a closed shutter for dark/bias frames.

        Parameters
        ----------
        duration            : float   Exposure duration in seconds
        base_fits_file_name : str     Base name for the output FITS file
        gain                : int     Camera gain (0 = driver default)
        offset              : int     Camera offset (0 = driver default)
        frame_type          : str     "light", "dark" or "bias"

        Returns
        -------
        bool  True on success, False on failure
        """
        try:
            if self._cam is None or not self._cam.Connected:
                if not self.connect():
                    return False

            cam = self._cam

            self.info(f"name: {cam.Name}")
            self.info(f"size: {cam.CameraXSize}x{cam.CameraYSize}")
            self.info(f"driver version: {cam.DriverVersion}")

            if duration < cam.ExposureMin or duration > cam.ExposureMax:
                self.error(f"duration {duration} is out of range [{cam.ExposureMin}, {cam.ExposureMax}]")
                return False

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

            # Set offset if the driver supports it
            try:
                self.info(f"setting offset to {offset}")
                cam.Offset = offset
            except Exception as ex:
                self.warning(f"failed to set offset: {ex=}")

            if cam.CCDTemperature >= self.set_point:
                self.warning(f"camera temperature ({cam.CCDTemperature} deg C) is above set point ({self.set_point} deg C)")

            # Frame-type-specific exposure parameters.
            if frame_type == "light":
                camera, light_flag, exp_duration = "polar", True, float(duration)
            elif frame_type == "dark":
                camera, light_flag, exp_duration = "main", False, float(duration)
            elif frame_type == "bias":
                camera, light_flag, exp_duration = "main", False, float(cam.ExposureMin)
            else:
                self.error(f"unknown frame_type '{frame_type}'")
                return False

            # Point ("polar") or block ("main") the beam, then expose.
            if not self.flip_mirror_to_camera(camera):
                return False
            self.info(f"starting {exp_duration} seconds {frame_type} exposure")
            cam.StartExposure(exp_duration, light_flag)
            return self._readout(cam, exp_duration, base_fits_file_name, frame_type, n, m)

        except Exception as e:
            self.error(traceback.format_exc())
            return False

    def _readout(self,
                 cam,
                 duration: float,
                 base_fits_file_name: str,
                 frame_type: Literal["light", "dark", "bias"] = "light",
                 n: int | None = None,
                 m: int | None = None) -> bool:
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
                match state:
                    case 0: state_str = "idle"
                    case 1: state_str = "waiting"
                    case 2: state_str = "exposing"
                    case 3: state_str = "readingout"
                    case 4: state_str = "downloading"
                    case 5: state_str = "error"
                    case _: state_str = f"unknown({state})"

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
            hdr["EXPTIME"]  = (float(duration), "Exposure time in seconds")
            hdr["EXPOSURE"] = (float(duration), "Exposure time in seconds")
            hdr["DATE-OBS"] = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())
            hdr["GAIN"]     = (cam.Gain, "Camera gain setting")

            try:
                hdr["OFFSET"] = (cam.Offset, "Camera offset setting")
            except Exception:
                pass

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

            filter = parts[1]
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