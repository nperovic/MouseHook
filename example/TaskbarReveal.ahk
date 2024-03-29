/************************************************************************
 * @description This AutoHotkey script allows users to reveal the taskbar in full-screen mode by simply moving the mouse cursor to the bottom of the screen. Utilizing the [MOUSEHOOK] library, it offers a seamless way to access the taskbar without disrupting the full-screen experience.
 * @file TaskbarReveal.ahk
 * @link https://github.com/nperovic/MouseHook
 * @author Nikola Perovic
 * @date 2024/03/29
 * @version 1.0.0
 ***********************************************************************/

#requires AutoHotkey v2.1-alpha.9
#SingleInstance
#Include <MouseHook>

Persistent()

class MONITORINFO  {
    cbSize   : i32 := ObjGetDataSize(this)
    rcMonitor: RECT
    rcWork   : RECT
    dwFlags  : i32
}

; Adding those windows related to the taskbar (or the system).
for title in ["ahk_class Shell_TrayWnd", "ahk_class Shell_SecondaryTrayWnd", "ahk_class TaskListThumbnailWnd ahk_exe explorer.exe", "ahk_class Xaml_WindowedPopupClass ahk_exe explorer.exe", "ahk_exe SearchHost.exe", "ahk_exe StartMenuExperienceHost.exe"]
	GroupAdd("SysWnd", title)


MHook := MouseHook("All", TaskbarReveal)
MHook.Start()


/**
 *  The callback function for `MouseHook`.
 */
TaskbarReveal(event, *)
{
	SetTimer(ShowTaskbar, -20)

	ShowTaskbar()
	{
		static taskbr        := WinExist("ahk_class Shell_TrayWnd")
		static fullScreenWnd := 0
		static pt            := 0
		static taskbrVisible := 0
		
		SetWinDelay(-1)
		mWin := WinUnderMouse(event.hookInfo.pt)
		
		if ((event.y+3 < A_ScreenHeight) || (mWin = taskbr)) {
			if taskbrVisible && WinActive("ahk_group SysWnd ahk_id" mWin) || WinExist("ahk_group SysWnd ahk_id" WinUnderMouse(event.hookInfo.pt))
				return SetTimer(HideTaskbar, -1500)
			else return taskbrVisible := 0
		}

		try {
			WinGetPos(&x, &y, &w, &h, fullScreenWnd := GetForegroundWindow())
			if ((x >= 2) || (y >= 2) || (w+2 <= A_ScreenWidth) || (h+2 <= A_ScreenHeight))
				throw
		} catch 
			return fullScreenWnd := taskbrVisible := 0

		SetWindowPos(fullScreenWnd, 0,,,,, 0x10 | 0x4 | 0x1 | 0x20)
		MarkFullscreenWindow(fullScreenWnd, 0)
		SetTimer(HideTaskbar, -1500)
		taskbrVisible := true

		HideTaskbar()
		{
			if WinExist("ahk_group SysWnd ahk_id" WinUnderMouse(event.hookInfo.pt))
				return SetTimer(HideTaskbar, -1500)

			taskbrVisible := false

			if !pt {
				pt   := Point()
				pt.x := (A_ScreenWidth // 2)
				pt.y := A_ScreenHeight-2
			}

			if (taskbr = WinUnderMouse(pt)) {
				if fullScreenWnd {
					SetWindowPos(fullScreenWnd, 0,,,,, 0x40 | 0x4 | 0x1 | 0x20)
					MarkFullscreenWindow(fullScreenWnd, 1)
					fullScreenWnd := 0
				} 
			}
		}
	}

	static SetWindowPos(hWnd, hWndInsertAfter, X := 0, Y := 0, cx := 0, cy := 0, uFlags := 0x40) => DllCall("User32\SetWindowPos", "ptr", hWnd, "ptr", hWndInsertAfter, "int", X, "int", Y, "int", cx, "int", cy, "uint", uFlags, "int")

	static GetAncestor(hwnd, gaFlags) => DllCall("User32\GetAncestor", "ptr", hwnd, "uint", gaFlags, "ptr")

	static WinUnderMouse(pt) => (CoordMode("Mouse"), GetAncestor(WindowFromPoint(pt), 2))

	static WindowFromPoint(pt) => DllCall("User32\WindowFromPoint", (IsObject(pt) ? [Point, pt, "uptr"] : ["uint64", pt, "ptr"])*)

	static GetForegroundWindow() => DllCall("User32\GetForegroundWindow", "ptr")

	static MarkFullscreenWindow(hWnd := WinExist("A"), fFullscreen := 0)
	{
		static IID_ITaskbarList  := "{56FDF342-FD6D-11d0-958A-006097C9A090}"
		static CLSID_TaskbarList := "{56FDF344-FD6D-11d0-958A-006097C9A090}"
		
		if ComCall(3, tbl := ComObject(CLSID_TaskbarList, IID_ITaskbarList))
			return

		/** @type {ITaskbarList2} */
		tbl2 := ComObjQuery(tbl, "{602D4995-B13A-429B-A66E-1935E44F4317}")
		ComCall(8, tbl2, "ptr", hWnd, "int", fFullscreen)
	}
}
