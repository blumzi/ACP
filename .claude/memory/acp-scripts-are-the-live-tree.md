---
name: acp-scripts-are-the-live-tree
description: This repo IS ACP's script directory, via two junctions — so git operations here change what ACP runs, immediately
metadata:
  type: project
---

ACP does not run a copy of this repository. It runs **this working tree**, reached through two
junctions:

```
C:\Program Files (x86)\ACP Obs Control\Scripts\Wise
        -> C:\Deploy\ACP\Scripts\Wise
C:\Deploy\ACP
        -> C:\Users\mizpe\source\repos\ACP
```

`Scripts/README.txt` says these scripts "go into" ACP's Scripts folder. They don't get copied
there — for `Scripts\Wise` the folder *is* here.

**Why:** there is no deploy step to forget, and no second copy to drift. The cost is that
ordinary git commands have operational consequences.

**How to apply:**

- **Switching branches changes what ACP runs.** Checking out a branch that lacks a script
  *deletes that script from ACP's menu*, live. This happened on 2026-09-24: a
  `git checkout master` removed `WiseTrainCorrector.vbs` from ACP while it was only committed on
  a feature branch. Harmless mid-afternoon; not harmless during a run. Before switching branches
  or rebasing, know whether ACP is executing anything.
- **Anything written into ACP's script folder lands here untracked.** A file that looks like it
  was "installed into ACP" is actually sitting in this working tree waiting to be committed.
  `git status` after touching anything under ACP.
- The same logic applies to `git stash`, `git clean` and a hard reset: they are deployments.

Related: [[acp-abort-mechanism]] for the other way a script can misbehave at an awkward moment.
