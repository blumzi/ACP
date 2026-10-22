---
name: wsc-bare-property-name-is-empty
description: "Inside a .wsc, a public property's own name is undefined (Empty), and Empty equals 0 - this made the wise40 and c28 shutdowns open the shutter instead of closing it"
metadata:
  type: feedback
---

**Inside a Windows Script Component, never refer to one of its own public properties by name.** A
property declared as

```xml
<property name="shutterClosed"><get /></property>
```

is served by `function get_shutterClosed`. Callers see `o.shutterClosed = 1`, but **inside the component
the bare name `shutterClosed` is an undefined variable, so it's Empty**. With no `option explicit`
nothing complains. Use the underlying constant (`const_shutterClosed`) or call `get_shutterClosed`.

**Why it matters: Empty compares equal to 0.** In `Wise.Dome` that 0 is the ASCOM shutter status
**Open**. Until 2026-10-22 (PR #7), `wise40_shutdown` and `c28_shutdown` did this:

- shutter open: `0 = Empty` is True, so they logged "shutter already closed" and **left it open**;
- shutter closed: `get_shutter_to(Empty)` matched `const_shutterOpen` and **opened it**.

**How it was proved:** a minimal component loaded with `GetObject("script:C:\path\x.wsc")`, which needs
no registration and touches nothing, gave `typename(shutterClosed)` = `Empty` inside and 1 outside. Use
the same trick to check any VBScript-in-WSC semantics before trusting a reading of the code.

**How to apply:** when reviewing or editing a `.wsc`, grep for each `<property name=...>` used as a
bare identifier in the component's own script. `Wise.Dome` is clean now. Other components weren't swept.
