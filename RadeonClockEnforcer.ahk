/*

v1.2.0 - Written with AutoHotKey_L v1.1.33.02

RadeonClockEnforcer by: https://github.com/hoffr/
Requires OverdriveNTool by: https://forums.guru3d.com/threads/overdriventool-tool-for-amd-gpus.416116/

Description: Force maximum clocks while important applications are open. Automates OverdriveNTool's clock/voltage switching functionality for GPU and VRAM, with the purpose of enforcing maximum clocks while whitelisted applications are in focus.

Uses MIT License as declared in README_RadeonClockEnforcer.txt directly alongside this file

I encourage forks, modifications and improvements!

*/


#SingleInstance,force
Menu,Tray,NoStandard
Menu,Tray,NoIcon
Menu,Tray,Add,% "View active code",% "ViewCode"
Menu,Tray,Add ; separator
Menu,Tray,Add,% "Exit",% "ExitScript"

gosub,CheckProcessCount


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

	),% A_ScriptDir "\RadeonClockEnforcer.ini",UTF-16
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
	if (A_Index = 1) {
		prof_min = %A_Loopfield% ; traditional assignment operator trims spaces from start & end
	} else if (A_Index = 2) {
		prof_max = %A_Loopfield%
	} else {
		msgbox,0,% "RadeonClockEnforcer",% "ERROR: Number of profiles specified in .ini are incorrect. There must be 2 profiles specified. Exiting"
		exitapp
	}
}

if (firstRun) {
	msgbox,0,% "RadeonClockEnforcer",% "FIRST RUN INFO:`n`nPlease read through README_RadeonClockEnforcer.txt,or else this program won't function correctly and may even harm your system.`n`nA template .ini configuration file has been created in the directory alongside this program. Go edit it to your liking before running this program again!"
	exitapp
}

if (startup = "True" || firstRun) {
	if (!FileExist(A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk")) {
		FileCreateShortcut,% A_ScriptDir "\RadeonClockEnforcer.exe",% A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk"
	}
} else {
	if (FileExist(A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk")) {
		FileRecycle,% A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\RadeonClockEnforcer.lnk"
	}
}

; ---

SplitPath,A_ScriptDir,,ODNTPath ; define up-one-folder from script as path to OverDriveNTool.exe

if (!FileExist(ODNTPath "\OverdriveNTool.exe")) {
	msgbox,% "Cannot locate """ ODNTPath "\OverdriveNTool.exe" """`n`nExiting"
	exitapp
}


; ---------------------------------------
; scan for, and if doesn't exist AND if 0rpm is disabled, create new prof intended to reinstate desired 0rpm state due to driver bug

FileRead,relevantFileContents,% ODNTPath "\OverDriveNTool.ini"
if (!InStr(relevantFileContents,"_0RPM_ON_DONTMODIFY")) {
	loop {
		IniRead,relevantFileContents,% ODNTPath "\OverDriveNTool.ini",% "Profile_" (A_Index - 1)
		if (relevantFileContents = "") {
			break
		}
		if (InStr(relevantFileContents,"Name=" prof_min) && InStr(relevantFileContents,"Fan_ZeroRPM=0")) {
			relevantFileContents := "[Profile_" (A_Index - 1) + 1 "]`n" . relevantFileContents
			relevantFileContents := StrReplace(relevantFileContents,prof_min,prof_min "_0RPM_ON_DONTMODIFY")
			relevantFileContents := StrReplace(relevantFileContents,"Fan_ZeroRPM=0","Fan_ZeroRPM=1")
			FileAppend,% relevantFileContents "`n`n",% ODNTPath "\OverDriveNTool.ini",UTF-16
			our0rpmProfExists := 1
		}
	}
} else {
	our0rpmProfExists := 1
}

prof_0rpm := prof_min . "_0RPM_ON_DONTMODIFY"

ApplyProfile(prof_0rpm)

sleep,750

ApplyProfile(prof_min)

; ---------------------------------------

; we will check for changes to ini contents periodically
FileRead,fileText_RCE1,% A_ScriptDir "\RadeonClockEnforcer.ini"
FileRead,fileText_ODNT1,% ODNTPath "\OverdriveNTool.ini"


; ---------------------------------------
; main loop

endLoopTimestamp := profileTimestamp := A_TickCount
profileNext	:= prof_min
profileCurrent := prof_min
maxTimer := 4000
minTimer := 2000
currentTimer := maxTimer
OnExit,ExitSub

loop {
	
	gosub,CheckProcessCount
	
	; check for changes to ini
	FileRead,fileText_RCE2,% A_ScriptDir "\RadeonClockEnforcer.ini"
	FileRead,fileText_ODNT2,% ODNTPath "\OverdriveNTool.ini"
	if (fileText_RCE1 != fileText_RCE2
	|| fileText_ODNT1 != fileText_ODNT2) {
		reload ; adapt changes
		exitapp
	}
	
	
	gosub,GetNextProfile
	
	if (profileNext = prof_min) {
		currentTimer := minTimer
	} else {
		currentTimer := maxTimer
	}
	
	
	; driver bug workaround: reinstate desired 0rpm mode if resuming from sleep/hibernate
	if (our0rpmProfExists = 1 && (A_TickCount - endLoopTimestamp) >= 5000) { ; flimsy method to detect if S3/S4 happened
		while (A_TickCount - profileTimestamp < minTimer) {
			sleep,200
		}
		
		ApplyProfile(prof_0rpm)
		sleep,750
		ApplyProfile(prof_min)
		soundplay,*-1
		profileTimestamp := A_TickCount
		sleep,750
	}
	
	
	; prevent rapid profile switching which could lead to gpu damage
	if (profileNext != profileCurrent) {
		while (A_TickCount - profileTimestamp < minTimer) {
			sleep,200
		}
		
		ApplyProfile(profileNext)
		
		profileTimestamp := A_TickCount
		profileCurrent := profileNext
	}
	
	endLoopTimestamp := A_TickCount
	
	sleep,% currentTimer
}



; ---------------------------------------------------
; funcs & subs

CheckProcessCount: ; make sure we aren't gonna stack processes, which could result in gpu harm
	; if you get this error when all seems well, it's likely from a residual ODNT .exe from recently applying a profile in the main loop...
	
	if (dontask = 1) {
		return
	}
	
	pidArr := []
	exename := ["RadeonClockEnforcer.exe", "OverDriveNTool.exe"]
	loop 2 {
		for process in ComObjGet("winmgmts:").ExecQuery("Select ProcessID from Win32_Process Where Name='" exename[A_Index] "'") {
			if (pidArr.Push(process.ProcessID) > 1) { ; check if arr ultimately has more than one elem / more than just this script's proc running
				msgbox,1,% "RadeonClockEnforcer",% "PAUSED: Too many RCE or ODNT processes running. Press OK to exit in order to avoid conflicts (recommended). Otherwise you will not be asked again until RCE restarts."
				ifmsgbox,Cancel
				{
					dontask := 1
				} else {
					exitapp
				}
			}
		}
	}
return


GetNextProfile:
	
	status_wl_proc := ProcessExistFromList(whitelistprocArr)
	status_bl_proc := ProcessExistFromList(blacklistprocArr)
	
	if (status_wl_proc) {
		if (status_bl_proc) {
			profileNext := prof_min
		} else {
			profileNext := prof_max
		}
	} else if (status_bl_proc) {
		profileNext := prof_min
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
					profileNext := prof_min
				} else {
					profileNext := prof_max
				}
			}
			if (forcefullscreen = "None") {
				if (status_wl_win) {
					if (status_bl_win) {
						profileNext := prof_min
					} else {
						profileNext := prof_max
					}
				}
			}
		} else {
			if (status_wl_win) {
				if (status_bl_win) {
					profileNext := prof_min
				} else {
					profileNext := prof_max
				}
			} else {
				profileNext := prof_min
			}
		}
	}
	
return

ApplyProfile(profile) {
	global prof_min, prof_max, prof_0rpm, ODNTPath
	
	ErrorLevel := 0
	runwait,% "OverdriveNTool.exe -p0" profile,% ODNTPath,UseErrorLevel
	if (ErrorLevel != 0) {
		msgbox,% "Error while calling """ ODNTPath "\OverdriveNTool.exe -p0" profile """`n`nWIN32 error code: " A_LastError "`n`nExiting"
		exitapp
	}
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


; ---------------------
; menu item subroutines

ViewCode:
	ListLines
return

ExitScript:
exitapp


; ---

ExitSub:
	if (profileCurrent = prof_max) {
		while (A_TickCount - profileTimestamp < 1000) {
			sleep,200
		}
		run,% "OverdriveNTool.exe -p0" prof_min,% ODNTPath,UseErrorLevel
		if (ErrorLevel != 0) {
			msgbox,% "ERROR DURING SCRIPT EXIT: Error while calling """ ODNTPath "\OverdriveNTool.exe -p0" prof_min """`n`nWIN32 error code: " A_LastError "`n`nCould not apply default profile. For now, you may need to manually apply a profile from within Radeon settings/WattMan or OverDriveNTool."
		}
	}
exitapp
