# Replace the junctions on dome-pc with a real Scripts\Wise folder

Status: DONE 2026-10-27 10:06 (steps 1-5; ACP was not running).  Remaining: step 6 (start ACP, run a harmless
script) and step 7 (deploy script).  Log: C:\Users\mizpe\acp-backup-2026-10-27\swap.log
Decided 2026-10-27: nothing else uses `C:\Deploy\ACP`.

## Why

ACP's `Scripts\Wise` is a junction to `C:\Deploy\ACP\Scripts\Wise`, and `C:\Deploy\ACP` is a symbolic link
to this working tree.  Every branch switch, stash, clean or hard reset changes what ACP runs, live.
dome-pc is also the wise40 observatory, so it must become a deploy target like c28-pc and h80-pc
(see deploy-model memory).

## Steps

1. Stop ACP (and make sure the dome and telescope are idle).
2. DONE - back up: links, registrations, a copy of the live Scripts\Wise, scheduler scripts, weather files.
3. Remove the two links with `rmdir` (never `del` or `rd /s` on a link):
   - `C:\Program Files (x86)\ACP Obs Control\Scripts\Wise`  (junction)
   - `C:\Deploy\ACP`  (symbolic link, not a junction).  Remove only this link.  Leave the rest of
     `C:\Deploy` alone: ACP.c28, ACP.sav, il0002, Wise4ACP.exe, RemoteSafetyDashboard*.exe, loose .wsc files.
4. Create a real `Scripts\Wise` and fill it from manifest-common + manifest-wise40 (by hand, once).
   Do not copy `.vs\`, `register.bat`, or anything not named in a manifest.
5. Re-register every .wsc from the new path, in manifest order (Util, Power first).  Verify the CLSIDs
   resolve to the new files.  ACP.UserActions stays unregistered on purpose.
6. Start ACP, run a harmless script, check the log.
7. Only then write the deploy script, and try it on dome-pc first.

## Findings from the backup

- Registrations (HKCR, 32-bit view) for all 8 Wise.* components and ACP.WiseWeather point at
  `C:\Program Files (x86)\ACP Obs Control\Scripts\Wise\*.wsc` (WiseWeather: `...\WeatherComponents\`), the
  same paths a real folder will have.  ACP.UserActions and the H80 components are not registered (expected).
- Live WiseWeather.wsc differs from the repo by one commented-out `wise_util.trace` line.  Decide: commit
  it or let the deploy overwrite it.
- Everything else live matches the repo.  ACP-Weather.vbs and the scheduler scripts are real files, not links.
- Untracked/ignored in the tree (not in any manifest, so never deployed): .vs/, obj/, ACP.vbproj.user,
  three `~RF*.TMP` files in Scripts\.

## Open

- Rollback if step 5 fails: re-create the two links (targets are in the backup's links.txt) and
  re-register from the old paths.
