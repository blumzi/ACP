' ===============================================================
' 
' 
' 			StartupObs.vbs
' 
' 			Author: Arie Blumenzweig
' 
' 		      Task: Open the observatory (in stages)
' 
' ===============================================================

dim wise_util : set wise_util = createobject("Wise.Util")
dim obs       : obs = wise_util.observatory

sub main

    dim wise_camera : set wise_camera = createobject("Wise.Camera")
    dim wise_dome   : set wise_dome = createobject("Wise.Dome")
    dim wise_tele   : set wise_tele = createobject("Wise.Tele")
    dim label       : label = wise_util.mklabel("Startup")

    wise_util.info " "
    wise_util.info label & "observatory '" & obs & "' on host '" & wise_util.hostname & "'"
    wise_util.info " "

    wise_dome.startup

    wise_camera.startup

    wise_util.run label & "loading FocusMax ...", """C:\Program Files (x86)\FocusMax\FocusMax.exe"""

    wise_tele.startup

    if obs = "c28" then
        wise_tele.sync_to_absolute_encoders
    end if

    wise_util.sleep 5
    wise_util.info label & "SUCCESS: observatory '" & obs & "' is now ready to use!"

end Sub
