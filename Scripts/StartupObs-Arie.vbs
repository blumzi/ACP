' ===============================================================
' 
' 
' 			StartupObs.vbs
' 
' 			Author: Ilan Manulis
'			Modified for robotic work by Saar Niv
' 
' 		Task: Open the observatory (in stages)
' 
' Sequence of procedures for the start of observation
'
' 1.	Connect with ScopeDome
' 2.	Turn power_set to the camera on
' 3.	Connect with the camera in ACP, which loads MaxIm DL automatically
' 4.	Open the FocusMax software which loads RoboFocus automatically
' 5.	Connect with the camera In MaxIm DL
' 6.	Turn camera’s cooler on, after changing the temperature set point to an arbitrary,  very low one
' 8.	Turn power_set to the telescope on
' 9.	Connect with the telescope in ACP
' 10.   Synchronize the FS2 controller
' ===============================================================

dim wise_util : set wise_util = createobject("Wise.Util")
dim acp_util  : set acp_util = createobject("ACP.Util")
dim obs       : obs = wise_util.observatory

sub main

    dim wise_camera : set wise_camera = createobject("Wise.Camera")
    dim wise_dome   : set wise_dome = createobject("Wise.Dome")
    dim label       : label = wise_util.mklabel("Startup")
    dim dli

    wise_util.info " "
    wise_util.info label & "observatory '" & obs & "' on host '" & wise_util.hostname & "'"
    wise_util.info " "

    if obs = "c18" or obs = "c28" then
        set dli = createobject("Wise.DliPowerSwitch")
    end if

    ' =========================
    ' 1. Dome startup
    ' =========================
    wise_dome.startup


    ' =================================================================
    ' 3. Connect and cool-down the camera
    ' =================================================================
    wise_camera.startup

    ' =================================================================
    ' 4. Open the FocusMax software which loads RoboFocus automatically
    ' =================================================================
    wise_util.run label & "loading FocusMax ...", """C:\Program Files (x86)\FocusMax\FocusMax.exe"""

    ' =================================
    ' 8. Turn power to the telescope on
    ' =================================
    if obs = "c18" or obs = "c28" then
        if not dli.has_power("Telescope") then
            dli.power_on("Telescope")
            wise_util.sleep 3
        end if
    end if

    ' ====================================
    ' 9. Connect with the telescope in ACP
    ' ====================================
    if not acp_util.telescopeConnected then
        const max_seconds = 30
        dim elapsed    : elapsed = 0
        dim start_time : start_time = timer

        wise_util.info label & "Connecting telescope ..."
        on error resume next
        acp_util.telescopeConnected = True
        if err.number <> 0 then
            wise_util.fatal label & err.description
        end if
        on error goto 0

        do while not acp_util.telescopeConnected and elapsed < max_seconds
            wise_util.sleep 2
            elapsed = int(timer - start_time)
        loop

        if not acp_util.telescopeConnected then
            wise_util.fatal label & "Telescope not connected within " & max_seconds & " seconds"
        end if

        dim msg : msg = "Telescope connected"
        if elapsed > 0 then
            msg = msg & " in " & elapsed & " seconds"
        end if
        wise_util.info label & msg
    end if

    ' ==================================
    ' 10. Synchronize the FS2 controller
    ' ==================================
    if obs = "c28" then
        wise_util.sync_telescope_to_absolute_encoders
    end if

    wise_util.sleep 5
    wise_util.info label & "SUCCESS: observatory '" & obs & "' is now ready to use!"
end Sub
