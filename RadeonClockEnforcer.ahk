/*

v1.0.0 - Written with AutoHotKey_L v1.1.33.02

RadeonClockEnforcer by: https://github.com/hoffr/
Requires OverdriveNTool by: https://forums.guru3d.com/threads/overdriventool-tool-for-amd-gpus.416116/

Description: Force maximum clocks while important applications are open. Automates OverdriveNTool's clock/voltage switching functionality for GPU and VRAM, with the purpose of enforcing maximum clocks while whitelisted applications are in focus.

Uses MIT License as declared in README_RadeonClockEnforcer.txt directly alongside this file

I encourage forks, modifications and improvements!

*/


#SingleInstance,force
Menu,Tray,NoStandard
Menu,Tray,NoIcon
Menu,Tray,Add,% "Exit",% "ExitScript"


; CHECK FOR AND/OR CREATE .INI:
if (!FileExist(A_ScriptDir "\RadeonClockEnforcer.ini"))
{
	firstRun := 1
	
	FileAppend,
	(
[Settings]
;
; Should RadeonClockEnforcer run on Windows startup? (True | False)
startup=True
;
; Should we force max clocks for all focused fullscreen apps? (All | None)
; "All" may also detect browser fullscreen (eg. YouTube), PowerPoint presentations, etc.
; As a workaround, you can specify blacklists down further below. This is the recommended setting/method.
forcefullscreen=All
;
; Show tray icon?
showtrayicon=True
;
; List here the apps we should force max clocks for when they're focused.
; .exe file names only (no paths), separated by commas:
whitelistwin=hl2.exe, VRChat.exe, Big Rigs.exe, Heaven.exe, Tower-Win64-Shipping.exe
;
; List here the apps we should force default clocks for if they're focused.
; Takes precedence over "whitelistwin"
blacklistwin=firefox.exe, chrome.exe, iridium.exe, brave.exe, opera.exe, powerpnt.exe, wmplayer.exe, vlc.exe, mpc-hc.exe, mpc-hc64.exe, JagexLauncher.exe, TTREngine.exe, dosbox.exe
;
; List here the apps we should force max clocks for if they're running at all, even in the background.
; Takes precedence over all other conditions except "blacklistproc".
whitelistproc=Heaven.exe, geekbench_x86_64.exe, memtestCL.exe, PerformanceTest64.exe
;
; List here the apps we should force default clocks for if they are running at all, even in the background.
; Takes precedence over all other conditions.
blacklistproc=B1TC01N_M1N1N6_D4T4_S734L3R.exe
;
; These two values are the names of the profiles to switch between. Order matters. Be very careful with these!
profilenames=default, max

	),RadeonClockEnforcer.ini,UTF-16
}



; --------------------------------
; setup & ini parsing

while (!FileExist(A_ScriptDir "\RadeonClockEnforcer.ini")) {
	if (A_Index = 5) {
		msgbox,% "cannot read .ini file, exiting"
		exitapp
	}
	sleep,200
}

IniRead,startup,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,startup
IniRead,forcefullscreen,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,forcefullscreen
IniRead,whitelistwin,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,whitelistwin
IniRead,blacklistwin,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,blacklistwin
IniRead,whitelistproc,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,whitelistproc
IniRead,blacklistproc,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,blacklistproc
IniRead,showtrayicon,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,showtrayicon
IniRead,profilenames,% A_ScriptDir "\RadeonClockEnforcer.ini",Settings,profilenames

if (showtrayicon = "true") {
	;Menu,Tray,Icon,shell32.dll,266,1
	Menu,Tray,Icon
}


whitelistwinArr := []
loop,parse,% whitelistwin,CSV
{ ; loop,parse/read braces can't be on same line
	loopfieldNoSpaces = %A_Loopfield% ; traditional assignment operator trims spaces from start & end
	whitelistwinArr.Push(loopfieldNoSpaces)
}
blacklistwinArr := []
loop,parse,% blacklistwin,CSV
{ ; loop,parse/read braces can't be on same line
	loopfieldNoSpaces = %A_Loopfield% ; traditional assignment operator trims spaces from start & end
	blacklistwinArr.Push(loopfieldNoSpaces)
}
whitelistprocArr := []
loop,parse,% whitelistproc,CSV
{ ; loop,parse/read braces can't be on same line
	loopfieldNoSpaces = %A_Loopfield% ; traditional assignment operator trims spaces from start & end
	whitelistprocArr.Push(loopfieldNoSpaces)
}
blacklistprocArr := []
loop,parse,% blacklistproc,CSV
{ ; loop,parse/read braces can't be on same line
	loopfieldNoSpaces = %A_Loopfield% ; traditional assignment operator trims spaces from start & end
	blacklistprocArr.Push(loopfieldNoSpaces)
}
loop,parse,% profilenames,CSV
{ ; loop,parse/read braces can't be on same line
	realIndex := A_Index
	zeroBasedIndex := realIndex - 1
	profile%zeroBasedIndex% = %A_Loopfield% ; traditional assignment operator trims spaces from start & end
}
if (realIndex != 2) {
	msgbox,0,% "RadeonClockEnforcer",% "ERROR: Number of profiles specified in .ini are incorrect. There must be 2 profiles specified. Exiting"
	exitapp
}


if (startup = "true") { ; note str comparison is not case sensitive by default in ahk
	startup := 1
} else {
	startup := 0
}
if (startup = "true") { ; note str comparison is not case sensitive by default in ahk
	startup := 1
} else {
	startup := 0
}


if (firstRun) {
	msgbox,0,% "RadeonClockEnforcer",% "FIRST RUN INFO:`n`nPlease read through README_RadeonClockEnforcer.txt,or else this program won't function correctly and may even harm your system.`n`nA template .ini configuration file has been created in the directory alongside this program. Go edit it to your liking before running this program again!"
	exitapp
}

; ---

if (startup || firstRun) {
	if (!FileExist(A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk")) {
		FileCreateShortcut,% A_ScriptDir "\RadeonClockEnforcer.exe",% A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk"
	}
} else {
	if (FileExist(A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk")) {
		FileRecycle,% A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk"
	}
}


SplitPath,A_ScriptDir,,ODNTPath ; define up-one-folder from script as path to OverDriveNTool.exe

if (!FileExist(ODNTPath "\OverdriveNTool.exe")) {
	msgbox,% "Cannot locate """ ODNTPath "\OverdriveNTool.exe" """`n`nExiting"
	exitapp
}



; ---------------------------------------
; main loop

; profile0 = default, profile1 = max
ErrorLevel := 0
runwait,% "OverdriveNTool.exe -p0" profile0,% ODNTPath,UseErrorLevel
if (ErrorLevel != 0) {
	msgbox,% "Error while calling """ ODNTPath "\OverdriveNTool.exe -p0" profile0 """`n`nWIN32 error code: " A_LastError "`n`nExiting"
	exitapp
}
; soundplay,*16 ; FOR TESTING


profileTimestamp := A_TickCount
profileNext	:= profile0
profileCurrent := profile0
maxTimer := 4000
minTimer := 2000
currentTimer := maxTimer
OnExit,ExitSub

loop {
	
	profileNext := SetProfile()
	
	if (profileNext = profile0) {
		currentTimer := 2000
	} else {
		currentTimer := 4000
	}
	
	; prevent rapid profile switching (eg. 60 times a second) which could lead to gpu damage
	if (profileNext != profileCurrent) {
		while (A_TickCount - profileTimestamp < 1000) {
			sleep,200
		}
		
		ErrorLevel := 0
		runwait,% "OverdriveNTool.exe -p0" profileNext,% ODNTPath,UseErrorLevel
		if (ErrorLevel != 0) {
			msgbox,% "Error while calling """ ODNTPath "\OverdriveNTool.exe -p0" profileNext """`n`nWIN32 error code: " A_LastError "`n`nExiting"
			OnExit
			exitapp
		}
		
		; ; FOR TESTING, to avoid GPU accident (to use real code uncomment above^):
		; if (profileNext = profile0) {
			; soundplay,*16
		; } else {
			; soundplay,*-1
		; }
		
		profileTimestamp := A_TickCount
		profileCurrent := profileNext
	}
	
	sleep,% currentTimer
}



; ---------------------------------------------------
; funcs & subs


SetProfile() {

	global status_wl_proc, status_bl_proc, status_wl_win, status_bl_win, status_fullscreen, forcefullscreen
	global whitelistprocArr, blacklistprocArr
	global profile0, profile1

	status_wl_proc := ProcessExistFromList(whitelistprocArr)
	status_bl_proc := ProcessExistFromList(blacklistprocArr)
	
	if (status_wl_proc) {
		if (status_bl_proc) {
			profileNext := profile0
		} else {
			profileNext := profile1
		}
	}
	
	if !(status_wl_proc || status_bl_proc) {
		
		status_fullscreen := IsSessionFullscreen()
		status_wl_win := WinActiveFromList(whitelistwinArr)
		status_bl_win := WinActiveFromList(blacklistwinArr)
		
		; check for photo viewer to prevent fullscreen maxing
		; note: may upclock for one loop when loading fullscreen if photoviewer decides to 'unfocus'
		if (WinActive("ahk_class Photo_Lightweight_Viewer")) {
			WinGet,photoviewPID,PID,% "ahk_class Photo_Lightweight_Viewer"
		}
		if (WinActive("ahk_pid" photoviewPID)) {
			status_wpv := 1
		} else {
			status_wpv := 0
		}
		
		if (status_fullscreen) {
			if (forcefullscreen = "All") {
				if (status_bl_win || status_wpv) {
					profileNext := profile0
				} else {
					profileNext := profile1
				}
			}
			if (forcefullscreen = "None") {
				if (status_wl_win) {
					if (status_bl_win) {
						profileNext := profile0
					} else {
						profileNext := profile1
					}
				}
			}
		} else {
			if (status_wl_win) {
				if (status_bl_win) {
					profileNext := profile0
				} else {
					profileNext := profile1
				}
			} else {
				profileNext := profile0
			}
		}
	}
	
	return profileNext
	
}


IsSessionFullscreen() {
	/*
	Return 1 if session is fullscreen
	https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryusernotificationstate
	typedef enum  {
	  QUNS_NOT_PRESENT,
	  QUNS_BUSY,
	  QUNS_RUNNING_D3D_FULL_SCREEN,
	  QUNS_PRESENTATION_MODE,
	  QUNS_ACCEPTS_NOTIFICATIONS,
	  QUNS_QUIET_TIME,
	  QUNS_APP
	} QUERY_USER_NOTIFICATION_STATE;
	*/
	
	if (!DllCall("Shell32.dll\SHQueryUserNotificationState","Int*",pquns)) { ; S_OK=0
		if (pquns = 2 || pquns = 3 || pquns = 4) {
			return 1
		} else {
			return 0
		}
	}
}


ProcessExistFromList(arr) {
	loop % arr.MaxIndex() {
		ErrorLevel := 0
		Process,Exist,% arr[A_Index]
		if (ErrorLevel) {
			return 1
		}
	}
	return 0
}


WinActiveFromList(arr) {
	loop % arr.MaxIndex() {
		if (WinActive("ahk_exe" arr[A_Index])) {
			return 1
		}
	}
	return 0
}


ExitScript: ; menu item subroutine
exitapp


ExitSub:
	if (profileCurrent = profile1) {
		while (A_TickCount - profileTimestamp < 1000) {
			sleep,200
		}
		run,% "OverdriveNTool.exe -p0" profile0,% ODNTPath,UseErrorLevel
		if (ErrorLevel != 0) {
			msgbox,% "ERROR DURING SCRIPT EXIT: Error while calling """ ODNTPath "\OverdriveNTool.exe -p0" profile0 """`n`nWIN32 error code: " A_LastError "`n`nCould not apply default profile. For now, you may need to manually apply a profile from within Radeon settings/WattMan or OverDriveNTool."
		}
		
		; ; FOR TESTING:
		; profileNext := profile0
		; soundplay,*16
	}
exitapp
