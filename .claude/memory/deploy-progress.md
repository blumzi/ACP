---
name: deploy-progress
description: Where the fleet deploy stands as of 2026-10-27 - dome-pc deployed (marker stale), c28 reviewed and ported, h80-pc not yet reviewed, what deploy.ps1 has and has not been tested on
metadata:
  type: project
---

**State on 2026-10-27** (PRs #15 #16 #17 #18 merged; `deploy/deploy.ps1` and the manifests are on `master`):

- **dome-pc (wise40): deployed twice today.** First `Scheduler\StartupObs.vbs` (per-observatory FocusMax); then `Wise.Camera/Dome/Tele.wsc` from `master` @ `551c151` (the `fatal` fix and the c28 ports; the c28 code does not run on wise40). Backups in `C:\ProgramData\AcpDeploy\backups\20261027-112411\` and `...-172506\`. Files match the repo, all 9 registrations point at the right files, and every Wise component creates from 32-bit `cscript`. **`WiseDeployed.txt` there is stale** (still describes the 11:24 deploy): the second run aborted in registration because of a `deploy.ps1` bug (below) after copying. The new `StartupObs.vbs` and the new `.wsc` files have not been seen running yet; check the next startup log ("loading FocusMax ...").
- **c28-pc: reviewed, NOT deployed.** The c28-only logic in its live files was ported to the repo (PR #18): see [[c28-no-fs2]]. Still to do before an apply: `Wise.Power.wsc` is missing there and must go in first; `Wise.Dome/Util/Camera` and the scheduler scripts differ but were reviewed as older versions; remove the live `FS2_Sync.vbs`. Fetched copy of its files: `C:\Users\mizpe\c28mirror` (outside the repo, delete when done).
- **h80-pc: dry run only, NOT reviewed.** 10 missing (`WiseTrainCorrector.vbs`, all of `H80.obs\`, `UserActions-Wise.wsc`) and 6 differ in content in both directions (`Wise.Util/Power/Camera/Dome.wsc`, `StartupObs.vbs`, `ShutdownObs.vbs`). **Next: diff those six for hand edits worth keeping** (same method as c28: read the diff, check which side is newer in git history, port what only h80 has). Fetched copy: `C:\Users\mizpe\h80mirror`.
- **wo-neo: out of scope**, see [[wo-neo-unmanaged]].

**How to dry-run a remote machine:** no SMB, so `scp` each destination from the manifest plan into a short local mirror, then run `deploy.ps1 -Observatory <obs> -AcpRoot <mirror>\acp -SchedulerRoot <mirror>\sc`. The script itself only reads local paths; to apply on a target it has to run there.

**How `deploy.ps1` behaves:** dry run unless `-Apply`; acts only on missing/differing files (SHA256); refuses to apply if not elevated, if `acp`/`wscript`/`cscript` is running (`-ForceRunning` overrides), or if a file to deploy is dirty in git; backs up what it replaces; writes the marker right after copying; re-registers only the `.wsc` it copied and reads the registry back; never deletes. It does not repair a lost registration when the file is unchanged.

**Bug found 2026-10-27 and fixed on branch `fix-deploy-registration-check`:** the registry read-back treated `ScriptletURL` as a property of the CLSID key; it is a subkey whose `(Default)` is the file URL, URL-encoded (`%20`), under `HKLM\SOFTWARE\WOW6432Node\Classes\CLSID\{clsid}\ScriptletURL`. Under `Set-StrictMode` that read threw, killed the run after the first `regsvr32` and still exited 0, so Camera was re-registered but Dome/Tele were not (their registrations were already correct) and the marker was never written. Check whether that branch is merged before the next live apply.

**Still untested:** a live apply that re-registers end to end with the fixed script; any apply on a target machine (c28-pc, h80-pc).

**Why:** deploys go out from dome-pc without git clones on the targets, per [[deploy-model]].

**How to apply:** on dome-pc a live `-Apply` needs an elevated shell, launched with `Start-Process powershell -Verb RunAs -Wait` writing its output to a log file (the user accepts the UAC prompt; ACP's idle state must be confirmed by the user before `-ForceRunning`). Never trust the exit code or the log alone: verify the files, the registrations and the marker afterwards. Remaining after the baselines: cut over h80-pc, then c28-pc; remove the live `FS2_Sync.vbs` on all three by hand; decide whether `Wise.Dli.wsc` is still needed; retire the old clones on c28-pc and h80-pc; delete branch `plan-deploy-to-fleet` or refresh its plan.
