---
name: wise40-power-ip9258
description: "Since 2026-10-22 Wise.Power drives the IP9258 on wise40 and the camera is powered off at every Scheduler shutdown; unknown outlet names are fatal; check_limits still never runs on wise40"
metadata:
  type: project
---

**Until 2026-10-22, `Wise.Power` did nothing on wise40.** It only knew c18/c28 (DigitalLoggers) and
h80 (Gude8211), and `Wise.Camera` skipped power on wise40 explicitly. PR #6 changed that:

- On wise40 `Wise.Power` drives `ASCOM.IPPower9258.Switch`. The only named outlet is **`Camera`** (box 0,
  outlet 0). For the switch and its traps, see ASCOM.Wise40's `ip9258-power-switch` memory.
- **wise40 now powers the camera off at every Scheduler shutdown**, after `warm_up` and the MaxIm
  disconnect, and on at startup. Arie chose this. Before, it stayed powered across nights.
- **`power_on`/`power_off`/`power_cycle` of a name the switch doesn't have are fatal.** `port_id()` returns
  Empty for an unknown name, and Empty as a switch id is 0, so they used to switch **outlet 0**, which on
  wise40 is the camera. `has_power` of an unknown name still returns `False`.

**Open, and deliberately unchanged:** `Wise.Tele.check_limits` (called by `WiseWeather` once a minute)
starts with `has_power("Telescope")`. wise40 has no such outlet, so it always logs "The telescope is
powered OFF" and returns. **The altitude-limit check never runs on wise40.** Fixing that needs a decision
about what "telescope powered" means without an outlet.

**Not yet seen end to end:** a real Scheduler startup/shutdown with this code. The first shutdown should log
"powered 'Camera' OFF".

**Scheduler scripts aren't the live tree:** the Scheduler runs
`C:\Users\Public\Documents\ACP Config\Scheduler\StartupObs.vbs`/`ShutdownObs.vbs`, which are copies.
On 2026-10-22 (PRs #9, #10) the repo's `Scheduler/StartupObs-Wise.vbs` and `ShutdownObs-Wise.vbs` were
made byte-identical to those live copies. The repo ones had drifted: the startup one launched **FocusMax
V4** on wise40, which can't run here (ASCOM.Wise40's `focuser-com-interfaces` memory). Copy any later edit
in both directions, and `cmp` the pairs before assuming either describes what runs. See
[[acp-scripts-are-the-live-tree]] for the half that *is* live.

**`Wise4ACP.iss` can't package them:** it still sources `Scripts\StartupObs-Wise.vbs`/`ShutdownObs-Wise.vbs`,
which moved to `Scheduler\` in `e6eca32`.

Related: [[wsc-registrations-lost]] (`Wise.Power` had never been registered), [[wsc-bare-property-name-is-empty]].
