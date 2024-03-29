[中文說明](#mousehook-%E4%B8%AD%E6%96%87)

---

# MouseHook
A comprehensive and customizable MouseHook library for AutoHotkey v2.1-alpha.9 or later. 

Welcome to AutoHotkey-MouseHook, a comprehensive and customizable MouseHook library for **AutoHotkey v2.1-alpha.9 or later**. This library allows you to monitor and handle mouse events with ease and flexibility.

https://github.com/nperovic/MouseHook/assets/122501303/94f2c4f0-8dc0-4c18-b34f-34b29ac17720

## Features

- Monitor various mouse events including movement, button presses, and wheel scrolling.
- Customize the handling of each mouse event with your own callback functions.
- Control the hook with start and stop functions.
- Wait for specific sequences of mouse events with the `Wait` method.

## Usage

To use this library, simply include it in your AutoHotkey script with the `#include` directive. Then, create an instance of the `MouseHook` class and provide your callback function to handle mouse events.

Here is a basic example:

```js
#Requires AutoHotkey v2.1-alpha.9
#include <MouseHook>

mh := MouseHook("All", (eventObj, wParam, lParam){
    ToolTip eventObj.x " " eventObj.y 
})
mh.Start()
/* Wait for: LButton Down > LButton Up > RButton Down > RButton Up */
mh.Wait("LButton", "D", "LButton", unset, "RButton", "D", "RButton", unset)
mh.Stop()
```

See  for the real uasge of MouseHook.

Refer to [TaskbarReveal.ahk](example/TaskbarReveal.ahk) for the practical usage of MouseHook.

## Notes

This library requires [AutoHotkey v2.1-alpha.9](https://www.autohotkey.com/download/2.1) or later.  
Learn more about the ahk v2.1: [Click here](https://github.com/AutoHotkey/AutoHotkeyDocs/tree/alpha)

## License

This library is licensed under the MIT License. Please make sure to acknowledge this library as the source if you use it in your projects.

---

# MouseHook (中文)

歡迎來到 MouseHook，這是一個為 AutoHotkey v2.1-alpha.9 設計的全面且可自訂的 MouseHook 函式庫。這個函式庫讓您可以輕鬆且靈活地監控和處理滑鼠事件。

## 特點

- 監控各種滑鼠事件，包括移動、按鍵和滾輪滾動。
- 用您自己的回調函數自訂每個滑鼠事件的處理方式。
- 使用啟動和停止函數控制鉤子。
- 使用 `Wait` 函數等待特定的滑鼠事件序列。

## 使用方法

要使用這個函式庫，只需在您的 AutoHotkey 腳本中使用 `#include` 指令包含此函式庫檔案。然後，創建一個 `MouseHook` 類的實例，並提供您的回調函數來處理滑鼠事件。

範例：
```js
#Requires AutoHotkey v2.1-alpha.9
#include <MouseHook>

mh := MouseHook("All", (eventObj, wParam, lParam){
    ToolTip eventObj.x " " eventObj.y 
})
mh.Start()
/* Wait for: LButton Down > LButton Up > RButton Down > RButton Up */
mh.Wait("LButton", "D", "LButton", unset, "RButton", "D", "RButton", unset)
mh.Stop()
```

請參考 [TaskbarReveal.ahk](example/TaskbarReveal.ahk) 以瞭解 MouseHook 的實際用途。

## 注意事項

這個函式庫需要 [AutoHotkey v2.1-alpha.9](https://www.autohotkey.com/download/2.1) 或更高版本。  
AutoHotkey v2.1-alpha.9 官方文件: [立即查看](https://github.com/AutoHotkey/AutoHotkeyDocs/tree/alpha)

## 授權

此函式庫採用 MIT 授權。如果您在您的專案中使用此函式庫，請確保表彰此函式庫為來源。
