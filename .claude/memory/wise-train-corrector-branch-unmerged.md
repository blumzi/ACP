---
name: wise-train-corrector-branch-unmerged
description: "origin/wise-train-corrector (PR #1) was compared and DELETED 2026-10-27; its only useful part, the corrector README paragraph, lives in Scripts/README.txt"
metadata:
  type: project
---

`origin/wise-train-corrector` (PR #1, closed unmerged; one commit `7a3e9e1`, 2026-09-24) was kept when the
merged branches were cleaned up on 2026-10-22. Compared on 2026-10-27:

- Its `WiseTrainCorrector.vbs` is byte-identical to master's first tracked version (`6649757`). Master has
  since fixed it twice (`ba9bcfc` ReadLine button set, `411bb87` MAX_POINT_TRIES); the branch copy would
  crash. Nothing unique.
- Its `Scripts/Wise/README.txt` was mostly outdated (junctions, `register.bat`). The still-useful corrector
  paragraph - including "never call the Wise40 driver for the Moon" - now lives in `Scripts/README.txt`.

**Status:** deleted from origin on 2026-10-27 at Arie's request. The commit stays recoverable by SHA
`7a3e9e176ecee8c3471752fbdcc8b7d6bec9cc3b` for a while (GitHub keeps unreferenced commits for some time).

Checking branches out no longer changes what ACP runs - see [[acp-scripts-are-the-live-tree]].
