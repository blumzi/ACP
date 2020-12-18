' ===============================================================
' 
' 
' 			ShutdownObs.vbs
' 
' 			Written by: Saar Niv			
' 
' 		Task: Close The observatory gracefully
' 
' 
' Sequence of procedures for the end of observation (Part 1)
' 
' 1.	Park telescope 
' 2.	Send the dome to its home position and close the shutter
' 3.	Runs the AcquireCalFrames.js script
' 
' ===============================================================

'
' This is a generic ACP shutdown script.  It runs at all the Wise observatories.
'

dim acp_util    : set acp_util = createobject("ACP.Util")
'dim telescope   : set telescope = acp_util.ScriptTelescope				    ' Needed for parking/tracking

sub main

    dim acp_sup     :     set acp_sup = createobject("ACP.AcquireSupport")    ' Enables slewing
    dim wise_util   :   set wise_util = createobject("Wise.Util")
    dim wise_camera : set wise_camera = createobject("Wise.Camera")
    dim wise_dome   :   set wise_dome = createobject("Wise.Dome")
    dim wise_tele   :   set wise_tele = createobject("Wise.Tele")
    dim label       : label = wise_util.mklabel("Startup")

    wise_util.info " "
    wise_util.info label & "observatory '" & wise_util.observatory & "' on host '" & wise_util.hostname & "'"
    wise_util.info " "

    ' Call ACP.Initialize				    ' commented out by NH, 20190920
    call acp_sup.InitializeUnsafeWeather	' added by NH, 20190920

    wise_tele.shutdown
    wise_dome.shutdown

'    wise_util.connect_and_wait telescope, 25     ' why?

'    if not telescope.Connected then
'        wise_util.warning "The camera is still ON"
'        wise_util.fatal "Failed to connect to the telescope"
'    end if

    '
    ' The code below is fishy !!!
    '
    ' Do we need to call wise_camera.shutdown?
    '

'    wise_util.info "The telescope is now connected"

'    ' ======================================
'    ' 3. Runs the AcquireCalFrames.js script
'    ' ======================================

'    ' all observatories?
'    wise_util.info "Calling AcquireCalFrames"
'    acp_util.ChainScript ACPApp.Path & "\Scripts\AcquireCalFrames.js"

end sub
