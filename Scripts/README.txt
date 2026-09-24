WHERE THESE FILES GO
====================

It depends on which directory they are in, and the two halves work differently.  This file used
to say everything here "goes into" ACP's Scripts folder.  That is no longer true of Scripts\Wise.


Scripts\Wise\  --  ALREADY THERE.  DO NOT COPY.
------------------------------------------------

ACP reads this directory directly, through two junctions:

    C:\Program Files (x86)\ACP Obs Control\Scripts\Wise
        -> C:\Deploy\ACP\Scripts\Wise
    C:\Deploy\ACP
        -> this repository

So editing a file here changes what ACP runs, immediately, with no copy step.  Two consequences
that are easy to get caught by:

  - Anything written into ACP's Scripts\Wise folder lands in this working tree and sits there
    untracked until someone commits it.  Run "git status" after touching anything under ACP.

  - Git operations are deployments.  Checking out a branch that lacks a script removes that
    script from ACP's menu, live; the same goes for stash, clean and a hard reset.  Know whether
    ACP is executing anything before switching branches.

See .claude/memory/acp-scripts-are-the-live-tree.md.


Scripts\ itself  --  COPY.
--------------------------

    C:\Program Files (x86)\ACP Obs Control\Scripts

Scripts\Wise is the ONLY junction under ACP's Scripts folder, so everything beside it - FS2_Sync.vbs
here - is an ordinary file that has to be put there by hand, and will drift from this repository if
it is then edited in place.


NOT EVERYTHING IN ACP'S SCRIPTS FOLDER COMES FROM HERE
------------------------------------------------------

Most of it ships with ACP.  "Wise40 Action Test.vbs" and "Wise40 Calibration Run.vbs" are tracked
in the ASCOM.Wise40 repository under AcpScripts\ and copied in from there.


REGISTERING THE .wsc COMPONENTS
-------------------------------

Scripts\Wise\register does it, from a bash shell.  The .vbs scripts need no registration - ACP
finds them by their being in the directory.
