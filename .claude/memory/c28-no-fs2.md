---
name: c28-no-fs2
description: c28 no longer has the FS2 controller (anything about FS2 is obsolete); the absolute-encoder sync is fully operational; c28's live Wise.Tele.wsc is the reference for c28 behaviour
metadata:
  type: project
---

Arie said on 2026-10-27: **FS2 is ancient history.** c28 had an FS2 controller and no longer does, so FS2-era workarounds in the scripts are obsolete. **Reading the absolute encoders and syncing (`c28_sync_to_absolute_encoders`, `A2Read.exe`) is fully operational now** and is not an FS2 leftover.

**Why:** c28's live `Wise.Tele.wsc` (edited 2026-10-03) carries c28 logic the repo never had: the pointing corrections recalibrated on 2025-11-23 (RA `01:32:51`, DEC `-09:18:43`) and the `dec > -41` sync guard. The repo's July 2021 choices (`c28_startup` waits 3 s, `c28_shutdown` slews to coordinates because "the FS2 cannot Park") were FS2-era, so live won: 10 s, and `acp_tele.park`.

**How to apply:** when a c28 file differs from the repo, treat the live c28 file as the reference for c28-only code and port it to the repo before any deploy; never apply a repo file over c28's live one unreviewed. Don't write new FS2 comments or workarounds. c28's camera setpoint is -25 C at startup (`Wise.Camera.wsc` `startup`); repo commit `27926e6` (message "added") had actually deleted it, and Arie had it restored on 2026-10-27. `ACP-Weather.vbs` is not integrated into ACP on any observatory (Arie, 2026-10-27), so c28's differing copy (powers the telescope, shuts the dome, slews to park) is not a regression to chase; to be handled some other time. Note `manifest-common.txt` still deploys it everywhere. `c28_Sync.vbs` calls `c28_sync_to_absolute_encoders`, so it is not an FS2 relic either; see [[deploy-model]].
