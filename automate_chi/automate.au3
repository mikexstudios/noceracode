#include <Date.au3>

Run('chi760d.exe')
WinWaitActive('CHI760D Electrochemical Workstation')
$main_hWnd = WinGetHandle('CHI760D Electrochemical Workstation')

Send('!st') ; open up the system -> techniques window
WinWaitActive('Electrochemical Techniques')
; single left click the chronopotentiometry item (at relative coordinates 55, 321)
ControlClick('Electrochemical Techniques', '', 1000, 'left', 1, 55, 321)
Send('{ENTER}') ; OK button

WinWaitActive('Chronopotentiometry Parameters')
; the nice thing is that each field in the dialog box is ALT accessible
Send('!C') ; Cathodic Current (A)
Send('0')
Send('!A') ; Anodic Current (A)
Send('0.85')
Send('!H') ; High E Limit (V)
Send('2')
Send('!L') ; Low E Limit (V)
Send('0')
Send('!T') ; Cathodic Time (sec)
Send('1')
Send('!m') ; Anodic Time (sec)
Send('300')
Send('!I') ; Initial Polarity
Send('a')
Send('!D') ; Data Storage Interval (sec)
Send('1')
Send('!e') ; Set Current Switching Priority to Time
Send('{ENTER}') ; OK button

; Figure out a way to check if experiment has completed

; Test for program responsiveness
$is_main_hung = DLLCall('user32.dll',"bool","IsHungAppWindow","hwnd",$main_hWnd)
If $is_main_hung == True Then
	SendAndLog('Main window is hung.')
Else
	SendAndLog('Main window is resonsive.')
EndIf

Func SendAndLog($Data, $FileName = -1, $TimeStamp = False)
    If $FileName == -1 Then $FileName = @ScriptDir & '\Log.txt'
    Send($Data)
    $hFile = FileOpen($FileName, 1)
    If $hFile <> -1 Then
        If $TimeStamp = True Then $Data = _Now() & ' - ' & $Data
        FileWriteLine($hFile, $Data)
        FileClose($hFile)
    EndIf
EndFunc


