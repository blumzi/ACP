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

	' FocusMax comes back after being killed, so kill it until it stays dead
	kill_until_gone wise_util, label, "FocusMax.exe", 3

	wise_util.info " "
    wise_util.info label & "observatory '" & wise_util.observatory & "' has been shut down"
	wise_util.info " "

end sub

'
' Kills every process named image, up to max_tries times, until none is left.
' Logs who started each one, to tell a COM re-activation (parent svchost,
' "-Embedding" or "/Automation" on the command line) from a restart by some program.
'
sub kill_until_gone(wise_util, label, image, max_tries)
    dim wmi   : set wmi   = getobject("winmgmts:\\.\root\cimv2")
    dim shell : set shell = createobject("WScript.Shell")
    dim try, procs, p

    for try = 1 to max_tries
        set procs = processes_named(wmi, image)
        if procs.count = 0 then
            exit for
        end if

        for each p in procs
            wise_util.info label & "killing " & image & " (try " & try & " of " & max_tries & "): pid " & p.ProcessId & _
                ", started by " & process_name(wmi, p.ParentProcessId) & ", command line: " & p.CommandLine
        next
        shell.run "taskkill /f /im " & image, 0, true    ' hidden, and wait for it
        wise_util.sleep 5                                  ' give a respawn time to show up
    next

    if processes_named(wmi, image).count = 0 then
        wise_util.info label & image & " is not running"
    else
        wise_util.warning label & image & " is still running after " & max_tries & " kills"
    end if
end sub

function processes_named(wmi, image)
    set processes_named = wmi.execquery("select ProcessId, ParentProcessId, CommandLine from Win32_Process where Name = '" & image & "'")
end function

function process_name(wmi, pid)
    dim procs, p
    set procs = wmi.execquery("select Name from Win32_Process where ProcessId = " & pid)
    process_name = "pid " & pid & " (exited)"
    for each p in procs
        process_name = p.Name & " (pid " & pid & ")"
    next
end function
