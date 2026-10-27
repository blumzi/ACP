WHERE THESE FILES GO
====================

Nothing in this repository is read by ACP directly.  Since 2026-10-27 the live folders on dome-pc are
ordinary folders, and the files get there by being deployed - see deploy\README.txt and the
manifest-*.txt files, which say which file goes where on which machine.  Editing, switching branches,
stash, clean and reset here do not change what ACP runs.

(Before that, ACP's Scripts\Wise was a junction into this working tree, and every git operation was a
deployment.  Some older notes and commit messages still describe that.)


NOT EVERYTHING IN ACP'S SCRIPTS FOLDER COMES FROM HERE
------------------------------------------------------

Most of it ships with ACP.  "Wise40 Action Test.vbs" and "Wise40 Calibration Run.vbs" used to be
copied in from the ASCOM.Wise40 repository (AcpScripts\); they are no longer needed and are not
deployed.


REGISTERING THE .wsc COMPONENTS
-------------------------------

The deploy script registers them (the "register" entries in deploy\manifest-*.txt; see
deploy\README.txt).  Scripts\Wise\register is an older bash version of the same job, kept but no
longer used, and out of date: it leaves out Wise.Dli.wsc and WiseWeather.wsc.  The .vbs scripts need
no registration - ACP finds them by their being in the directory.


WiseTrainCorrector.vbs
----------------------

ACP's Train Corrector with Moon exclusion added.  Asks for a minimum Moon distance at the start of the
run, in degrees, and skips mapping points that fall closer than that; a rejected candidate is replaced,
so the requested number of points still comes out.

The Moon comes from JPL Horizons - topocentric for this site, which it reads from the mount - with a
local formula as the fallback if the network is unavailable.  Whichever source answered, its
uncertainty is added to the requested separation, so a marginal point is excluded rather than pointed
at.

It does NOT call the Wise40 driver, and must not be changed to.  An earlier version asked the driver
for the Moon through an Action, and serving that Action killed ASCOM.RemoteServer outright - a native
fast-fail with no managed exception and nothing in any log.  The Action is withdrawn.  The full
account, including the explanations already ruled out, is in the ASCOM.Wise40 repo at
.claude/memory/ascom-moonillumination-kills-the-process.md.

It is deployed to ACP's top-level Scripts folder, beside the stock "Train Corrector.vbs".
