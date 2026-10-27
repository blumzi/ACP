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

    start_focusmax wise_util, label, obs

    wise_tele.startup

    if obs = "wise40" then
        wise_dome.get_shutter_to wise_dome.shutterOpen
    end if

    wise_util.info label
    wise_util.info label & "observatory '" & obs & "' is now ready for operations"
    wise_util.info label

end Sub

'
' Which FocusMax is installed differs per observatory, and the wrong one either is not there (c28 has
' only V4) or cannot run (V4 on wise40).  An observatory not listed here is an error, not a guess.
'
sub start_focusmax(wise_util, label, obs)
    dim folder

    select case obs
        case "c18"
            folder = "FocusMax"
        case "c28"
            folder = "FocusMax V4"
        case "wise40", "h80"
            folder = "FocusMax V5"
        case else
            wise_util.fatal "StartupObs", label & "no FocusMax known for observatory '" & obs & "'"
    end select

    wise_util.task_run label & "loading FocusMax ...", """C:\Program Files (x86)\" & folder & "\FocusMax.exe"""
end sub
