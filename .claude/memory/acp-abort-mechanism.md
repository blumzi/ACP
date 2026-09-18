---
name: acp-abort-mechanism
description: How ACP delivers Abort (user button / Scheduler dawn-stop) to a running script
metadata:
  type: reference
---

ACP has **no pollable "abort pending" flag**. A script becomes interruptible only by:
1. Setting `Util.Abortable = True` on an ACP.Util instance (AcquireSupport does this once at init; all ACP.Util instances share the app-global console/abort state).
2. Periodically calling `Util.WaitForMilliseconds(ms)` — this is the **only** abort-delivery point. ACP stops the script at that call when an abort is pending.

Consequence: any long **blocking** operation (especially an out-of-process COM call, e.g. the Python `Wise.H80.QHY550P` server) makes the script uninterruptible for its whole duration, because no `WaitForMilliseconds` runs. Fix = drive the work in small non-blocking steps on the ACP/JScript side and call `WaitForMilliseconds` (~1s) between polls. See the H80 polar `TargetEnd` rewrite (Wise.H80.wsc `run_polar_sequence` + qhy550p `begin_exposures`/`start_next_frame`/`image_ready`/`read_current_frame`/`abort_exposures`).

**Ending a run cleanly from a user action:** `AcquireImages.js` calls `if (!SUP.UserActions.TargetEnd(...)) break Sets;` — so returning **false** from `TargetEnd` (via UserActions) terminates the run gracefully. TargetStart returns false to terminate, 2 to skip a target. This is the reliable lever for a user-action abort handler: restore hardware, then return false. (ACP also wraps the TargetEnd call in try/catch, so a thrown error is swallowed — don't rely on throwing to stop the run.)

Verified by inspecting the installed `AcquireSupport.wsc` (only `Util.Abortable = True` at line ~1691; `WaitForMilliseconds` peppered everywhere; no readable abort property anywhere in the ACP install).
