WHAT ACP ACTUALLY RUNS
======================

This directory is not a copy that gets deployed somewhere.  ACP reads it directly, through two
junctions:

    C:\Program Files (x86)\ACP Obs Control\Scripts\Wise
        -> C:\Deploy\ACP\Scripts\Wise
    C:\Deploy\ACP
        -> C:\Users\mizpe\source\repos\ACP

So editing a file here changes what runs, immediately, with no copy step.  The flip side is that
anything written into ACP's Scripts\Wise folder lands in this working tree, and will sit here
untracked until someone commits it.  Check "git status" after touching anything under ACP.


THE .wsc COMPONENTS
===================

To register the .wsc files:

	Right click on register.bat
	Run As Administrator


THE .vbs SCRIPTS
================

Nothing to register - ACP finds them by being in this directory, and they appear in its script
menu.

WiseTrainCorrector.vbs
	ACP's Train Corrector with Moon exclusion added.  Asks for a minimum Moon distance at
	the start of the run, in degrees, and skips mapping points that fall closer than that;
	a rejected candidate is replaced, so the requested number of points still comes out.

	The Moon comes from JPL Horizons - topocentric for this site, which it reads from the
	mount - with a local formula as the fallback if the network is unavailable.  Whichever
	source answered, its uncertainty is added to the requested separation, so a marginal
	point is excluded rather than pointed at.

	It does NOT call the Wise40 driver, and must not be changed to.  An earlier version
	asked the driver for the Moon through an Action, and serving that Action killed
	ASCOM.RemoteServer outright - a native fast-fail with no managed exception and nothing
	in any log.  The Action is withdrawn.  The full account, including the explanations
	already ruled out, is in the ASCOM.Wise40 repo at
	.claude/memory/ascom-moonillumination-kills-the-process.md.
