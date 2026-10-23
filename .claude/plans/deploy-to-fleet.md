# Deploy the ACP scripts to the fleet from dome-pc

Date: 2026-10-23 (status as of the end of that session)

Goals and the push-over-SSH decision are in `.claude/memory/deploy-model.md`. This file is the
status and the plan.

## Done

- SSH from dome-pc to c28-pc and h80-pc works key-only (`ssh c28-pc`, `ssh h80-pc`; key
  `~/.ssh/mizpe`, aliases in `~/.ssh/config`). `sshd` is set to Automatic on both.
- `FS2_Sync.vbs` renamed `c28_Sync.vbs` (PR #12); `Wise.Power.wsc` added to `ACP.vbproj` (PR #13).
  dome-pc `master` is clean and level with `origin/master`.
- Read-only comparison of the live folders against dome-pc `master` (see Findings).

## Findings (2026-10-23)

- **Only dome-pc has the junction chain.** On c28-pc and h80-pc, `Scripts\Wise` under ACP is a plain
  directory and `C:\Deploy\ACP` does not exist.
- **c28-pc live has no `Wise.Power.wsc`**, though the repo's version targets c28 (Dli). It still has
  `Wise.Dli.wsc`; it probably runs the pre-Power scripts (inference, unverified).
- **Scheduler `StartupObs.vbs` / `ShutdownObs.vbs` differ** from the repo on both c28-pc and h80-pc.
- **`Wise.Camera/Dome/Util.wsc` differ** on both; `Wise.Tele.wsc` differs on c28-pc only; `register`
  and `Wise.Power.wsc` differ on h80-pc. Not yet diffed - could be old versions or line endings.
- **h80-pc has none of `H80.obs\`** and its `UserActions.wsc` differs; it has no `UserActions-Wise.wsc`.
- **dome-pc live `WeatherComponents\WiseWeather.wsc` is stale** (2021-07-26; repo is 2021-07-27, one
  trace line commented out). c28-pc and h80-pc have the current one.
- Old clones: c28-pc `C:\Users\mizpe\source\repos\blumzi\ACP` (41 commits behind), h80-pc
  `C:\Users\mizpe\source\repos\ACP` (17 behind). The targets' live folders are not linked to them.
- Live `FS2_Sync.vbs` still exists in ACP's `Scripts` folder on all three machines.
- `Wise.Util.wsc` maps hostnames to observatories: `wo-neo` c18, `c28-pc` c28, `dome-pc` wise40,
  `h80-pc` h80.

## Next steps, in order

1. **Manifest + dry-run deploy script** (a PR). A per-observatory manifest (common files;
   h80: `H80.obs\` and the UserActions files; wise40: the two `Wise40 *.vbs` from ASCOM.Wise40's
   `AcpScripts\`; c28: `c28_Sync.vbs`; Scheduler scripts renamed on copy). The script only reports
   what it would change until told otherwise. It must back up the live folder first (dated copy),
   re-register the `.wsc` components (needs elevation), write the deployed commit to a marker file,
   and refuse to run while ACP is executing something.
2. **Baseline each machine:** diff its live folder against the repo, and against its own old clone,
   to find hand edits worth keeping. Save c28-pc's clone first (its only unique change was the
   `c28_Sync.vbs` rename, now in the repo; `ACP.vbproj` there is also modified - not yet looked at).
3. **Cut over h80-pc, then c28-pc, then dome-pc** (dome-pc last: remove the two junctions and make
   its live folder a deployed copy like the others).
4. Remove the live `FS2_Sync.vbs` everywhere (replace with `c28_Sync.vbs` on c28-pc only).
5. Decide whether `Wise.Dli.wsc` is still needed (`Wise.Power` now chooses the driver itself; it is
   still referenced from `ACP.vbproj`, `Wise4ACP.iss` and `Scripts/README.txt`).
6. Retire the old clones on c28-pc and h80-pc.

## Working notes

- Remote default shell is **cmd**. Send PowerShell as `-EncodedCommand <base64 of UTF-16LE>`; piping a
  script on stdin fails (BOM, line-by-line execution). Use `-o BatchMode=yes`.
- Do not name a PowerShell function `H` - `h` is an alias for `Get-History` and wins over functions.
- dome-pc has git 2.15: there is no `git worktree remove` (delete the folder, then `git worktree
  prune`). The Bash tool's working directory persists; leave a worktree before deleting it.
- Avoid nested heredocs inside `$(...)` in one Bash call; put commit and PR text in files and use
  `git commit -F` / `gh pr create --body-file`.
- `gh` is at `C:\Users\mizpe\bin\gh\bin`. A `Bash(gh pr:*)` permission rule is set; auto mode still
  asks for a merge unless the user has just said to merge.
- Work goes through PRs; the dome-pc tree on `master` is ACP's live tree, so branch switches and pulls
  are deployments (a pull that touches only files outside `Scripts\Wise\` is safe).
- Loose end: an unused TextMate extension at `C:\Users\mizpe\.vs\Extensions\wsc-textmate\` (the
  `.wsc` colouring experiment was dropped). Delete it if it is not wanted.
