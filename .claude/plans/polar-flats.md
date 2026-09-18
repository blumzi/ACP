# Polar-camera flats — implementation plan

Date: 2026-09-18

## Design in one paragraph

ACP Scheduler takes flats by running ACP's `AutoFlat.vbs` against a fixed plan file
(`...\ACP Astronomy\Plans\SchedulerDuskFlats.txt` / `SchedulerDawnFlats.txt`). Flats have no
Description field, so the polar request rides as a `;` comment line in that same plan file:

```
; [ polar flat number_of_exposures=3 ]
5,gpr,4
```

AutoFlat never sees the comment (`GetNextLiveLine` strips `;`, AcquireSupport.wsc:7409), so the main
flat line is untouched. Our code reads the file itself from a UserActions hook.

Placement, from the 16-Sep logs: at dusk AutoFlat spends ~27 of its 30 minutes waiting, because 3 s at
bin 4 in gpr saturates until the Sun reaches about -6.5 deg. That bright stretch is unusable for the
main camera and is exactly what a micro-polarizer camera wants. So:

- **dusk** — polar frames run *before* the main sets, from the first `SlewEnd` (fires after arrival at
  the flat spot, AcquireSupport.wsc:5177-5185), so pointing is already done.
- **dawn** — polar frames run *after* the main sets, from `ScriptEnd` (SUP.Terminate, AutoFlat.vbs:1178),
  because the sky is brightening.

Note AutoFlat drives MaxIm directly (AutoFlat.vbs:1471, `Camera.Expose` at :1585), so `ImageStart` /
`ImageEnd` never fire during a flat run — `ScriptStart`, `SlewStart` / `SlewEnd` and `ScriptEnd` are the
only hooks available.

## Phase 0 — Spike first (before writing any loop)

Temporary logging only, no behavior change. One dusk + one dawn.

- [ ] In `UserActions.wsc`, log from `ScriptStart` / `SlewEnd` / `ScriptEnd`: `ACPApp.Script`, and in
      try/catch `Util.Script.Dawn`, `Util.Script.plnFile`, `Util.Script.FlatMode`.
- [ ] Count how many times `SlewEnd` fires in one AutoFlat run.
- [ ] Log the polar camera's `MaxADU`, `ExposureMin`, `ExposureMax`.

**Exit criteria:** we know whether `Util.Script` exposes AutoFlat's VBScript globals (fallback: fixed
plan-file names + sun altitude for dusk/dawn), how many `SlewEnd`s to latch against, and the ADU
ceiling the target must be expressed in.

## Phase 1 — Parser (Wise.H80.wsc)

In `parse_polar_parameters` (Wise.H80.wsc:335):

- [ ] Normalize keys: `key = str_trim(key).toLowerCase().replace(/_/g, "-")` before matching, so
      `number_of_exposures` and `number-of-exposures` both work, in both spec sites.
- [ ] `polar` accepts a value: `found_polar = (val == null) ? true : parseBool(val)` — gives `polar=false`
      as the per-night off switch, matching how `dark` / `bias` already behave.
- [ ] New `flat` marker sets `params.flat = true`. Guard both ways: the flat path ignores a spec without
      `flat`, `TargetEnd` ignores a spec with it.
- [ ] New keys: `number-of-exposures` (default **1** on the flat path), `target-adu`, `adu-tolerance`,
      `min-exposure`, `max-exposure`, `max-minutes`. `focus-offset`, `gain`, `offset` carry over.
- [ ] `dark` / `bias` in a flat spec: warn and ignore.
- [ ] New `read_flat_spec(planPath)`: open the plan, try the parser **line by line** — whole-file parsing
      would span two bracket blocks (`indexOf("[")` / `lastIndexOf("]")` at :340).
- [ ] Separate `default_polar_flat_parameters()` so flat defaults never drift into light-frame defaults.

## Phase 2 — Python (qhy550p_com.py)

- [ ] `_readout`: `mean = float(arr.mean())` -> `self._last_mean_adu`, exposed as a property. Exact
      analogue of AutoFlat's PinPoint `SimpleBackgroundMean` (AutoFlat.vbs:1671).
- [ ] `"flat"` frame type in `_start_frame` (mirror -> polar, `Light=True`); `IMAGETYP = "Flat Field"`
      in the map at :625.
- [ ] Explicit output naming. The `parts[2]` split at :671 derives everything from a main-camera path
      that does not exist during a flat run. Add a `base_path` for flats:
      `<night folder>\PolarFlat-<YYYYMMDD>-<dusk|dawn>-NNN.fts`, folder following AutoFlatConfig's
      `$DATENITE` convention so frames land with the night's data.
- [ ] Expose `max_adu`, `exposure_min`, `exposure_max` for the JScript clamps.
- [ ] Optional `test_size` subframe for convergence frames (even-aligned origin, whole 2x2 polarizer
      superpixels) with a discard path that skips the FITS write. Skip this if full-frame readout is
      fast enough and just iterate on real frames.

## Phase 3 — Control loop (Wise.H80.wsc)

Public `FlatsBegin()` (dusk) and `FlatsEnd()` (dawn), both delegating to `run_polar_flats(dawn)`:

1. [ ] Read the spec; absent or `polar=false` -> one log line, return.
2. [ ] Save focuser position, `move_focuser(saved + focus-offset)`, `move_flipmirror("polar")`,
   `acp_util.Abortable = true`.
3. [ ] Seed `intv` = min-exposure at dusk / max-exposure at dawn; `accel` = 1.05 PM / 0.95 AM
   (AutoFlat.vbs:803-815), with **our** bounds, not AutoFlatConfig's 3/90 s.
4. [ ] Converge: expose -> mean -> in band (`target +/- tolerance`) accept; else
   `intv = intv * target/mean * accel`, clamp to [min,max]; if clamped and still wrong,
   `WaitForMilliseconds(15000)` and retry (dusk-too-light / dawn-too-dark) or abandon
   (dusk-too-dark / dawn-too-bright). Same structure as AutoFlat.vbs:1728-1800. Enforce `max-minutes`.
5. [ ] Take the N keepers, re-applying the correction after each so `intv` carries forward —
   AutoFlat's ByRef behavior.
6. [ ] Restore: mirror -> main, focuser -> saved.

**Abort decision:** at dusk we are inside `SlewEnd`, where returning false raises an error
(AcquireSupport.wsc:5142). So restore optics and return **true**; ACP re-delivers the abort at its own
next wait. Only the dawn path (`ScriptEnd`) can end quietly. Abort is only delivered at
`Util.WaitForMilliseconds` while `Util.Abortable = True`.

## Phase 4 — Wiring (UserActions.wsc)

- [ ] `ScriptStart`: keep the cooldown, add `wise_h80.FlatsReset()` to clear the once-per-run latch.
- [ ] `SlewEnd`: if `ACPApp.Script` contains "autoflat", not dawn, latch unset -> `FlatsBegin()`.
      Always return true. Heed AcquireSupport's warning above `WaitForSlew`: no slews, no tracking changes.
- [ ] `ScriptEnd`: if "autoflat" and dawn -> `FlatsEnd()`.
- [ ] Add both methods to `<public>`; `ACPApp` is already declared at UserActions.wsc:119.
- [ ] Re-register with `register-wsc-components.ps1`.

## Phase 5 — Logging

`wise_util.info` -> `acp_util.Console.PrintLine` (Wise.Util.wsc:134), and during an AutoFlat run the ACP
console *is* `Logs\AutoFlat\AutoFlat-YYYYMMDD-Dusk.log` — so our lines interleave with AutoFlat's own ADU
trail in one file, plus the trace file. No new logging machinery, but make it deliberate:

- [ ] Fixed prefix `polar-flat:` on every line, so one grep pulls the whole story out of a mixed log.
- [ ] Mirror AutoFlat's phrasing (`TEST`, `FLAT n of m`, `Background mean = N (ADU)`) so the two
      cameras' numbers read side by side.
- [ ] Log at every decision point: hook entry (script name, dawn flag, plan path); spec found (echo the
      raw line) or "no polar flat spec"; parsed parameters; ADU ceiling and clamps in use; each
      iteration's exposure / mean / decision; each 15 s wait with elapsed total; optics moves; each file
      written; completion with elapsed time and final exposure; every abandon reason; both restore paths
      (normal and abort).

A good dusk run should read roughly:

```
polar-flat: AutoFlat dusk run, plan SchedulerDuskFlats.txt
polar-flat: spec "[ polar flat number-of-exposures=3 ]"
polar-flat: target 1600 ADU +/- 600 (MaxADU 4095), exposure 0.05-30 s, seed 0.05 s
polar-flat: TEST 0.05 s -> mean 3980 (too light), scaling to 0.02 s
polar-flat: FLAT 1 of 3: 0.02 s -> mean 1712, wrote PolarFlat-20260920-dusk-001.fts
...
polar-flat: done, 3 frames in 1.4 min, final exposure 0.03 s; optics restored
```

## Phase 6 — Verification

- [ ] Parser checked offline against sample lines (hyphen/underscore, `polar=false`, missing `flat`,
      junk tokens). No telescope needed.
- [ ] Daytime plumbing run: mirror + focuser moves and one short frame with the dome shut. Checks
      naming, logging, restore — not photometry.
- [ ] First dusk with `number_of_exposures=1` and a conservative `max-minutes`; compare the AutoFlat log
      against the previous night — main flats' start time and frame count must be unchanged.
- [ ] First dawn likewise.
- [ ] Abort mid-sequence: optics restored, run ends cleanly, no stuck mirror.
- [ ] Regression: spec removed -> exactly one "no polar flat spec" line, nothing else.

## Phase 7 — Docs

- [ ] Add a Flats section to `QHY550P parameters in Scheduler plans.md`: the two plan-file paths, the
      grammar, defaults, dusk-before / dawn-after placement and why, how to turn it off for a night, and
      where to read the log.

## Risks

| Risk | Mitigation |
|---|---|
| `Util.Script` may not expose VBScript globals | Phase 0 settles it; fallback is fixed plan names + sun altitude |
| Long work inside `SlewEnd` is unconventional | No slews, no tracking changes, `max-minutes` cap, always return true |
| Polar ADU scale unknown (12-bit sensor) | Target defaults to a fraction of `MaxADU`, never a copied 20000 |
| `ScriptEnd` is not called on a script error | Dawn flats simply skipped that night — logged by absence; acceptable |
| A `number-of-exposures` typo silently ignored | Hyphen normalization plus the existing unknown-token warning |
