---
name: wo-neo-unmanaged
description: wo-neo (c18) runs plain ACP with no Wise scripts and is deliberately left out of the deploy; ssh to it works key-only as admin mizpe
metadata:
  type: project
---

Arie decided on 2026-10-27 that **wo-neo (observatory c18) stays as it is**: no manifest, not a deploy target.

Found on 2026-10-27 (read-only look): no `Scripts\Wise`, no `C:\Deploy`, no junctions, no `Wise.*` component registered, ACP's own `StartupObs.js` / `ShutdownObs.js` in the Scheduler folder, an old `WiseWeather.wsc` (2020-04-12). `C:\Wise` and `C:\Wise40` exist at the drive root and were not opened.

**Why:** c18 is a legacy ACP install; `Wise.Util.wsc` maps `wo-neo` -> c18 but nothing Wise was ever deployed there.

**How to apply:** leave wo-neo out of the cutover order in [[deploy-model]]. `ssh wo-neo` works key-only from dome-pc as `mizpe`, who IS an administrator there, so the key lives in `C:\ProgramData\ssh\administrators_authorized_keys` (the per-user `authorized_keys` is ignored). Stale leftovers there: `C:\Users\mizpe\.ssh\authorized_keys`, `C:\ProgramData\ssh\mizpe.pub`. An old sshd process had held port 22 and stopped the service restarting (cleared by 2026-10-27).
