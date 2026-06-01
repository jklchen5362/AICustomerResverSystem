//
//  GoogleSheetsSettingsView.swift
//  AICustomerResverSystem
//

import SwiftUI
import SwiftData

struct GoogleSheetsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    private let authService = GoogleAuthService.shared
    private let sheetsService = GoogleSheetsService.shared
    private let syncEngine = GoogleSheetsSyncEngine.shared
    
    // UI state
    @State private var isSyncing = false
    @State private var isDownloading = false
    @State private var isFetchingFiles = false
    @State private var driveFiles: [GoogleDriveFile] = []
    @State private var showFileBrowser = false
    @State private var clientIDInput = ""
    @State private var showClientIDSheet = false
    
    // Connect Existing Spreadsheet by URL/ID
    @State private var showConnectExistingSheet = false
    @State private var inputSpreadsheetURLOrID = ""
    
    // Switch Connection Choices
    @State private var showConnectionChoiceAlert = false
    @State private var selectedFileForChoice: GoogleDriveFile? = nil
    
    // Alerts
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var syncSuccess = false
    
    var body: some View {
        List {
            // Connection Status Header Card
            Section {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(authService.isAuthorized ? AppTheme.Colors.success.opacity(0.12) : AppTheme.Colors.textSecondary.opacity(0.12))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "tablecells.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(authService.isAuthorized ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.isAuthorized ? "Google 試算表已連線" : "Google 服務尚未啟用")
                            .font(AppTheme.Typography.body)
                            .fontWeight(.bold)
                        
                        if authService.isAuthorized {
                            Text("作用帳戶：\(authService.activeEmail)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            
                            if !appState.googleSpreadsheetName.isEmpty {
                                Text("連接檔案：\(appState.googleSpreadsheetName)")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundStyle(AppTheme.Colors.accent)
                                    .fontWeight(.semibold)
                            } else {
                                Text("尚未連結雲端試算表檔案")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundStyle(AppTheme.Colors.warning)
                            }
                        } else {
                            Text("請先登入 Google 帳號以啟用同步")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.white)
            
            // Account Management Section
            Section("Google 帳戶管理 (Multi-Account)") {
                if authService.registeredAccounts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("目前沒有已登錄的 Google 帳戶")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, AppTheme.Spacing.sm)
                        Spacer()
                    }
                } else {
                    ForEach(authService.registeredAccounts, id: \.self) { email in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(email)
                                    .font(AppTheme.Typography.callout)
                                    .fontWeight(.medium)
                                
                                if let creds = KeychainHelper.shared.readCredentials(email: email) {
                                    Text(creds.displayName)
                                        .font(AppTheme.Typography.caption2)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if authService.activeEmail == email {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.success)
                            } else {
                                Button("切換") {
                                    authService.activeEmail = email
                                }
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.accent)
                                .buttonStyle(.bordered)
                            }
                            
                            Button(role: .destructive) {
                                authService.signOut(email: email)
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.Colors.danger)
                            }
                            .padding(.leading, 8)
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Button {
                    signIn()
                } label: {
                    Label("➕ 新增 Google 帳戶 (Add Account)", systemImage: "person.badge.plus")
                        .font(AppTheme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            
            // Spreadsheet Connection Section
            if authService.isAuthorized {
                Section("雲端試算表對接設定 (Google Spreadsheet)") {
                    Button {
                        createNewSpreadsheet()
                    } label: {
                        Label("在 Google Drive 建立全新對接試算表", systemImage: "plus.app.fill")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                    
                    Button {
                        browseSpreadsheets()
                    } label: {
                        Label("瀏覽並連接雲端硬碟現有試算表", systemImage: "folder.fill")
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    
                    Button {
                        showConnectExistingSheet = true
                    } label: {
                        Label("輸入試算表網址或 ID 連接 (Connect Existing)", systemImage: "link")
                            .foregroundStyle(AppTheme.Colors.info)
                    }
                }
            }
            
            // Synchronization Status
            if authService.isAuthorized && !appState.googleSpreadsheetID.isEmpty {
                Section("資料對接同步與還原 (Sync & Restore)") {
                    HStack {
                        Text("當前連接 ID")
                        Spacer()
                        Text(appState.googleSpreadsheetID.prefix(12) + "..." + appState.googleSpreadsheetID.suffix(8))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        Button {
                            appState.googleSpreadsheetID = ""
                            appState.googleSpreadsheetName = ""
                        } label: {
                            Text("斷開/退出")
                                .font(AppTheme.Typography.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.Colors.danger)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.danger.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack {
                        Text("上次同步時間")
                        Spacer()
                        if appState.googleLastSyncTime > 0 {
                            let date = Date(timeIntervalSince1970: appState.googleLastSyncTime)
                            Text(date.formattedShortDate + " " + date.formattedTime)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        } else {
                            Text("從未同步")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.warning)
                        }
                    }
                    
                    Button {
                        triggerSync()
                    } label: {
                        HStack {
                            Label("📤 上傳本機資料至雲端 (Upload & Overwrite)", systemImage: "arrow.up.doc.fill")
                            Spacer()
                            if isSyncing {
                                ProgressView()
                                    .tint(AppTheme.Colors.accent)
                            }
                        }
                    }
                    .disabled(isSyncing || isDownloading)
                    .foregroundStyle(AppTheme.Colors.primary)
                    
                    Button {
                        triggerDownload()
                    } label: {
                        HStack {
                            Label("📥 從雲端下載並還原 (Download & Restore)", systemImage: "arrow.down.doc.fill")
                            Spacer()
                            if isDownloading {
                                ProgressView()
                                    .tint(AppTheme.Colors.warning)
                            }
                        }
                    }
                    .disabled(isSyncing || isDownloading)
                    .foregroundStyle(AppTheme.Colors.warning)
                }
            }
            
            if authService.isAuthorized && !appState.googleSpreadsheetID.isEmpty {
                Section("即時自動同步設定 (Instant Auto Sync)") {
                    Toggle(isOn: Bindable(appState).googleInstantSyncEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("啟用本機變更即時同步")
                                .font(AppTheme.Typography.body)
                                .fontWeight(.medium)
                            Text("偵測到本機資料變更時，立即自動鏡像上傳至雲端")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .tint(AppTheme.Colors.accent)
                    
                    if appState.googleInstantSyncEnabled {
                        Text("💡 系統已啟用即時智慧防抖技術 (Debounce)，在您連續編輯資料時，會自動延遲 3 秒在背景靜默完成同步，以防頻繁呼叫 Google API 造成擁堵。")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                            .lineSpacing(2)
                    }
                }
                
                Section("自動背景同步設定 (Scheduled Auto Sync)") {
                    Toggle(isOn: Bindable(appState).googleAutoSyncEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("啟用定時自動背景同步")
                                .font(AppTheme.Typography.body)
                                .fontWeight(.medium)
                            Text("系統在背景偵測到間隔時間後自動進行鏡像對接")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .tint(AppTheme.Colors.accent)
                    
                    if appState.googleAutoSyncEnabled {
                        HStack {
                            Text("同步時間間隔")
                                .font(AppTheme.Typography.body)
                            Spacer()
                            
                            Stepper(value: Bindable(appState).googleSyncIntervalMinutes, in: 1...3600) {
                                Text("\(appState.googleSyncIntervalMinutes) 分鐘")
                                    .font(AppTheme.Typography.body)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }
                            .frame(width: 170)
                        }
                        
                        Text("時間間隔支援 1 分鐘至 3600 分鐘 (60 小時) 的自訂區間配置。")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
            
            // Advanced Settings (Client ID configuration)
            Section("進階設定 (Developer Options)") {
                Button {
                    clientIDInput = authService.clientID
                    showClientIDSheet = true
                } label: {
                    HStack {
                        Label("配置 Google OAuth 密鑰 (Client ID)", systemImage: "key.fill")
                        Spacer()
                        Text(authService.clientID.prefix(12) + "...")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .foregroundStyle(AppTheme.Colors.primary)
                
                HStack {
                    Label("軟體包 ID (Bundle ID)", systemImage: "app.badge.checkmark.fill")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Jeff.AICustomerResverSystem")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Button {
                        UIPasteboard.general.string = Bundle.main.bundleIdentifier ?? "Jeff.AICustomerResverSystem"
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(AppTheme.Colors.primary)
            }
        }
        .navigationTitle("Google 試算表同步")
        .listStyle(.insetGrouped)
        .background(AppTheme.Colors.background)
        .sheet(isPresented: $showFileBrowser) {
            GoogleDriveFileBrowser(
                files: driveFiles,
                isFetching: isFetchingFiles,
                onSelect: { file in
                    selectedFileForChoice = file
                    showFileBrowser = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showConnectionChoiceAlert = true
                    }
                },
                onCancel: { showFileBrowser = false }
            )
        }
        .sheet(isPresented: $showConnectExistingSheet) {
            ConnectExistingSheetView(
                urlOrIDInput: $inputSpreadsheetURLOrID,
                onConnect: { id, title in
                    let file = GoogleDriveFile(id: id, name: title, mimeType: "application/vnd.google-apps.spreadsheet")
                    selectedFileForChoice = file
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showConnectionChoiceAlert = true
                    }
                }
            )
        }
        .sheet(isPresented: $showClientIDSheet) {
            NavigationStack {
                Form {
                    Section("配置 Google OAuth Client ID") {
                        Text("請輸入您在 Google Cloud Console 中建立的 iOS OAuth 2.0 用戶端 ID：")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        TextField("請輸入 Client ID", text: $clientIDInput)
                            .font(.system(size: 12, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    Section("您的軟體包 ID (Bundle ID)") {
                        HStack {
                            Text(Bundle.main.bundleIdentifier ?? "Jeff.AICustomerResverSystem")
                                .font(.system(size: 13, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.primary)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = Bundle.main.bundleIdentifier ?? "Jeff.AICustomerResverSystem"
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("在 Google Cloud Console 建立憑證時，必須提供此軟體包 ID (Bundle ID)。")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    
                    Section("如何取得密鑰？") {
                        Text("1. 開啟 Google Cloud Console 建立專案。\n2. 啟用 Google Drive API 與 Google Sheets API。\n3. 在「憑證」中建立「iOS 用戶端 ID」，輸入 Bundle ID，取得 Client ID。\n4. 將其複製貼上於上方欄位即可開始使用。")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineSpacing(4)
                    }
                }
                .navigationTitle("Google OAuth 設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") { showClientIDSheet = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("儲存") {
                            authService.setClientID(clientIDInput)
                            authService.refreshActiveState()
                            showClientIDSheet = false
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert(selectedFileForChoice?.isCRMMatched == true ? "已連接已匹配的 CRM 試算表" : "已連接試算表", isPresented: $showConnectionChoiceAlert, presenting: selectedFileForChoice) { file in
            Button("📥 (推薦) 下載並還原雲端資料", role: .none) {
                appState.googleSpreadsheetID = file.id
                appState.googleSpreadsheetName = file.name
                triggerDownload()
            }
            Button("📤 上傳本機資料至雲端", role: .none) {
                appState.googleSpreadsheetID = file.id
                appState.googleSpreadsheetName = file.name
                triggerSync()
            }
            Button("僅連接暫不同步", role: .cancel) {
                appState.googleSpreadsheetID = file.id
                appState.googleSpreadsheetName = file.name
            }
        } message: { file in
            if file.isCRMMatched {
                Text("您已成功連接與本 App 匹配的 CRM 試算表「\(file.name)」。\n\n💡 建議：如果您是在新裝置上安裝 App，請點擊下方「下載並還原雲端資料」拉回所有客戶與預約記錄。如果是要把本機最新變更上傳，請選擇「上傳本機資料至雲端」。")
            } else {
                Text("您已成功連接試算表「\(file.name)」。\n\n請選擇您接下來要執行的同步動作：")
            }
        }
    }
    
    // MARK: - Actions
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn()
                alertTitle = "登入成功"
                alertMessage = "成功登入帳號：\(authService.activeEmail)"
                showAlert = true
            } catch {
                alertTitle = "登入失敗"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func createNewSpreadsheet() {
        isSyncing = true
        Task {
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "yy_MM_dd"
                let dateStr = formatter.string(from: Date())
                let sheetTitle = "極致美學 CRM 雲端資料庫_\(dateStr)"
                
                let file = try await sheetsService.createNewSpreadsheet(title: sheetTitle)
                appState.googleSpreadsheetID = file.id
                appState.googleSpreadsheetName = file.name
                isSyncing = false
                alertTitle = "新建成功"
                alertMessage = "成功在您的 Google 雲端硬碟根目錄建立了全新試算表「\(file.name)」！正在為您同步初始化數據..."
                showAlert = true
                
                // Immediately perform initial sync
                triggerSync()
            } catch {
                isSyncing = false
                alertTitle = "建立失敗"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func browseSpreadsheets() {
        isFetchingFiles = true
        showFileBrowser = true
        
        Task {
            do {
                let files = try await sheetsService.fetchSpreadsheets()
                driveFiles = files
                isFetchingFiles = false
            } catch {
                isFetchingFiles = false
                showFileBrowser = false
                alertTitle = "無法讀取雲端檔案"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func triggerSync() {
        isSyncing = true
        Task {
            do {
                try await syncEngine.syncAllData(context: modelContext, spreadsheetID: appState.googleSpreadsheetID)
                isSyncing = false
                appState.googleLastSyncTime = Date().timeIntervalSince1970
                alertTitle = "同步成功"
                alertMessage = "CRM 本機資料已成功完整上傳並鏡像至您的 Google 試算表！"
                showAlert = true
            } catch {
                isSyncing = false
                alertTitle = "同步失敗"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func triggerDownload() {
        isDownloading = true
        Task {
            do {
                try await syncEngine.downloadAllData(context: modelContext, spreadsheetID: appState.googleSpreadsheetID)
                isDownloading = false
                appState.googleLastSyncTime = Date().timeIntervalSince1970
                alertTitle = "還原成功"
                alertMessage = "成功從雲端試算表下載並還原所有資料至本機資料庫！"
                showAlert = true
            } catch {
                isDownloading = false
                alertTitle = "還原失敗"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - Subview: GoogleDriveFileBrowser

enum FileFilterMode: String, CaseIterable, Identifiable {
    case matched = "matched"
    case all = "all"
    
    var id: String { self.rawValue }
    var title: String {
        switch self {
        case .matched: return "✨ 匹配 CRM"
        case .all: return "📁 瀏覽全部"
        }
    }
}

struct GoogleDriveFileBrowser: View {
    let files: [GoogleDriveFile]
    let isFetching: Bool
    
    let onSelect: (GoogleDriveFile) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    @State private var filterMode: FileFilterMode = .matched
    
    var filteredFiles: [GoogleDriveFile] {
        var list = files
        
        if filterMode == .matched {
            list = files.filter { $0.isCRMMatched }
        }
        
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return list
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Filter Control
                Picker("篩選模式", selection: $filterMode) {
                    ForEach(FileFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color.white)
                
                Divider()
                
                if isFetching {
                    Spacer()
                    ProgressView("讀取 Google 雲端硬碟中...")
                        .tint(AppTheme.Colors.accent)
                    Spacer()
                } else if filteredFiles.isEmpty {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        
                        if filterMode == .matched {
                            Text("未發現任何名稱匹配的 CRM 試算表檔案")
                                .font(AppTheme.Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.primary)
                            Text("💡 提示：請切換至「瀏覽全部」尋找，或在設定頁中點擊「建立全新對接試算表」。")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        } else {
                            Text(searchText.isEmpty ? "未在您的 Google Drive 發現任何試算表檔案" : "找不到符合「\(searchText)」的試算表")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    Spacer()
                } else {
                    List(filteredFiles) { file in
                        Button {
                            onSelect(file)
                        } label: {
                            HStack {
                                Image(systemName: "tablecells.badge.ellipsis")
                                    .font(.system(size: 18))
                                    .foregroundStyle(file.isCRMMatched ? AppTheme.Colors.accent : AppTheme.Colors.success)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(file.name)
                                            .font(AppTheme.Typography.body)
                                            .foregroundStyle(AppTheme.Colors.primary)
                                            .fontWeight(file.isCRMMatched ? .semibold : .regular)
                                        
                                        if file.isCRMMatched {
                                            Text("CRM 匹配")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(AppTheme.Colors.accent)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1)
                                                .background(AppTheme.Colors.accent.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text("ID: \(file.id.prefix(8))...\(file.id.suffix(6))")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("選擇 Google 試算表對接")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜尋試算表名稱...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { onCancel() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .background(AppTheme.Colors.background)
        }
    }
}

// MARK: - Subview: ConnectExistingSheetView

struct ConnectExistingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var urlOrIDInput: String
    let onConnect: (String, String) -> Void
    
    @State private var isVerifying = false
    @State private var errorMessage = ""
    private let sheetsService = GoogleSheetsService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("輸入現有試算表連結或 ID") {
                    Text("請複製並貼上您的 Google 試算表完整網址，或是輸入試算表的專屬 ID：")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    TextField("https://docs.google.com/spreadsheets/d/...", text: $urlOrIDInput)
                        .font(.system(size: 12, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.danger)
                            .fontWeight(.medium)
                            .padding(.top, 2)
                    }
                }
                
                Section("如何取得試算表連結？") {
                    Text("1. 開啟您的瀏覽器前往 Google Drive。\n2. 點選您要連接的現有試算表檔案。\n3. 複製瀏覽器網址列中的整行網址（或是複製網址中 /d/ 後面的英數組合 ID）。\n4. 將其貼於上方欄位，點擊「驗證並連接」即可。")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineSpacing(4)
                }
            }
            .navigationTitle("連接現有試算表 (Connect Existing)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        verifyAndConnect()
                    } label: {
                        if isVerifying {
                            ProgressView()
                                .tint(AppTheme.Colors.accent)
                        } else {
                            Text("驗證並連接")
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                    }
                    .disabled(isVerifying || urlOrIDInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .background(AppTheme.Colors.background)
        }
    }
    
    private func verifyAndConnect() {
        let trimmed = urlOrIDInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isVerifying = true
        errorMessage = ""
        
        let id = extractSpreadsheetID(from: trimmed)
        
        Task {
            do {
                let title = try await sheetsService.fetchSpreadsheetTitle(spreadsheetID: id)
                isVerifying = false
                onConnect(id, title)
                dismiss()
            } catch {
                isVerifying = false
                errorMessage = "無法讀取試算表，請確認：\n1. 試算表 ID/網址是否正確\n2. 您的 Google 帳戶是否有存取權限\n3. 是否已啟用 Google Sheets API\n\n錯誤詳情：\(error.localizedDescription)"
            }
        }
    }
    
    private func extractSpreadsheetID(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("docs.google.com/spreadsheets") {
            if let range = trimmed.range(of: "/d/") {
                let start = range.upperBound
                let rest = trimmed[start...]
                if let endRange = rest.range(of: "/") {
                    return String(rest[..<endRange.lowerBound])
                } else if let queryRange = rest.range(of: "?") {
                    return String(rest[..<queryRange.lowerBound])
                } else {
                    return String(rest)
                }
            }
        }
        return trimmed
    }
}
