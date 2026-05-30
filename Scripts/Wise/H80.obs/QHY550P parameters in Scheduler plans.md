# QHY550P parameters in Scheduler plans

The H80 polar camera (QHY550P) is controlled per-target through a short spec
placed in the **Observation Description** field of a Scheduler plan.

## Format

```
[ polar exposure=N.N focus-offset=N number-of-exposures=N gain=N offset=N dark bias ]
```

- The spec is the first `[ ... ]` block found anywhere in the Description, so it
  may be embedded in free text, e.g. `GRAL 1651 [ polar exposure=120 dark ]`.
- The `polar` marker is **mandatory** — without it the spec is ignored and the
  polar camera is skipped.
- Keys and the `polar`/`dark`/`bias` markers are **case-insensitive**.
- Every key is **optional**; any key you omit keeps its default.

## Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `polar` | marker | — | Required. Enables the polar camera for this target. |
| `exposure` | seconds (float) | `300` | Light-frame exposure time. |
| `focus-offset` | steps (int) | `-240` | Focuser offset applied for the polar camera, relative to the current position (alias: `focuser-offset`). |
| `number-of-exposures` | int | `5` | Number of light frames to take. |
| `gain` | int 0–100 | `85` | QHY550P gain. |
| `offset` | int 0–100 | `15` | QHY550P offset. |
| `dark` | marker | off | Also take **one** dark frame, matching the light's `exposure` (the default if not specified). |
| `bias` | marker | off | Also take **one** bias frame (shortest possible exposure). |

`dark` and `bias` are presence flags; `dark=false` / `bias=false` also work.

## Behaviour

- Frames are taken in order: the numbered light frames, then one dark (if
  requested), then one bias (if requested).
- Darks and biases use the flip mirror pointed at the **main** camera as a
  "closed shutter" (the QHY550P has no mechanical shutter). The dark matches the
  light's `exposure`; the bias uses the camera's minimum exposure.
- Output FITS files are tagged with `IMAGETYP` (`Light Frame` / `Dark Frame` /
  `Bias Frame`); light frames are numbered `N_of_M`, dark/bias are suffixed
  `_dark` / `_bias`.

## Examples

| Description spec | Result |
|------------------|--------|
| `[ polar ]` | 5 lights at all defaults (300 s, gain 85, offset 15). |
| `[ polar exposure=120 number-of-exposures=3 ]` | 3 lights of 120 s each. |
| `[ polar exposure=120 dark ]` | 5 lights + 1 matching 120 s dark. |
| `[ polar exposure=60 gain=90 dark bias ]` | 5 lights + 1 dark + 1 bias. |
| `[ polar dark ]` | 5 lights + 1 dark, all at the default exposure (300 s). |
