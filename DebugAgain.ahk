#include FcnLib.ahk

;A_Debug:=true
;suppressPageReload:=true

if (A_ComputerName <> "PHOSPHORUS")
   ExitApp

;{{{ Get all of the debugger commands from the file
;We'll execute the last command from the file
Loop, read, DebuggerCommands.txt
{
   DebuggerCommand = %A_LoopReadLine%
}
;}}}

;{{{ Set some variables depending upon what mode we are in (project, refresh server, live/not)
;find out if we are in the mode to refresh the server
SysGet, MonitorCount, MonitorCount
refreshServerMode:=GetKeyState("ScrollLock", "T")=="D"

;if we're VPNing, we don't have access to the keyboard, so just always refresh the server
if (MonitorCount = 1)
   refreshServerMode:=true

;DbicDebugMode:=true
;EpmsDebugMode:=true

;TODO make this so we can switch between :wa and :wa!
;force save in gvim
;if blah
   ;gvimForceSaveMode:=true

;find out if we're in live site mode
FileRead, filecontents, C:\code\bench\fl_bench.json
if InStr(filecontents, "argon")
   LiveSiteMode:=true
FileRead, filecontents, C:\code\epms\cgi\epms_local.json
if InStr(filecontents, "prozac")
   LiveSiteMode:=true

;find out what project we're on
StringLeft, project, debuggerCommand, 2
StringLeft, firstFour, debuggerCommand, 4
if (firstFour == "cmd ")
{
   suppressPageReload:=true
   RegExMatch(debuggerCommand, "1: {(.*?)}", projDir)
   RegExMatch(debuggerCommand, "2: {(.*?)}", projRun)
   projDir:=RegExReplace(projDir, "(\d\: \{|\})", "")
   projRun:=RegExReplace(projRun, "(\d\: \{|\})", "")
}
else if (firstFour == "perl")
{
   suppressPageReload:=true
   ;projDir=cd C:\inetpub\EPMS-import\script\property_importers
   projRun:=debuggerCommand
}
else if (project == "FL")
{
   ;suppressPageReload:=true
   projTitle=American Bench
   projDir=C:\code\bench
   projRun=perl -MCarp::Always -I ..\Mitsi\perl\trunk\lib script\fl_bench_server.pl -d
   projRun=perl -I ..\Mitsi\perl\trunk\lib script\fl_bench_server.pl -d
   welcomeTabImage:="images\firebug\WelcomeTab.bmp"
}
else if (project == "TM")
{
   projTitle=Slope Monitor Server
   projDir=C:\code\deepcrow
   projRun=perl -I ..\Mitsi\perl\trunk\lib script\tm_server.pl -d
   welcomeTabImage:="images\firebug\WelcomeTabBlue.bmp"
}
else if (debuggerCommand == "EPMS")
{
   apacheServer:=true
   projTitle=Ellis Partners in Mystery Shopping|EPMS|Survey Detailed Reporting
}
else
{
   debug("unrecognized command")
   ExitApp
}

allWindow=Forms|Parts|Bench|Server|EPMS|Home|xds|phosphorus|Ellis Partners in Mystery Shopping|Survey Detailed Reporting
ffWindow=(%projTitle%).* - Mozilla Firefox ahk_class MozillaUIWindowClass
ieWindow=(%projTitle%).* - Windows Internet Explorer ahk_class IEFrame
;}}}

;{{{ Live site mode warning
if LiveSiteMode
   Run, LiveDbWarning.ahk
;}}}

;{{{ Copy the correct project config over
if LiveSiteMode
{
   FileCopy, C:\code\bench\fl_bench.json.remote, C:\code\bench\fl_bench.json, 1
   FileCopy, C:\code\epms\cgi\epms_LIVE.json, C:\code\epms\cgi\epms_local.json, 1
}
else
{
   FileCopy, C:\code\bench\fl_bench.json.dev, C:\code\bench\fl_bench.json, 1
   FileCopy, C:\code\epms\cgi\epms_mydev.json, C:\code\epms\cgi\epms_local.json, 1
}
;}}}

;{{{ Save files we were working with in Vim
if ForceWinFocusIfExist("\\(strawberry|code|(i|I)netpub).*GVIM ahk_class Vim", "RegEx")
{
   ;TODO flag for overwrite RO files in gvim
   ;SendInput, {Escape 6}{;}wa{!}{Enter}
   SendInput, {Escape 6}{;}wa{Enter}
}
;}}}

;{{{ Restart the server, if desired
if refreshServerMode
{
   if apacheServer
   {
      Run, "C:\Program Files (x86)\Apache Software Foundation\Apache2.2\bin\httpd.exe" -w -n "Apache2.2" -k restart
      WinWaitActive, httpd.exe
      WinMinimize, httpd.exe
      WinWaitClose, httpd.exe
   }
   else
   {
      ;TODO change this to one regex that excludes MINGW32
      if NOT ForceWinFocusIfExist("_server.pl ahk_class ConsoleWindowClass", "Contains")
         if NOT ForceWinFocusIfExist("Administrator: Command Prompt ahk_class ConsoleWindowClass", "Exact")
            if NOT ForceWinFocusIfExist("ahk_class ConsoleWindowClass", "Exact")
               ForceWinFocusIfExist("cmd.exe", "Contains")
      SendInput, ^c

      dd:=WaitForImageSearch("images\cmd\Prompt(dir).bmp")
      ;dd:=WaitForImageSearch("images\cmd\Prompt(dir)lc.bmp")
      if NOT dd
         return
      dd:=WaitForImageSearch("images\cmd\Prompt(arrow).bmp")
      if NOT dd
         return
      SendInput, {esc}cls{ENTER}
      SendInput, {esc}cd C:{ENTER}
      if EpmsDebugMode
         SendInput, set EPMS_UPTO=trace{ENTER}
      else
         SendInput, set EPMS_UPTO={ENTER}
      SendInput, cd %projDir%{ENTER}
      SendInput, %projRun%{ENTER}
      dd:=WaitForImageSearch("images\cmd\PerlServerIsRunning.bmp")
      if NOT dd
         return ;TODO launch build error detection (to go through and find the word "syntax error" or whatever quickly
   }
}
else
{
   if (firstFour == "perl")
   {
      ;perhaps this warning msg should be moved to the top, and it might be nice if it only runs in A_Debug mode
      debug("um, guessing that you meant to have the scrolllock key down to refresh the server (since you're running a perl script)")
      ExitApp
   }
}
;}}}

;{{{ Save files in Ext Designer, if it's open
if ForceWinFocusIfExist("Ext Designer ahk_class QWidget", "Contains")
{
   Send, ^s
   Sleep, 100
   Send, {ALT}
   Sleep, 100
   Send, a
   Sleep, 100
   Send, e
}
;}}}

;FIXME this entire section is so wrong...
;TODO need to change this section so that first we're figuring out what browser we're debugging with. Maybe this will suck because I'm using WinSplitRevolution and windows will exist, but it will be impossible to activate them. I had a feeling of that in the beginning, so that was why I decided to just use WinActivate. But it's a little bit annoying, having browser windows jump one in front of the other (I'd like to coin the term "ADHD-AHK").
SetTitleMatchMode, RegEx
;WinActivate, .*(%allWindow%).* - Google Chrome
WinActivate, .*(%allWindow%).* - Windows Internet Explorer ahk_class IEFrame
WinActivate, .*(%allWindow%|Problem loading page).* - Mozilla Firefox ahk_class MozillaUIWindowClass

IfWinActive, %ieWindow%
   Click, 600, 600
IfWinActive, %ffWindow%
   Click(600, 600, "Control")

Sleep, 500
;TODO maybe we could toggle this on and off easily like server refresh mode
if suppressPageReload
   ExitApp
SendInput, {F5}

Run, RefreshIfProblemLoadingPage.ahk

;WaitForImageSearch("images\firebug\WelcomeTabCruddy.bmp")
;WaitForImageSearch("images\firebug\WelcomeTab.bmp")
;WaitForImageSearch("images\firebug\WelcomeScreen.bmp")

;{{{ Refresh if we're using firefox
if ForceWinFocusIfExist("Ellis Partners in Mystery Shopping: Customer Interface - Mozilla Firefox", "Exact")
{
   ;This section is for testing out EPMS Customer Interface (Initially for Survey Graphing / Reporting)
   Sleep, 500
   ;Click(50,13)
   Click(105,65)
   ;if (MonitorCount = 1)
      ;ClickIfImageSearch("images\firebug\reloadButton.bmp")
   ;if (MonitorCount = 2)
      ;if ClickIfImageSearch("images\firebug\phosphorusAddress.bmp", "Control") || ClickIfImageSearch("images\firebug\phosphorusAddressHighlighted.bmp", "Control")
         ;ClickIfImageSearch("images\firebug\reloadButton.bmp")
   SleepSeconds(7)
   Click(173, 352, "Control")
   Sleep, 700
   Click(173, 376, "Control")
   Sleep, 700
   Click(173, 385, "Control")
   Sleep, 700
   Click(260, 280, "Control")
   ExitApp
}
if ForceWinFocusIfExist(ffWindow, "RegEx")
{
   ForceWinFocus(ffWindow, "RegEx")
   ClickIfImageSearch("images\firebug\ConsoleTab.bmp", "Control")

   if (DebuggerCommand == "EPMS")
      ExitApp

   ForceWinFocus(ffWindow, "RegEx")
   if (welcomeTabImage)
      WaitForImageSearch(welcomeTabImage)

   WaitForImageSearch("images\firebug\LoadedRoles.bmp")
   WaitForImageSearch("images\firebug\LoadedWelcome.bmp")

   ForceWinFocus(ffWindow, "RegEx")
   ClickIfImageSearch("images\firebug\ClearTypedText.bmp", "Control")

   ClickIfImageSearch("images\firebug\SelectCommandWindow.bmp", "Control")

   ;Send, %DebuggerCommand%
   ;SendInput, %DebuggerCommand%
   if ( StrLen(DebuggerCommand) > 4 )
      SendViaClipboard(DebuggerCommand)
   ClickIfImageSearch("images\firebug\RunTypedText.bmp", "Control")

   ExitApp
}
else if ForceWinFocusIfExist("Mozilla Firefox", "Exact")
{
   if (DebuggerCommand == "EPMS")
   {
      Click(500,500)
      if ClickIfImageSearch("images\firebug\phosphorusAddress.bmp", "Control") || ClickIfImageSearch("images\firebug\phosphorusAddressHighlighted.bmp", "Control")
      {
         ;ClickIfImageSearch("images\firebug\reloadButton.bmp", "Control")
         ClickIfImageSearch("images\firebug\reloadButton.bmp")
         ;Send, {F5}
      }
   }
}

;}}}

;{{{ Refresh if we're using IE
if ForceWinFocusIfExist(ieWindow, "RegEx")
{
   if (DebuggerCommand == "EPMS")
      ExitApp

   WaitForImageSearch(welcomeTabImage)

   Sleep, 100
   IfWinNotActive, , Developer Tools Tabs ,
      SendInput, {F12}
   Sleep, 100
   IfWinNotActive, , Developer Tools Tabs ,
      SendInput, {F12}
   Sleep, 100
   ClickIfImageSearch("images\ieDebug\ScriptTab.bmp")
   ClickIfImageSearch("images\ieDebug\MultiLineModeButton.bmp")
   if (ClickIfImageSearch("images\ieDebug\StopDebuggingButton.bmp"))
      SendInput, ^p

   Sleep, 100
   ClickIfImageSearch("images\ieDebug\ScriptTextbox.bmp")
   Sleep, 100

   ;Send, %DebuggerCommand%
   ;SendInput, %DebuggerCommand%
   SendViaClipboard(DebuggerCommand)
   Sleep, 100
   ClickIfImageSearch("images\ieDebug\RunScriptButton.bmp")
   return
   SendInput, {F12}

   ExitApp
}
;}}}
