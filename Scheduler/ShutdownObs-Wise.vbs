' =================================================
'
' Script: ShutdownObs.vbs
' Author: Arie Blumenzweig
'   Task: Shuts the observatory down
'
' =================================================

sub main

    dim wise_util   : set wise_util   = createobject("Wise.Util")
    dim wise_camera : set wise_camera = createobject("Wise.Camera")
    dim wise_tele   : set wise_tele   = createobject("Wise.Tele")
    dim wise_dome   : set wise_dome   = createobject("Wise.Dome")
    dim label       :           label = wise_util.mklabel("Shutdown")

	wise_util.info " "
    wise_util.info label & "observatory '" & wise_util.observatory & "' on host '" & wise_util.hostname & "'"
	wise_util.info " "

	wise_dome.shutdown
    wise_tele.shutdown
	wise_camera.shutdown

	wise_util.task_kill label & "killing FocusMax ...", "FocusMax.exe"

	wise_util.info " "
    wise_util.info label & "observatory '" & wise_util.observatory & "' has been shut down"
	wise_util.info " "

end sub
