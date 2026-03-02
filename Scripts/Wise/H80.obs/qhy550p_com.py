"""
QHY550P Python COM Server
Exposes a COM object with progid "Wise.H80.QHY550P" that wraps
the ASCOM QHYCCD_GUIDER camera driver and saves images as FITS.

Register:   python qhy550p_com.py --register
Unregister: python qhy550p_com.py --unregister
"""

import time
import traceback
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

    _public_methods_ = ["expose"]
    _label = "QHY550P: "

    def __init__(self):
        self._cam = None
        self.connected = False
        self._wise_util = win32com.client.Dispatch("Wise.Util")

    # ------------------------------------------------------------------
    # Public COM methods
    # ------------------------------------------------------------------

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

    def info(self, msg: str):
        self._wise_util.info(self._label + msg)

    def debug(self, msg: str):
        self._wise_util.debug(self._label + msg)

    def warning(self, msg: str):
        self._wise_util.warning(self._label + msg)

    def error(self, msg: str):
        self._wise_util.error(self._label + msg)

    def expose(self, duration: float, fits_file: str, gain: int | None = None) -> bool:
        """
        Take an exposure and save it as a FITS file.

        Parameters
        ----------
        duration      : float   Exposure duration in seconds
        fits_file     : str     Full path for the output FITS file
        gain          : int     Camera gain (0 = driver default)

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

            self.info(f"setting binning = 1")
            cam.BinX = 1
            cam.BinY = 1

            self.info(f"setting full frame")
            cam.StartX = 0
            cam.StartY = 0
            cam.NumX = cam.CameraXSize
            cam.NumY = cam.CameraYSize

            # Set gain if the driver supports it
            try:
                if gain is not None:
                    self.info(f"setting gain to {gain}")
                    cam.Gain = gain
            except Exception:
                pass  # driver may not support Gain property

            # Start exposure
            self.info(f"starting {duration} seconds exposure")
            cam.StartExposure(float(duration), True)  # True = light frame

            # Wait for image to be ready
            timeout = duration + 30.0  # generous timeout
            start = time.time()
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
                self.info(f"state: {state_str}")

                if time.time() - start > timeout:
                    self.error(f"Timeout waiting for ImageReady after {timeout} seconds")
                    return False
                time.sleep(1.0)
            self.debug("image is ready")

            # Retrieve image array
            img_variant = cam.ImageArrayVariant
            vbarray_data = img_variant  # comes in as a nested tuple via pythoncom

            # Convert to numpy array
            # ASCOM ImageArray is (width, height) i.e. column-major → transpose to (height, width)
            arr = np.array(vbarray_data, dtype=np.float32).T

            # Build FITS header
            hdr = fits.Header()
            hdr["SIMPLE"]   = True
            hdr["INSTRUME"] = "QHY550P"
            hdr["EXPTIME"]  = (float(duration), "Exposure time in seconds")
            hdr["DATE-OBS"] = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())
            hdr["GAIN"]     = (cam.Gain, "Camera gain setting")

            try:
                hdr["CCD-TEMP"] = (cam.CCDTemperature, "CCD temperature deg C")
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

            parts = fits_file.split("-")

            filter = parts[1]
            hdr["FILTER"] = filter

            # Write FITS
            parts[2] = f"{int(duration):03d}s"
            fits_file = '-'.join([parts[0]] + ["polar"] + parts[1:])
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