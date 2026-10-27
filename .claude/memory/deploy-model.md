---
name: deploy-model
description: Goals and decisions for deploying the ACP scripts - dome-pc is the dev machine and pushes to c28-pc and h80-pc over SSH, no git clones on the targets
metadata:
  type: project
---

Arie's goals (2026-10-23):

- **dome-pc is the development machine.** It is also the wise40 observatory (`Wise.Util.wsc` maps hostname `dome-pc` -> `wise40`, `c28-pc` -> `c28`, `h80-pc` -> `h80`, `wo-neo` -> `c18`).
- **One copy of the ACP solution.** Behaviour differs by observatory name, which comes from the hostname, so no per-machine config is needed.
- **Some components belong to one observatory only**: `Scripts\Wise\H80.obs\` and the `UserActions*.wsc` files are h80-pc's; `Wise40 Action Test.vbs` / `Wise40 Calibration Run.vbs` were wise40's (ASCOM.Wise40 `AcpScripts\`) but are **no longer needed (2026-10-27)** and are not deployed. `FS2_Sync.vbs` is a relic of c28-pc and is no longer needed. **Decided 2026-10-23: keep `c28_Sync.vbs`, discard `FS2_Sync.vbs`.** They are byte-identical (both call `Wise.Tele.c28_sync_to_absolute_encoders`, which no-ops off c28); c28-pc already renamed it locally on 2020-12-18 without committing. The repo now has `Scripts/c28_Sync.vbs` (renamed from `FS2_Sync.vbs`); still to do: deploy it to c28 only, and remove the live `FS2_Sync.vbs` copies on all three machines.
- **Develop on dome-pc, push to the live scripts on every machine.**

**Decision: push over SSH from dome-pc; the targets keep no git clones.** The old clones on c28-pc (`C:\Users\mizpe\source\repos\blumzi\ACP`, 41 commits behind, with uncommitted work including an untracked `c28_Sync.vbs`) and h80-pc (`C:\Users\mizpe\source\repos\ACP`, 17 behind) are to be retired once the push works - save c28's local work first.

**Why:** a clone on each target is state to keep in sync and a second source of truth. A push from one place leaves nothing on the targets to drift, and a deployed-commit marker file gives provenance.

**How to apply:** `ssh c28-pc` / `ssh h80-pc` work key-only as admin `mizpe` (see ASCOM.Wise40's `machine-fleet` memory); remote default shell is cmd, so send PowerShell with `-EncodedCommand`. Deploys need a per-observatory manifest, a backup of the existing live folder, `.wsc` re-registration, and a refusal while ACP is running. Dome-pc must stop being a junction to the working tree - see [[acp-scripts-are-the-live-tree]].
