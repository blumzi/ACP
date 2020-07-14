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
' 2.	Turn power to the camera on
' 3.	Connect with the camera in ACP, which loads MaxIm DL automatically
' 4.	Open the FocusMax software which loads RoboFocus automatically
' 5.	Connect with the camera In MaxIm DL
' 6.	Turn camera’s cooler on, after changing the temperature set point to an arbitrary,  very low one
' 8.	Turn power to the telescope on
' 9.	Connect with the telescope in ACP
' 10.   Synchronize the FS2 controller
' ===============================================================

Sub Main()

Dim domex, ACP, Telescope, PWC, CCDPower, switchName, TelescopePower
Dim SetPoint, Temperature
Dim A, Stringx, DecEnc, RAEnc, Pos, I, ErrStat, ErrStatus, Comma
Dim Arc_Seconds_Per_Tick, Current_Tick, Zero_Altitude
Dim LoadDec, Dec, Degrees, Minutes, Seconds
Dim LoadRa, RA, Hours, RAMinutes, RASeconds
Dim LST, TempCoord
Dim YearVal, MonthVal, DayVal
Dim DateString, MonthValX, DayValX
Dim fso, MyFile, FileName, TextLine, Z
Dim SunSet, MinusSix, MinusTwelve, MinusEighteen, SunSetPlusTenMin


On Error Resume Next


' Dim objShell

Set domex = createobject ("Ascom.ScopeDomeUSBDome.DomeLS")
Set Telescope = Util.ScriptTelescope				' Need this for parking/tracking
' Set ACP = CreateObject("ACP.AcquireSupport")			' Enables slewing

' Call ACP.Initialize

Util.Console.PrintLine "*** Welcome to the Wise Obervatory C-28 telescope!"
Util.Console.PrintLine " "



' =========================
' 1. Connect with ScopeDome
' =========================

If Telescope.Connected = False Then

Util.Console.PrintLine "==> Connecting with the dome. Please wait..."
Util.Console.PrintLine "==>     (may take up to a minute!)"

	' Due to ScopeDome instability!
	' domex.connected=false
	' domex.commandString("Dome_Wait_1000ms")
	' Util.WaitForMilliseconds 20000					' ==> This line is mandatory! Don't remove.
domex.connected=true
domex.commandString("Dome_Wait_1000ms")
Util.WaitForMilliseconds 10000
 
Domex.CommandString ("rel_2_on") 				'==> Changed from rel_1 to rel_2 on 29.11.15
domex.commandString("Dome_Wait_1000ms")
Util.WaitForMilliseconds 10000
Domex.CommandString ("rel_2_off")
domex.commandString("Dome_Wait_1000ms")				'==> Changed from rel_1 to rel_2 on 29.11.15
Util.WaitForMilliseconds 20000					' ==> This line is mandatory! Don't remove.

' domex.connected=true
' domex.commandString("Dome_Wait_3000ms")
' Util.WaitForMilliseconds 8000

Else
Util.Console.PrintLine "==>Telescope is already connected!"

End If


' ==============================
' 2. Turn power to the camera on
' ==============================

Util.Console.PrintLine "==> Applying power to the CCD camera..."

'domex.commandString("Rel_CCD_On")
'domex.commandString("Dome_Wait_1000ms")
'Util.WaitForMilliseconds 10000

set PWC = CreateObject("ASCOM.DigitalLoggers.Switch")
PWC.Connected=True
CCDPower = PWC.GetSwitch(1) 	  ' Change this to 1 when connecting the switch to the real system
switchName = PWC.GetSwitchName(1) ' Change this to 1 when connecting the switch to the real system
Call PWC.SetSwitch (1,True) 	  ' Change this to 1 when connecting the switch to the real system
Util.WaitForMilliseconds 10000


' =====================================================================
' 3. Connect with the camera in ACP, which loads MaxIm DL automatically
' =====================================================================


Util.Console.PrintLine "==> Activating MaxIm DL..."
Util.CameraConnected = True
Util.WaitForMilliseconds 6000


' =================================================================
' 4. Open the FocusMax software which loads RoboFocus automatically
' =================================================================


Util.Console.PrintLine "==> Loading FocusMax + Robofocus..."
Dim shell
Set shell = CreateObject("WScript.Shell") 
shell.Run """C:\Program Files (x86)\FocusMax\FocusMax.exe"""
Util.WaitForMilliseconds 6000


' ======================================
' 5. Connect with the camera In MaxIm DL
' ======================================

Util.Console.PrintLine "==> Connecting with the cameras..."
Camera.LinkEnabled = True
Util.WaitForMilliseconds 6000


' ===================================================================================================
' 6. Turn camera’s cooler on, after changing the temperature set point to an arbitrary,  very low one
' ===================================================================================================


' SetPoint = +10.0									' <== !!!

' SetPoint = -28.0									' <== !!!

SetPoint = -25.0									' <== !!!
Camera.TemperatureSetpoint = SetPoint					' Lower temperature much below ambient
Util.Console.PrintLine "==> Turning camera's cooler on..."
Camera.Cooleron = True
Util.WaitForMilliseconds(5000)



' =================================
' 8. Turn power to the telescope on
' =================================

	' domex.connected=True
Util.Console.PrintLine "==> Applying power to the telescope..."
TelescopePower = PWC.GetSwitch(0)   ' keep this on 0 when connecting the switch to the real system
switchName = PWC.GetSwitchName(0)   ' keep this on 0 when connecting the switch to the real system
Call PWC.SetSwitch (0,True)         ' keep this on 0 but change to True when connecting the switch to the real system	

'domex.commandstring("Rel_Scope_On")
'domex.commandstring("Dome_Wait_1000ms")
Util.WaitForMilliseconds 10000



' ====================================
' 9. Connect with the telescope in ACP
' ====================================

	' domex.connected=false
Util.Console.PrintLine "==> Connecting with the telescope..."
Telescope.Connected = False
Util.WaitForMilliseconds 3000
For I = 1 to 3
	If Telescope.Connected = False Then
		Telescope.Connected = True
		Util.WaitForMilliseconds 8000
	End If
Next

If Telescope.Connected = False Then
	Util.Console.PrintLine "   *** Connecting with the telescope failed. Exiting the script."
	Util.Console.PrintLine "   *** Please note: The camera is still on!"

End If



' ==================================
' 10. Synchronize the FS2 controller
' ==================================

	' --------------------------------------
	' Call function to read encoder's values
	' --------------------------------------
Call Encoders (LoadRA, LoadDec, RA, Dec, ErrStat)

If ErrStat <> 0 then
	Util.Console.PrintLine "   *** Reading the absolute encoders failed. Exiting the script."
	Util.Console.PrintLine "   *** Power to the telescope is beening turned off."
	Util.Console.PrintLine "   *** Please note: The camera is still on!"

	If Telescope.Connected Then Util.ScriptTelescope.Connected = False ' Disconnect telescope from ACP
	dome.commandString("Dome_Wait_1000ms")
	dome.commandString("ScopeOff")
	dome.commandString("Dome_Wait_1000ms")
	Util.WaitForMilliseconds 5000

Else									' <== Makeshift exit
	
Util.WaitForMilliseconds 4000

	' -----------------------------------------
	' Sync the FS2 with the correct coordinates
	' -----------------------------------------
Telescope.TargetRightAscension = LoadRA
Telescope.TargetDeclination = LoadDec
Telescope.SyncToTarget
' MsgBox(CStr(LoadRA) + "  " + CStr(LoadDec))

	'--------------------------------------------
	' Notify user of currently loaded coordinates
	'--------------------------------------------
Degrees = Fix(Dec / 3600)
Dec = Abs(Dec - (Degrees * 3600))
Minutes = Int(Dec / 60)
Seconds = Dec - (Minutes * 60)

Hours = Fix(RA / 3600)
RA = Abs(RA - (Hours * 3600))
RAMinutes = Int(RA / 60)
RASeconds = RA - (RAMinutes * 60)

Util.Console.PrintLine " "
Util.Console.PrintLine "Telescope currently pointing at:"
Util.Console.PrintLine "RA = "+ CStr(Hours) + "h " + Right("00" & CStr(RAMinutes), 2) + "m " + Right("000000" & CStr(FormatNumber(RASeconds, 3)), 6) + "s"
Util.Console.PrintLine "Dec = "+ CStr(Degrees) + "d " + Right("00" & CStr(Minutes), 2) + "m " + Right("000000" & CStr(FormatNumber(Seconds, 3)), 6) + "s"
Util.Console.PrintLine " "

End If



Util.WaitForMilliseconds 5000
Util.Console.PrintLine "==>     Observatory is now open and ready to use!"




End Sub


'===========================================================================================
' Function to obtain encoder's values, parse string and return currently pointed coordinates
'===========================================================================================

Function Encoders (LoadRA, LoadDec, RA, Dec, ErrStat)

'A = "12345678901234"
'
'Do While (Len(A) > 13)
'	A = Shell (String)
'	A = String
'	WScript.Sleep 100
'Loop

' A = "0:3171:NoError,2:2602:NoError"						' <==

' A = Shellby (Stringx)
Call Shellby (Stringx)
' Util.WaitForMilliseconds 4000							' <==
A = Stringx

If (Len(A) > 31) then
	MsgBox("Wrong encoder reading, please try again")
' 	WScript.Quit
End If

ErrStat = 1
If (Len(A) <= 31) then					' <== If not, get out of the function with an error!

'======================
' Parse returned string
'======================

ErrStat = 0
I = 1
DecEnc = 0
Pos = InStr (A,":")
Do While Mid(A,(Pos + I) ,1) <> ":"
	DecEnc = (DecEnc * 10) + CInt(Mid(A, (pos + I), 1))
	I = I + 1
Loop

Pos = Pos + 1
Comma = InStr (A,",")
ErrStatus = Mid (A, (POS + I), (Comma - (Pos + I)))
If ErrStatus <> "NoError" then
	ErrStat = ErrStat + 1
End If

I = 1
RAEnc = 0 
Pos = Pos + Comma - 1
Do While Mid(A,(Pos + I) ,1) <> ":"
	RAEnc = (RAEnc * 10) + CInt(Mid(A, (pos + I), 1))
	I = I + 1
Loop

ErrStatus = Mid (A, (POS + I + 1), Len(A))
If ErrStatus <> "NoError" then
	ErrStat = ErrStat + 1
End If

If ErrStat <> 0 then
	MsgBox("Wrong encoder reading, please try again")
' 	WScript.Quit
End If

If ErrStat = 0 then						' <== If not, get out of the function with an error!


' MsgBox (Cstr(DecEnc) + "   " + Cstr(RAEnc))


'========================================
' Encoders Tick to Coordinates Conversion
'========================================

' Arc_Seconds_Per_Tick = 180		' number of arc seconds per encoder tick
Arc_Seconds_Per_Tick = 175.04		' number of arc seconds per encoder tick

'====================
' Declination Encoder
'====================

Zero_Altitude = 30.596744 - 90		' declination at 0 altitude South, negative value
Zero_Altitude = Zero_Altitude *3600	' converted to seconds

' Current_Tick = 1221
Current_Tick = DecEnc			' get Declination encoder value
' Current_Tick = Current_Tick * Arc_Seconds_Per_Tick	' how many arc-seconds we are above altitude 0
Current_Tick = (Current_Tick + 51.01) * Arc_Seconds_Per_Tick	' how many arc-seconds we are above altitude 0

Dec = Zero_Altitude + Current_Tick	' current Declination in arc-seconds
If Dec >= 324000 then			' normalize for Declination 90 degrees
	Dec = 324000 - (Dec - 324000)
End If
LoadDec = Dec /3600

'========================
' Right Ascension Encoder
'========================

' Current_Tick = 1221
Current_Tick = RAEnc			' get RA encoder value
' Current_Tick = Current_Tick * Arc_Seconds_Per_Tick	' how many arc-seconds we are above horizon
Current_Tick = (Current_Tick + 51.01) * Arc_Seconds_Per_Tick	' how many arc-seconds we are above horizon
Current_Tick = Current_Tick / 15	' convert to h:m:s format

RA = Current_Tick			' current RA in arc-seconds
LoadRA = RA / 3600

'==============================================
' Finally, prepare to sync the FS2 with the sky
'==============================================

' Get LST from ACP
LST = Util.NowLST() 		' Current local apparent sidereal time

If RAEnc <= 1800 then
	LoadRA = (LST - (6 - LoadRA))
	If LoadRA < 0 then LoadRA = LoadRA + 24
Else
	LoadRa = (LST + (LoadRA - 6))
	If LoadRA >= 24 then LoadRA = LoadRA - 24
End If
RA = LoadRA * 3600


'============================================
' Notify user of currently loaded coordinates
'============================================

TempCoord = Dec
Degrees = Fix(Dec / 3600)
Dec = Abs(Dec - (Degrees * 3600))
Minutes = Int(Dec / 60)
Seconds = Dec - (Minutes * 60)
Dec = TempCoord

TempCoord = Ra
Hours = Fix(RA / 3600)
RA = Abs(RA - (Hours * 3600))
RAMinutes = Int(RA / 60)
RASeconds = RA - (RAMinutes * 60)
RA = TempCoord

' MsgBox("Telescope currently pointing at:"_
' 	& vbCrLf & _
' 	"RA = "+ CStr(Hours) + "h " + Right("00" & CStr(RAMinutes), 2) + "m " + Right("000000" & CStr(FormatNumber(RASeconds, 3)), 6) + "s" _
' 	& vbCrLf & _
' 	"Dec = "+ CStr(Degrees) + "d " + Right("00" & CStr(Minutes), 2) + "m " + Right("000000" & CStr(FormatNumber(Seconds, 3)), 6) + "s")


End If							' <== Makeshift function exit
End If							' <== Makeshift function exit

End Function


'===================================================
' Acquire Encoders Value Function
' Syntax: "A2Read Com5 0 1 retry=nn"
' Return string = "0:nnnn:NoError,1:nnnn:NoError"
' 		  	 "HasError" in case of error
'===================================================

Function shellby (Stringx)
	' Run a command as if you were running from the command line
	dim objShell, ObjExec, objWshScriptExec, objStdOut

	Set objShell = CreateObject ("WScript.Shell")
	Set objWshScriptExec = objShell.Exec("C:\SEI\A2Read\A2Read\A2Read\bin\Debug\A2Read.exe" & " COM10 0 1 retry=15")
	Set objStdOut = objWshScriptExec.StdOut
	Stringx = objStdOut.ReadLine
	Set objShell = Nothing
End Function

'sub test_main()
'    Call Encoders (LoadRA, LoadDec, RA, Dec, ErrStat)
'    util.Console.PrintLine "LoadRA: " & LoadRA & ", LoadDec: " & LoadDec & ", RA: " & RA & ", Dec: " & Dec
'end sub
