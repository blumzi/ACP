# Memory index

- [ACP abort mechanism](acp-abort-mechanism.md) — Abort is only delivered at `Util.WaitForMilliseconds` when `Util.Abortable=True`; no pollable flag.
- [Deploy model](deploy-model.md) — dome-pc is the dev machine and pushes to c28-pc/h80-pc over SSH; no git clones on targets; per-observatory components; FS2_Sync was renamed c28_Sync (c28 only).
- [ACP scripts are the live tree](acp-scripts-are-the-live-tree.md) — this repo IS ACP's `Scripts\Wise` folder, via two junctions; a branch switch changes what ACP runs.
- [WSC bare property name is Empty](wsc-bare-property-name-is-empty.md) — inside a `.wsc` its own property name is Empty (= 0); it made wise40/c28 shutdowns **open** the shutter. Fixed in PR #7.
- [wise40 power via the IP9258](wise40-power-ip9258.md) — `Wise.Power` drives the IP9258 on wise40; the camera is powered **off at every shutdown**; unknown outlets are fatal; `check_limits` still never runs on wise40.
- [WSC registrations lost](wsc-registrations-lost.md) — 2026-10-22: every component had lost its CLSID, `Wise.Power` was never registered, and **`ACP.UserActions` is now unregistered on purpose**.
- [wise-train-corrector branch (deleted)](wise-train-corrector-branch-unmerged.md) — compared and deleted 2026-10-27; its README paragraph moved to `Scripts/README.txt`.
- [wo-neo is unmanaged](wo-neo-unmanaged.md) — c18 runs plain ACP, no Wise scripts, left out of the deploy; ssh is key-only as admin `mizpe`.
