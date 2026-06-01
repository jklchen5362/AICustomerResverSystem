# Release Notes (版本發佈說明) — v1.2.0

歡迎閱讀 **「醫美隨身特助 (醫美智能客戶預約與管理系統)」** v1.2.0 的正式發佈說明。

本版本為系統帶來了重大升級，包括全新的**繁體中文臨床曜金「系統使用指南」**、**互動式角色權限表格**、**自動後端即時同步**、**Google 雲端硬碟試算表多帳戶與智慧篩選對接機制**，為高端醫美會所與奢華診所提供更穩健、精緻的操作體驗。

---

## 🌟 全新亮點與功能升級 (New Features)

### 1. 📖 曜金奢華手風琴互動式「系統使用指南」 (`UserGuideView.swift`)
*   **手風琴主題卡片**：將原本數萬字的繁體中文指南精緻打包為 9 大主題（含架構、核心功能、語音提醒、開發憑證配置及雲端對接），採用 SwiftUI 動態折疊 `VStack`，結合曜金調色與磨砂玻璃陰影。
*   **互動式 `RoleMatrixTable`**：為行動與平板裝置設計的**橫向滾動權限矩陣表**，直觀顯示四大角色對應之功能權限（如查看醫療過敏史、簽發發票、對接設定等），綠色勾號與紅色叉號一目了然。

### 2. 🌐 全方位 Google Sheets & Drive 深度備份還原
*   **自動帶有 yy_MM_dd 日期戳記的新建試算表**：點選新建時，自動擷取本機日期生成後綴，例如：`極致美學 CRM 雲端資料庫_26_06_01`，利於診所進行定期數據歸檔。
*   **智慧型 CRM 篩選器與 [CRM 匹配] 標籤**：雲端檔案瀏覽器新增 Segmented 選擇器，預設「✨ 匹配 CRM」功能僅列出名稱包含「極致美學、CRM」等相符的檔案，高亮標註金黃色的尊榮標籤。
*   **對接推薦下載還原機制**：當連結匹配的試算表時，自動提示建議下載以還原本地大盤資料。
*   **工作表自動補齊防呆 (`ensureWorksheetsExist`)**：連接現有試算表還原時，若發現雲端缺少任何一個標準分頁（`客戶資料`、`預約記錄`、`療程方案`、`財務發票`），同步引擎會自動在雲端補齊重建，防範 API range 400 錯誤。
*   **連結現有試算表 (貼上 URL / ID)**：新增快速文字對接功能，貼上網址或 ID 即可由正則解析器提取、進行 API 存取權限安全驗證，並動態顯示「雲端真實名稱」。
*   **「斷開/退出」安全退租**：更新退出按鈕為「斷開/退出」，點選後瞬間解除雲端鏡像並清空緩存，回歸獨立 Local-First 安全離線運作。

### 3. ⚡ 本機變更即時靜默同步 (Instant Auto Sync)
*   **實時資料監聽**：自動註冊對 SwiftData 核心 `ModelContext.didSave` 通知的全局監聽。
*   **3秒智慧防抖 (Debounce)**：前台編輯（例如連續鍵入電話、修改備註）時，系統會自動在背景延遲 3 秒執行靜默同步鏡像上傳，防止頻繁呼叫 Google API 導致的 rate-limit 拥堵與卡頓。

---

## 🛠️ 問題修復與底層優化 (Bug Fixes & Optimizations)

*   **智慧型 403 錯誤導引**：若 Google 雲端專案未啟用 Sheets / Drive API，API 回報 403 時會自動攔截並彈出內含 Trad-Chinese clickable 連結的藍色警告彈窗，一鍵導向對應的 Google Console 開啟 API 服務。
*   **Swift 6 Data-Race 安全併發編譯**：
    *   將語音播報服務的 `AVSpeechSynthesizerDelegate` 回呼標記為 `nonisolated`，並在 callback 內部使用 thread-safe `Task { @MainActor in ... }` 順序進行 singleton 狀態修改，完全解決 Swift 6 編譯下的併發數據競爭警告。
*   **CKAccountStatus 匹配完整性優化**：
    *   針對 iCloud 雲端同步 Diagnostics，完整處理了 iOS SDK 最新的 `.temporarilyUnavailable` 臨時維護狀態，搭配曜金 warning 徽章提示，保證高可用性與防崩潰。
*   **快捷客戶建檔 Picker 自動代入**：
    *   修復了前台新增療程或預約時新增客戶需頻繁跳轉的痛點，現在點選 Picker 下方的「快捷新增客戶資料 Quick Add Client」，儲存後自動將新客戶 auto-select 代入當前 Picker。

---

## 📝 提交變更日誌 (Git Commit History)
*   `5fee918` - Feature: Enhance in-app UserGuideView with a premium interactive scrollable RoleMatrixTable
*   `f9bc122` - Feature: Refactor in-app UserGuideView to display the ultra-detailed clinical guide in a luxurious golden Accordion view
*   `27f0d24` - Feature: Add yy_MM_dd date-stamp suffix to newly created sync spreadsheets in Google Drive
*   `5420f54` - Fix: Transition database save observer to native SwiftData ModelContext.didSave notification for real-time synchronization
*   `35b88f0` - Feature: Add Instant Sync toggle with intelligent debouncer on database save
*   `a66e1a0` - Feature: Add segmented picker and gold capsule badges for smart CRM spreadsheet matching, and auto-recommend download restoration

---

祝您使用愉快！如需進一步整合或調整，隨時聯絡管理同仁。
