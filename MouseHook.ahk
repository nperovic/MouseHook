/************************************************************************
 * @description The MouseHook library is an advanced tool for AutoHotkey, designed to facilitate the monitoring and handling of mouse events in a customizable and efficient manner. Perfect for scripting and automation on Windows.  
 * MouseHook 函式庫是 AutoHotkey 的進階工具，旨在以可自訂且高效的方式促進滑鼠事件的監控與處理。非常適合在 Windows 上進行腳本編寫和自動化操作。
 * @file MouseHook.ahk
 * @link https://github.com/nperovic/MouseHook
 * @author Nikola Perovic
 * @date 2024/03/29
 * @version 1.0.0
 * @copyright  
 * This library is licensed under the MIT License. Please make sure to acknowledge this library as the source if you use it in your projects.
 * 此函式庫採用 MIT 授權。如果您在您的專案中使用此函式庫，請確保表彰此函式庫為來源。
 ***********************************************************************/

#Requires AutoHotkey v2.1-alpha.9

class POINT {
    x: i32, y: i32
}

class tagMSLLHOOKSTRUCT {
    pt         : POINT
    mouseData  : i32
    flags      : u32
    time       : u32
    dwExtraInfo: uptr
}

class MouseHook
{
    static Inst := 0

    /** @prop {Map} MsgList A list of actions and message codes. */
    MsgList := Map(
        512, "Move",
        513, "LButton Down",
        514, "LButton Up",
        516, "RButton Down",
        517, "RButton Up",
        519, "MButton Down",
        520, "MButton Up",
        522, "Wheel",
        523, "XButton{:d} Down",
        524, "XButton{:d} Up")

    /** @prop {integer} Hook SetWindowsHookEx */
    Hook := 0

    /** @prop {integer} Count Count how many times an action happens in a short time (`Interval`). */
    Count := 0

    /** @prop {string} ThisKeyTime The time when this key was pressed. */
    ThisKeyTime := 0

    /** @prop {Map} PriorKeyTime The Map logs the timestamps of when keys were previously pressed. (Keys are not included in the record until they are pressed for the first time.) */
    PriorKeyTime := Map()

    /** @prop {string} ThisKey This key. */
    ThisKey := ""

    /** @prop {string} Action The current action. */
    Action := ""

    /** @prop {tagMSLLHOOKSTRUCT} HookInfo Typed structure for tagMSLLHOOKSTRUCT. */
    HookInfo := ""

    /** @prop {integer} Interval The time between two actions (milliseconds). */
    Interval := 250

    /** @prop {integer} TimeSinceThisAct The time elapsed since this key was pressed. */
    TimeSinceThisAct => (this.ThisKeyTime ? (A_TickCount - this.ThisKeyTime) : 0)

    /**
     * @param {string} [action="All"] Move, LButton Up, RButton, etc. Default is All.
     * @param {(eventObj, wParam, lParam) => Integer} [callback] The callback function that will be called when an event is received.
     * @param {integer} [criticalOn=false] Critical On/ Off. If on, this parameter will be used in the `Critical` function as well.
     */
    __New(action := "All", callback := unset, criticalOn := 0)
    {
        this.OnEvent := callback ?? (*) => false
        this.cb      := CallbackCreate(LowLevelMouseProc, (criticalOn && criticalOn != "Off") ? "F" : unset, 3)
        this.keep    := false

        LowLevelMouseProc(nCode, wParam, lParam)
        {
            static CallNextHookEx := DllCall.Bind("CallNextHookEx", "Ptr", 0, "Int", unset, "UInt", unset, "UInt", unset)
            static StructOut      := StructFromPtr.Bind(tagMSLLHOOKSTRUCT)
            
            if criticalOn
                Critical(criticalOn)

            /** @var {tagMSLLHOOKSTRUCT} hookInfo */
            this.hookInfo := hookInfo := StructOut(lParam)
            
            switch wParam {
            case 522     : this.Action := (hookInfo.mouseData>>16 > 0 ? "WheelUp" : "WheelDown")
            case 523, 524: this.Action := Format(this.MsgList[wParam], hookInfo.mouseData >> 16)
            default      : this.Action := (this.MsgList.Has(wParam) ? this.MsgList[wParam] : "")
            }

            this.x := hookInfo.pt.x
            this.y := hookInfo.pt.y

            if (nCode < 0) || (action != "All" && !InStr(action, this.Action))
                return CallNextHookEx(nCode, wParam, lParam)

            if this.Action != "Move" && this.Action
            {
                isUp := false
                switch wParam {
                case 514, 517, 520, 524: isUp := true
                }

                if this.Action != this.ThisKey 
                    this.ThisKey := this.Action

                if !this.PriorKeyTime.Has(this.Action)
                    this.PriorKeyTime[this.Action] := {t: hookInfo.time, c: 0}

                pK               := this.PriorKeyTime[this.Action]
                this.Count       := pK.c += (hookInfo.time - pK.t < this.Interval) || -pK.c+1
                this.ThisKeyTime := pK.t := hookInfo.time
                
                if isUp || wParam == 522 
                    this.keep := false
                else {
                    this.keep := true
                    SetTimer((*) => (this.Hook && this.keep ? this.OnEvent(wParam, 0) : SetTimer(, 0)), 50)
                }
            }
            else if !this.keep {
                this.Count := 1
                this.keep  := this.ThisKey := this.ThisKeyTime := 0
            }

            return !!this.OnEvent(wParam, lParam) || CallNextHookEx(nCode, wParam, lParam)
        }
    }

    /** 
     * MouseHook starts.
     * @returns {void}
     * */
    Start()
    {
        if !this.Hook 
            this.Hook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", this.cb, "Ptr", DllCall("GetModuleHandle", "UInt", 0, "Ptr"), "UInt", 0, "Ptr")
    }

    /** 
     * MouseHook stops.
     * @returns {void} 
     * */
    Stop()
    {
        if this.Hook && DllCall("UnhookWindowsHookEx", "Ptr", this.Hook)
            this.Hook := 0
    }

    /**
     * Waits for keys or mouse/controller buttons to be released or pressed down.
     * @param {string} KeyName  
     * > This can be just about any single character from the keyboard or one of the key names from the key list, such as a mouse/controller button. Controller attributes other than buttons are not supported.  
     * 
     * > An explicit virtual key code such as `vkFF` may also be specified. This is useful in the rare case where a key has no name and produces no visible character when pressed. Its virtual key code can be determined by following the steps at the bottom of the [key list page](https://www.autohotkey.com/docs/v2/KeyList.htm#SpecialKeys).
     *
     * @param {string} [Options]  
     * > If blank or omitted, the function will wait **indefinitely** for the specified key or mouse/controller button to be physically released by the user.  
     *
     * > Specify a string of one or more of the following options (in any order, with optional spaces in between): 
     * > - `D`: Wait for the key to be pushed down.
     * > - `L`: Check the logical state of the key, which is the state that the OS and the active window believe the key to be in (not necessarily the same as the physical state). 
     * > - `T`: Timeout (e.g. `T3`). The number of seconds to wait before timing out and returning `0`. If the key or button achieves the specified state, the function will not wait for the timeout to expire. Instead, it will immediately return `1`. The timeout value can be a floating point number such as `2.5`, but it should not be a hexadecimal value such as `0x03`.
     *
     * @param {array} [MoreKeys] More keys to wait. As previous two parameters.  
     * @example
     * mh := MouseHook("All", (eventObj, wParam, lParam){
     *     ToolTip eventObj.x " " eventObj.y 
     * })
     * mh.Start()
     * ; Wait for: LButton Down > LButton Up > RButton Down > RButton Up 
     * mh.Wait("LButton", "D", "LButton", unset, "RButton", "D", "RButton", unset)
     * mh.Stop()
     * 
     * @returns {integer} This method returns `0` (`false`) if the function timed out or `1` (`true`) otherwise.
     */
    Wait(KeyName, Options?, MoreKeys*)
    {
        result := KeyWait(KeyName, Options?)
        if !MoreKeys.Length
            return result
        return this.Wait(MoreKeys.RemoveAt(1), MoreKeys.Length ? MoreKeys.RemoveAt(1) : unset, MoreKeys*) 
    }

    __Delete() => (this.cb && (this.Stop(), CallbackFree(this.cb), this.cb := 0))
}
