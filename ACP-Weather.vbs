'
' Standard ACP Weather Safety script. Please see ACP Help, Customizing ACP, 
' Adding to ACP's Logic, Weather Safety Script. If you have a real dome Or
' if the scope can clear your roll-off roof under all conditions, then 
' you can adjust this so that the dome/roof closes right away. 
'
' NOTE: This assumes tht you have the ACP Dome Control option "Close and 
'       park/home [dome] AFTER scope is parked by script" ON/Set. 
'
' NOTE: To have your safe roof or real dome close right away, turn OFF the 
'       above option and uncomment the indicated lines for opening the dome
'
' This runs when there is a weather unsafe event.
'
sub main
	dim wise_util : set wise_util = createobject("Wise.Util")
	dim wise_dome : set wise_dome = createobject("Wise.Dome")
	dim wise_tele : set wise_tele = createobject("Wise.Tele")

	dim label     : label = wise_util.mklabel("ACP-Weather")
	dim obs       : obs   = wise_util.observatory

	wise_util.info label & "started"
    on error resume next                        ' Best efforts...

	select case obs
		case "c28"
			if not wise_dli.has_power("Telescope") then
				wise_dli.power_on("Telescope")
				wise_util.sleep 5
			end if

			if not telescope.connected then
				telescope.connected = true		' this will also connect to the dome
				wise_util.info label & "connected Telescope"
			end if

			wise_dome.shutdown
			wise_tele.slew_to_parking_position
	end select

    wise_util.info label &  "done"
end sub
