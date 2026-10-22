---
name: wsc-registrations-lost
description: "On 2026-10-22 every Wise script component had lost its COM class registration (ProgID stub, no CLSID) and Wise.Power had never been registered; ACP.UserActions is now deliberately unregistered"
metadata:
  type: project
---

**Symptom (2026-10-22):** the Scheduler's `StartupObs.vbs` failed at line 11 with
`ActiveX component can't create object: 'Wise.Util'`.

**State found:** every Wise component (`Wise.Util/Ascom/Camera/Dli/Dome/Http/Tele`, `ACP.UserActions`,
`ACP.WiseWeather`) still had `HKLM\SOFTWARE\Classes\<ProgID>\CLSID` but **no `CLSID\{...}` key in either
registry view**. A half-removed registration, cause unknown. Most `.wsc` files had been rewritten on
2026-09-24 11:43, so that may be when it happened. Not confirmed.

**`Wise.Power` had never been registered at all**, although `Wise.Camera`, `Wise.Dome` and `Wise.Tele`
each create it at load time. `Wise4ACP.iss` still doesn't register it; the `Scripts/Wise/register`
helper does. **Open:** add it to the installer.

**Fix:** `C:\Windows\SysWOW64\regsvr32.exe /s "<file>.wsc"` for each. ACP is 32-bit, so it must be the
SysWOW64 one, run elevated. Verify by checking
`HKLM\SOFTWARE\WOW6432Node\Classes\CLSID\{clsid}\ScriptletURL`, not by regsvr32's silence. Backups of the
broken keys are in `C:\Wise40\wsc-registration-backup-20261022-*`.

**Don't register the `Scripts\Wise\H80.obs\` components on wise40.** Their `UserActions.wsc` uses the same
CLSID as Wise40's `ACP.UserActions`, and registering it would replace Wise40's hooks with H80's.

## `ACP.UserActions` is unregistered on purpose

Arie had it unregistered on 2026-10-22, so **ACP now runs with no Wise UserActions hooks** (including
`TargetStart`). If hook behaviour is missing, this is why, not a fault. To restore:
`SysWOW64\regsvr32 /s "C:\Program Files (x86)\ACP Obs Control\UserActions.wsc"`, or import the `.reg`
files in `C:\Wise40\wsc-registration-backup-20261022-100303-useractions\`.

**`regsvr32 /u` didn't remove it.** It ran twice, elevated, returned silently, and left everything in place.
The keys had to be deleted by hand (`ACP.UserActions`, `ACP.UserActions.1.0`, and the
`WOW6432Node\Classes\CLSID\{33F9198D-...}` key).

Related: [[wise40-power-ip9258]], and ASCOM.Wise40's `elevated-steps-from-a-tool-call` for running these steps.
