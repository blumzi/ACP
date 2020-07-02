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
' Observatory-specific code can be introduced by checking the value of the
'  "observatory" variable (which can be "c18", "c28" or "wise40"
'

dim wise_util       : set wise_util = createobject("Wise.Util")
dim acp_util    : set acp_util = createobject("ACP.Util")
dim observatory : observatory = wise_util.observatory
dim telescope   : set telescope = acp_util.ScriptTelescope				    ' Needed for parking/tracking

dim dli
if observatory = "c18" or observatory = "c28" then
    set dli = createobject("Wise.DliPowerSwitch")
else
    set dli = nothing
end if

dim dome : dome = acp_util.dome
dim telescope_parking_dec, dome_parking_az

switch case observatory
    case "c128"
        telescope_parking_dec = -45.0
        dome_parking_az = 233
        if dome is nothing then set dome = createobject ("Ascom.ScopeDomeUSBDome.DomeLS")

    case "c18"
        telescope_parking_dec = -45.0
        dome_parking_az = 233   ' ???
        if dome is nothing then set dome = createobject("ASCOM.DigialDomeWorks.Dome")

    case "wise40"
        telescope_parking_dec = 66.0
        dome_parking_az = 90
        if dome is nothing then set dome = createobject("ASCOM.Wise40.Dome")

    end select

sub main()

    Dim i

    dim acp_sup   : set acp_support = createobject("ACP.AcquireSupport")    ' Enables slewing

    ' Call ACP.Initialize				    ' commented out by NH, 20190920
    call acp_sup.InitializeUnsafeWeather	' added by NH, 20190920

    if not dli = nothing and not dli.has_power("Telescope") then
        dli.power_on("Telescope")           ' may call wise_util.fatal 
    end if

    if not dli = nothing and  not dli.has_power("Dome") then
        dli.power_on("Dome")                ' may call wise_util.fatal
    end if

    ' =======================
    ' 1. Park the telescope 
    ' =======================

    if not telescope.connected then
        wise_util.connect_and_wait telescope, 30
    fi
    telescope_park

    if telescope.Connected then
        telescope.Connected = False ' Disconnect it from ACP to force dome unslave
    end if
    wise_util.sleep 5
    wise_util.info "The telescope is disconnected"


    ' ===========================================================
    ' 2. Send the dome to its home position and close the shutter
    ' ===========================================================
    dome_park

    ' ===========================================================
    ' 3. Close the shutter
    ' ===========================================================
    shutter_close

    wise_util.connect_and_wait telescope, 25     ' why?

    if not telescope.Connected then
        wise_util.warning "The camera is still ON"
        wise_util.fatal "Failed to connect to the telescope"
    end if

    wise_util.info "The telescope is now connected"

    ' ======================================
    ' 3. Runs the AcquireCalFrames.js script
    ' ======================================

    ' all observatories?
    wise_util.info "Calling AcquireCalFrames"
    acp_util.ChainScript ACPApp.Path & "\Scripts\AcquireCalFrames.js"

end sub

'
' Checks if the shutter is closed
'
function shutter_is_closed
    dim status : status = dome.shutterstatus
    const shutterClosed = 1

    shutter_is_closed = (status = shutterClosed) or (status = "shutterClosed")
end function

'
' Checks if the dome is parked.
' Some domes cannot park, so we check the dome azimuth instead
'
function dome_is_parked
    if dome.canpark then
        dome_is_parked = dome.atpark
    elseif dome.canfindhome then
        dome_is_parked = dome.athome
    else
        dim az = dome.azimuth

        dome_is_parked = az >= (dome_parking_az - 3) and az <= (dome_parking_az + 3)
    fi
end function

'
' Park the dome
'
sub dome_park
    if dome.slewing then
        ' Stop any ongoing slew
        dome.abortslew
        wise_util.sleep 5
    end if

    if not dome_is_parked then
        if dome.canpark then
            dome.park
        elseif dome.canfindhome then
            dome.findhome
        else
            dome.slewtoaz dome_parking_az
        end if

        wise_util.sleep 5   ' let it start slewing
        while dome.slewing
            wise_util.info "dome is at " & int(dome.azimuth) & " degrees ..."
            wise_util.sleep 2
        wend
    end if
    wise_util.info  "dome is parked at " & int(dome.azimuth) & " degrees"
end sub

'
' Close the dome shutter
'
sub shutter_close
    if not shutter_is_closed then

        if observatory = "c28" and not dome.commandbool("Shutter_Link_Strength") then
            wise_util.info "The shutter communication link is poor."
            wise_util.info " Powering the dome OFF."
            dli.power_off "Dome"
            wise_util.sleep 10
            wise_util.info " Powering the dome ON."
            dli.power_on  "Dome"
        end if

        wise_util.info "Closing the shutter"
        dome.closeshutter
        wise_util.sleep 2

        dim start_time : start_time = timer()
        dim timeout    : timeout = 80  'seconds

        do while not shutter_is_closed  and (timer() - start_time) < timeout
            sleep 2
        loop
        if not shutter_is_closed then
            wise_util.fatal "Shutter is not closed after " & timeout & " seconds"
        end if

    end if
    wise_util.info "Shutter is closed"
end sub

'
' Park the telescope
'
sub telescope_park
    if telescope.slewing then
        telescope.abortslew
        wise_util.sleep 5
    end if

    if telescope.canpark then
        if not telescope.atpark then
            wise_util.info "Parking the telescope ..."
            telescope.park
        end if

        if not telescope.atpark then
            wise_util.warning "Failed to park the telescope"
        end if
    else
        ' This telescope cannot Park, we slew it to park position
        dim telescope_parking_ra = acp_util.NowLST()

        wise_util.info "Parking telescope at " & util.HMS_Hours(telescope_parking_ra) & ", " util.DMS_Degrees(telescope_parking_dec)
        telescope.SlewToCoordinatesAsync acp_util.NowLST(), telescope_parking_dec
        wise_util.sleep 2                   ' wait for start of slew
        while telescope.slewing
            wise_util.info "The telescope is at " & util.HMS_Hours(telescope.rightascension) & ", " util.DMS_Degrees(telescope.declination) & " ..."
            wise_util.sleep 5
        wend
    end if
    wise_util.info "The telescope is parked at " & util.HMS_Hours(telescope.rightascension) & ", " util.DMS_Degrees(telescope.declination)
end sub