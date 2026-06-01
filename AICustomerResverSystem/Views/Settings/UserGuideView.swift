//  UserGuideView.swift
//  AICustomerResverSystem
//

import SwiftUI
import SwiftData

struct UserGuideView: View {
    @State private var expandedSections: [String: Bool] = [
        "architecture": false,
        "views": false,
        "moreMenu": false,
        "tts": false,
        "quickAdd": false,
        "developer": false,
        "syncEngine": false,
        "roleMatrix": false,
        "faq": false
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header Hero
                VStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.bottom, 4)
                    
                    Text("醫美隨身特助 (CRM)")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.accent)
                        .fontWeight(.bold)
                    
                    Text("全方位操作與設定指南")
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
                
                Text("請點選下方各大主題卡片以展開閱讀詳細操作步驟：")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, 4)
                
                // 1. Architecture
                accordionCard(
                    id: "architecture",
                    icon: "info.circle.fill",
                    title: "📖 系統核心設計美學與技術架構",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        bulletRow(title: "曜金奢華視覺設計", content: "全局採用深藍基底搭配高質感磨砂玻璃卡片，各級 VIP 擁有獨立專屬調色徽章，儀表板與財務分析配有奢華配色的 Swift Charts 動態報表。")
                        bulletRow(title: "SwiftData 離線優先儲存", content: "在完全沒有網路的無訊號雷射治療室，本機的所有客戶資料、預約排程與核銷扣堂也都能以微秒級速度瞬時寫入與儲存，保證絕不卡頓。")
                        bulletRow(title: "熱插拔雙雲架構", content: "提供 iCloud 私有雲與 Google Sheets 試算表之雙重即時備份，並支援在「離線本機」、「iCloud 雲端」、「Google 試算表」以及「雙重同步」四種模式間隨時熱插拔無縫切換，保證診所數據安全無虞。")
                    }
                }
                
                // 2. Core Views Guide
                accordionCard(
                    id: "views",
                    icon: "square.grid.2x2.fill",
                    title: "🌟 五大核心分頁深度操作指南",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        sectionTitle("① 數據儀表板 (DashboardView)")
                        bulletRow(title: "大盤指標卡", content: "實時顯示「客戶總數」（點擊可直接彈窗查看該分店的客戶列表、其賸餘療程堂數與下次預約時間）、「已售療程包」、「賸餘未核銷堂數」與「今日預約堂數」。")
                        bulletRow(title: "營收統計與今日預約", content: "採用 Swift Charts 呈現近 6 個月營業額柱狀圖。今日預約動態列表按時間軸先後排序，顯示預約時段、項目及狀態標籤（已確認、已到店、已結案等）。")
                        bulletRow(title: "編輯顧問與分店", content: "點擊頂部 Welcome 曜金卡片右側的「編輯」，可修改當前登入的「顧問姓名」、「Email」以及切換「執勤分店」，數據與名單即刻 scoped 重新加載。")
                        
                        Divider().padding(.vertical, 2)
                        
                        sectionTitle("② 客戶管理履歷 (CustomerListView)")
                        bulletRow(title: "模糊搜尋與 VIP 篩選", content: "支援按姓名、電話模糊查詢，並可使用 VIP 等級篩選晶片（鑽石、白金、黃金、白銀、青銅、一般）。")
                        bulletRow(title: "醫療安全履歷檔案", content: "特設「醫療安全檔案」記錄重要過敏史（高亮呈現，防範雷射術前麻藥過敏）膚質分類與諮詢病史。")
                        bulletRow(title: "五合一分頁卡", content: "在客戶詳情頁中，一鍵切換查看該客戶的基本資料、醫療資訊、療程方案、預約記錄與發票明細。")
                        
                        Divider().padding(.vertical, 2)
                        
                        sectionTitle("③ 預約排班引擎 (AppointmentCalendarView)")
                        bulletRow(title: "三維排班引擎", content: "支援日 (時段網格區間表)、週 (Traditional Chinese 橫卡流)、月 (日曆彩點網格) 三維切換。彩點顏色對應不同的預約狀態。")
                        bulletRow(title: "狀態即時轉換", content: "在日視圖中點選預約卡片，一鍵轉換為「已到店」或「已結案」，即時同步後台美容師。")
                        
                        Divider().padding(.vertical, 2)
                        
                        sectionTitle("④ AI 智能助理 (AIAssistantView)")
                        bulletRow(title: "離線語意助理", content: "輸入如「查詢 0922-111-222」、「林雅琪」、「今日預約」、「營收業績」等，AI 會秒級解析 SwiftData 庫並給予結構化回覆。")
                        bulletRow(title: "續購預警警報", content: "輸入「剩餘堂數」，AI 自動篩選出全店賸餘堂數 <= 2 堂的客戶名單與電話，助您引導續購銷售。")
                    }
                }
                
                // 3. More Menu Extensions
                accordionCard(
                    id: "moreMenu",
                    icon: "folder.badge.gearshape",
                    title: "💼 延伸功能與深度擴充指南 (More Menu)",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        bulletRow(title: "療程合約方案", content: "直觀顯示已消耗堂數與賸餘堂數百分比。當賸餘堂數低於 30% 時，進度條自動轉化為黃金警戒色，提醒現場同仁進行續購推廣。")
                        bulletRow(title: "消費扣堂與手寫簽名", content: "扣堂時支援美容師核章、上傳術前術後照片。特設電容手寫簽名板，客戶可直接在螢幕上進行電子手寫簽名確認，保留核銷法律依據。")
                        bulletRow(title: "連鎖多分店管理", content: "管理各大店點的地址、電話、负责人，自動匯總該分店的「有效合約包總數」與「今日預約飽和度」。")
                        bulletRow(title: "財務統計與客單價", content: "自動計篩營業額、客單價、交易筆數。動態生成 Cash、Credit Card、LINE Pay、Apple Pay 分期等渠道佔比餅圖。")
                        bulletRow(title: "A4 PDF 報告匯出", content: "在「報表中心」中，一鍵生成 A4 列印標準的客戶與財務 PDF，並拉起 iOS 系統分享面板，支持 AirDrop、AirPrint 一鍵列印紙本。")
                    }
                }
                
                // 4. TTS Engine
                accordionCard(
                    id: "tts",
                    icon: "speaker.wave.2.bubble.left.fill",
                    title: "🔊 專屬 AI 曜金語音提醒 (Speech TTS Engine)",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        bulletRow(title: "客製化提醒內容", content: "新增/編輯預約排程時，可設定「語音提醒」之內容與前置時間（如前 1 小時、2 小時或 24 小時）。")
                        bulletRow(title: "曜金美學音質", content: "語音採用台灣腔國語（zh-TW），將語速調至溫和優雅的 0.48，音高上調至輕柔溫暖的 1.1，帶來 clinical luxury 會所的典雅發音氛圍。")
                        bulletRow(title: "語音試聽與防漏單", content: "表單中提供「朗讀試聽」按鈕。當提醒通知到達、App 在前台運行，或是用戶在通知中心點選通知卡片時，系統會柔聲唸讀預約，完美防漏單。")
                    }
                }
                
                // 5. Quick Add Client
                accordionCard(
                    id: "quickAdd",
                    icon: "person.badge.plus.fill",
                    title: "⚡ 快捷客戶建檔與 picker 自動連動",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        bulletRow(title: "免頁面跳轉入口", content: "在「新增預約」或「購買新療程」頁面時，點選「快捷新增客戶資料 Quick Add Client」彈窗。")
                        bulletRow(title: "快速建檔", content: "在彈窗中輸入新客戶核心資料（姓名、電話、性別、VIP等級、過敏史、膚質）點擊儲存。")
                        bulletRow(title: "極致Picker自動連動", content: "點擊儲存後，新客戶將寫入 SwiftData，並「自動 auto-select」代入當前表單的客戶選擇器中，給您極致絲滑的無縫操作。")
                    }
                }
                
                // 6. Developer Console Setup
                accordionCard(
                    id: "developer",
                    icon: "wrench.and.screwdriver.fill",
                    title: "🛠️ Google Cloud Developer Console 專案整合指南",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        stepRow(number: "1", title: "建立專案與啟用 API", content: "登入 Google Cloud Console 新建專案。在庫 (Library) 中搜尋並啟用 「Google Sheets API」 與 「Google Drive API」。")
                        stepRow(number: "2", title: "設定 OAuth 同意畫面 (Consent Screen)", content: "用戶類型選擇「外部 (External)」。設定 scopes 權限新增 `auth.spreadsheets` 與 `auth.drive.readonly`。在「測試使用者」中必須手動添加您要登入同步的 Google 帳號。")
                        stepRow(number: "3", title: "建立 iOS 憑證與 Bundle ID", content: "在「憑證」中點擊建立「OAuth 用戶端 ID」，類型選擇「iOS」。套件識別碼 (Bundle ID) 必須精確輸入本應用的軟體包 ID：Jeff.AICustomerResverSystem (設定畫面中提供一鍵複製按鈕)。")
                        stepRow(number: "4", title: "獲取 Client ID 並貼入 App", content: "複製產生的 Client ID (格式如 xxxx.apps.googleusercontent.com)，在 App 內「配置 Google OAuth 密鑰」粘貼儲存，即可順利新增帳戶。")
                    }
                }
                
                // 7. Cloud Sync & Restore
                accordionCard(
                    id: "syncEngine",
                    icon: "arrow.trianglehead.2.counterclockwise.rotate.90.icloud.fill",
                    title: "🌐 全方位雲端同步對接與還原指南 (Google Sheets)",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        bulletRow(title: "多帳戶 Keychain 安全管理", content: "授權 Token 皆使用 iOS 原生安全 Keychain 加密儲存。設定頁面支援多個 Google 帳戶的熱切換與一鍵登出。")
                        bulletRow(title: "新建對接試算表與 yy_MM_dd 日期戳記", content: "點選新建，系統會自動在您的 Google Drive 根目錄建立全新且帶有日期戳記的工作簿，例如：極致美學 CRM 雲端資料庫_26_06_01，並自動初始化四個標準 worksheets (客戶資料、預約記錄、療程方案、財務發票)。")
                        bulletRow(title: "搜尋與篩選 (Segment Filter Browser)", content: "Drive 瀏覽器頂部設有 segmented 篩選 Picker。預設「✨ 匹配 CRM」僅列出名稱包含極致美學、CRM 等符合模式的試算表，高亮標註金黃色的 [CRM 匹配] 尊榮標籤。支援 .searchable 即時關鍵字搜尋。")
                        bulletRow(title: "輸入網址或 ID 對接 (Connect Existing via URL/ID)", content: "點選輸入，貼上瀏覽器網址列整行網址，系統會自動解析提取 ID，向 Google API 驗證存取權限並動態抓取其「雲端真實名稱」，防錯防漏。")
                        bulletRow(title: "工作表自動補齊防呆與還原合併", content: "點選「下載並還原」會啟動 ensureWorksheetsExist。如果該試算表中缺失任何標準工作表，引擎會在拉取前自動重新補齊建立，防範 API range 400 錯誤。拉回的資料會智慧 Upsert 合併，防重複。")
                        bulletRow(title: "本機變更即時智慧防抖同步 (Instant Auto Sync)", content: "啟用後，監聽 ModelContext.didSave 儲存通知。配合智慧型防抖 (Debounce) 機制，當您在前台連續快速輸入時，會自動延遲 3 秒在背景靜默完成同步鏡像，防止頻繁呼叫 Google API 拥堵。")
                        bulletRow(title: "自動定時背景同步與斷開退出", content: "同步時間間隔支援從 1 分鐘至 3600 分鐘的 Stepper 自訂，背景定時器靜默鏡像。點擊「斷開/退出」膠囊按鈕，即可瞬間安全退出當前試算表對接，回歸本機完全離線狀態。")
                    }
                }
                
                // 8. Role Matrix
                accordionCard(
                    id: "roleMatrix",
                    icon: "lock.shield.fill",
                    title: "🔐 角色權限安全管控矩陣 (UserRole & Permissions)",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("系統內置了完善的角色權限管控，保護核心業務與客戶隱私：")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        Divider().padding(.vertical, 2)
                        
                        roleRow(role: "👑 管理員 (Admin)", desc: "擁有最高權限。可管理分店、自訂 TTS、簽發療程發票、核銷扣堂、查看總財務報表與匯出 PDF、變更員工角色與進行雲端同步設定。")
                        roleRow(role: "💼 諮詢師 (Consultant)", desc: "可查看與編輯客戶檔案、建立預約排程、自訂曜金語音提醒、簽發療程包與財務發票、執行消費核銷。")
                        roleRow(role: "💅 美容師 (Beautician)", desc: "可查看客戶基本資料與醫療史、查看今日班表，並執行核銷扣堂、上傳對比照片與顧客手寫簽名。")
                        roleRow(role: "📞 接待人員 (Receptionist)", desc: "可進行快速客戶建檔、預約建立、自訂語音提醒及到店狀態變更。")
                    }
                }
                
                // 9. FAQ
                accordionCard(
                    id: "faq",
                    icon: "questionmark.circle.fill",
                    title: "❓ 常見問答集 (FAQ) 與疑難排解",
                    color: AppTheme.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        faqRow(
                            q: "Q1：登入 Google 時彈出「未通過 Google 驗證 (App Not Verified)」？",
                            a: "答：這是正常現象。因為專案處於測試階段（Testing）。您只需點選「進階設定 (Advanced)」，然後點選「轉至醫美隨身特助 (Go to App)」即可。請務必確認您的 Google 帳戶已被加入為「測試使用者」。"
                        )
                        
                        faqRow(
                            q: "Q2：同步或下載資料時，跳出 403 錯誤，並提示 clickable 的 Google Console 連結？",
                            a: "答：此為您的 Google 專案尚未啟用 Google Sheets / Drive API 服務。App 內置了智慧型 403 攔截器，請直接點選警告中的 Trad-Chinese 藍色 clickable 連結，系統會引導您到對應的 API 頁面，點選「啟用 (Enable)」後返回即可。"
                        )
                        
                        faqRow(
                            q: "Q3：同步時回報 400 錯誤，提示 range 不符合？",
                            a: "答：這代表您在 Google 試算表網頁端手動刪除或更改了工作表分頁的名稱。請勿手動更改名稱。您只需在 App 中點擊「📥 從雲端下載並還原」，我們的分頁自動補齊安全機制會在拉取前自動重建標準分頁，即可瞬間排除 400 錯誤。"
                        )
                        
                        faqRow(
                            q: "Q4：開啟「即時同步」後，會不會造成手機耗電或網路卡頓？",
                            a: "答：完全不會。即時同步內置了高度優化的「智慧型防抖 (Debounce)」機制。當您在前台連續輸入時，所有的儲存通知都會被自動攔截並重置計時器，只有在您停止編輯整整 3 秒鐘之後，App 才會在背景默默發起一次輕量級上傳，且完全不佔用前台渲染 CPU 資源，極致流暢。"
                        )
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("系統使用指南")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Accordion Subview Helpers
    
    private func accordionCard<Content: View>(
        id: String,
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isExpanded = expandedSections[id] ?? false
        
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(AppTheme.Animations.smooth) {
                    expandedSections[id] = !isExpanded
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 28, height: 28)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Divider()
                
                content()
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.background.opacity(0.4))
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(isExpanded ? AppTheme.Colors.accent.opacity(0.3) : Color.gray.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isExpanded ? AppTheme.Colors.accent.opacity(0.04) : .black.opacity(0.015), radius: 5, x: 0, y: 2)
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.Typography.body)
            .fontWeight(.bold)
            .foregroundStyle(AppTheme.Colors.accent)
            .padding(.bottom, 2)
    }
    
    private func bulletRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.accent)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Text(content)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(3.5)
                .padding(.leading, 12)
        }
    }
    
    private func stepRow(number: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(AppTheme.Colors.accent)
                .clipShape(Circle())
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(content)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineSpacing(3.5)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func roleRow(role: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(role)
                .font(AppTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.primary)
            
            Text(desc)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(3.5)
                .padding(.leading, 4)
        }
        .padding(.vertical, 2)
    }
    
    private func faqRow(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(q)
                .font(AppTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.accent)
            
            Text(a)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(3.5)
                .padding(.leading, 4)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        UserGuideView()
    }
}
