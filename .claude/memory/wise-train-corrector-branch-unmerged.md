---
name: wise-train-corrector-branch-unmerged
description: "origin/wise-train-corrector (PR #1, closed unmerged) holds a Scripts/Wise/README.txt and a different WiseTrainCorrector.vbs that exist nowhere else - don't delete it without comparing"
metadata:
  type: project
---

When the merged branches were cleaned up on 2026-10-22, **`origin/wise-train-corrector` was kept on
purpose.** Its PR #1 was *closed, not merged*, and its one commit (`7a3e9e1`, "Track
WiseTrainCorrector.vbs, which ACP has been running untracked") carries:

- `Scripts/Wise/README.txt`, which `master` doesn't have;
- a `WiseTrainCorrector.vbs` that **differs** from the one on `master`.

**How to apply:** before deleting the branch, diff both files against `master` and let Arie decide
which version of the corrector is the real one. Remember that checking it out changes what ACP runs
([[acp-scripts-are-the-live-tree]]).
