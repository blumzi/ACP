' =================================================
' 
' Script: StartupObs.vbs
' Author: Arie Blumenzweig
'   Task: Get the observatory ready for operations
' 
' =================================================

sub main

	dim wise_util   : set wise_util   = createobject("Wise.Util")
    dim wise_camera : set wise_camera = createobject("Wise.Camera")
    dim wise_dome   : set wise_dome   = createobject("Wise.Dome")
    dim wise_tele   : set wise_tele   = createobject("Wise.Tele")

    dim label       : label = wise_util.mklabel("Startup")
	dim obs         : obs = wise_util.observatory

	wise_util.info " "
    wise_util.info label & "observatory '" & obs & "' on host '" & wise_util.hostname & "'"
	wise_util.info " "

    wise_dome.startup

    wise_camera.startup

    wise_util.task_run label & "loading FocusMax ...", """C:\Program Files (x86)\FocusMax V4\FocusMax.exe"""

    wise_tele.startup

    if obs = "wise40" then
        wise_dome.get_shutter_to wise_dome.shutterOpen
    end if

    wise_util.info label
    wise_util.info label & "observatory '" & obs & "' is now ready for operations"
    wise_util.info label

end Sub
