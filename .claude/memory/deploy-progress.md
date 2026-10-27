---
name: deploy-progress
description: Where the fleet deploy stands as of 2026-10-27 - dome-pc deployed, h80-pc and c28-pc baselined/not yet, what deploy.ps1 does and has not been tested on
metadata:
  type: project
---

**State on 2026-10-27** (PR #15 merged; `deploy/deploy.ps1` and the manifests are on `master`):

- **dome-pc (wise40): deployed.** One file was replaced, `Scheduler\StartupObs.vbs` (per-observatory FocusMax). Backup in `C:\ProgramData\AcpDeploy\backups\20261027-112411\`. A dry run now shows 13 of 13 identical. The new script has not run yet; check for the "loading FocusMax ..." line in the next startup log.
- **h80-pc: dry run only, NOT applied.** 16 to copy: 10 missing (`WiseTrainCorrector.vbs`, all of `H80.obs\`, `UserActions-Wise.wsc`) and 6 differ in content (`Wise.Util/Power/Camera/Dome.wsc`, `StartupObs.vbs`, `ShutdownObs.vbs`; real changes, not line endings, in both directions). **Next: diff those six for hand edits worth keeping before any apply.** The fetched copy is at `C:\Users\mizpe\h80mirror` (outside the repo, delete when done).
- **c28-pc: not looked at yet.** Last known: no `Wise.Power.wsc`, Scheduler scripts and several `.wsc` differ, still has `FS2_Sync.vbs`.
- **wo-neo: out of scope**, see [[wo-neo-unmanaged]].

**How to dry-run a remote machine:** no SMB, so `scp` each destination from the manifest plan into a short local mirror, then run `deploy.ps1 -Observatory <obs> -AcpRoot <mirror>\acp -SchedulerRoot <mirror>\sc`. The script itself only reads local paths; to apply on a target it has to run there.

**How `deploy.ps1` behaves:** dry run unless `-Apply`; acts only on missing/differing files (SHA256); refuses to apply if not elevated, if `acp`/`wscript`/`cscript` is running (`-ForceRunning` overrides), or if a file to deploy is dirty in git; backs up what it replaces; re-registers only the `.wsc` it copied; never deletes. **Untested: registration, and any apply on a target machine.** It does not repair a lost registration when the file is unchanged.

**Why:** deploys go out from dome-pc without git clones on the targets, per [[deploy-model]].

**How to apply:** on dome-pc a live `-Apply` needs an elevated shell, which can be launched with `Start-Process powershell -Verb RunAs` (the user accepts the UAC prompt); ask the user whether ACP is idle before using `-ForceRunning`. Still to do after the baselines: cut over h80-pc, then c28-pc; remove the live `FS2_Sync.vbs` on all three by hand; decide whether `Wise.Dli.wsc` is still needed; retire the old clones on c28-pc and h80-pc; delete branch `plan-deploy-to-fleet` or refresh its plan.
