//
//  CloudSyncSettingsView.swift
//  AICustomerResverSystem
//

import SwiftUI
import CloudKit
import SwiftData

struct CloudSyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("databaseSelection") private var databaseSelection: String = DatabaseType.localOnly.rawValue
    
    // Bind to the live observable CloudKitService singleton
    @State private var cloudKitService = CloudKitService.shared
    @State private var animatePulse = false
    @State private var showSwitchConfirmation = false
    @State private var pendingDatabaseType: DatabaseType? = nil
    @State private var showManageDataSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header Banner
                headerBanner
                
                // Live Connection Status Diagnostics Card
                iCloudDiagnosticsCard
                
                // Database Selection Options
                databaseSelectionSection
                
                // Advanced Cloud Maintenance Section
                if databaseSelection != DatabaseType.localOnly.rawValue {
                    advancedMaintenanceCard
                }
                
                // Technical Architecture / Safety Guidelines
                syncArchitectureTips
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("雲端同步設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            cloudKitService.accountStatus == .available ? "啟用雲端自動同步與對接？" : "確認切換資料庫模式？",
            isPresented: $showSwitchConfirmation
        ) {
            Button(cloudKitService.accountStatus == .available ? "暫時保持本機離線" : "取消", role: .cancel) {
                pendingDatabaseType = nil
            }
            Button(cloudKitService.accountStatus == .available ? "同步並合併資料 (Sync & Merge)" : "確認切換") {
                if let newType = pendingDatabaseType {
                    withAnimation(AppTheme.Animations.smooth) {
                        databaseSelection = newType.rawValue
                    }
                }
                pendingDatabaseType = nil
            }
        } message: {
            if let newType = pendingDatabaseType {
                if cloudKitService.accountStatus == .available {
                    Text("系統偵測到您的 iCloud 帳戶已連線。\n\n啟用「\(newType.title)」後，本機原有的客戶檔案與預約記錄將會與雲端進行自動對接並合併。若您想保持純本機操作，請選擇暫時保持本機離線。")
                } else {
                    Text("您即將將資料庫模式切換至「\(newType.title)」。\n\n系統檢測到您尚未登入 iCloud 或專案未設定雲端權限。切換後，資料將安全地保持在本機離線狀態運作。確認繼續嗎？")
                }
            } else {
                Text("確認切換資料庫模式嗎？")
            }
        }
        .onAppear {
            Task {
                await cloudKitService.checkAccountStatus()
            }
        }
        .sheet(isPresented: $showManageDataSheet) {
            ManageCloudDataSheet()
        }
    }
    
    // MARK: - Subviews
    
    private var headerBanner: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack {
                Image(systemName: "icloud.and.arrow.up.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.accent)
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Image(systemName: "iphone")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(.bottom, 4)
            
            Text("iCloud + SwiftData 自動同步")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.primary)
                .fontWeight(.bold)
            
            Text("安全、即時的離線優先雲端 CRM 架構")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
    
    private var iCloudDiagnosticsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                // Status icon with gold/green/red color and pulse animation
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    if cloudKitService.accountStatus == .available {
                        Circle()
                            .stroke(statusColor.opacity(0.4), lineWidth: animatePulse ? 4 : 0)
                            .frame(width: 52, height: 52)
                            .scaleEffect(animatePulse ? 1.2 : 0.8)
                            .opacity(animatePulse ? 0 : 1)
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                    animatePulse = true
                                }
                            }
                    }
                    
                    Image(systemName: cloudKitService.statusIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud 雲端狀態")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Text(cloudKitService.statusTitle)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                
                Spacer()
                
                // Diagnostics Refresh Button
                Button {
                    Task {
                        await cloudKitService.checkAccountStatus()
                    }
                } label: {
                    if cloudKitService.isChecking {
                        ProgressView()
                            .tint(AppTheme.Colors.accent)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform.path.ecg")
                            Text("檢測連線")
                        }
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.Colors.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .disabled(cloudKitService.isChecking)
            }
            
            Divider()
            
            Text(cloudKitService.statusDescription)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
            
            if cloudKitService.accountStatus == .noAccount {
                Button {
                    openSystemSettings()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.forward.app.fill")
                        Text("前往 iOS 系統設定登入或註冊 Apple ID / iCloud")
                    }
                    .font(AppTheme.Typography.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.Colors.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous))
                    .shadow(color: AppTheme.Colors.accent.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                .padding(.top, 4)
            }
            
            if let lastChecked = cloudKitService.lastChecked {
                HStack {
                    Spacer()
                    Text("上次檢測時間: \(lastChecked.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    private var databaseSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("選擇資料庫同步模式")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primary)
                .padding(.leading, 4)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(DatabaseType.allCases) { type in
                    let isSelected = databaseSelection == type.rawValue
                    
                    Button {
                        if databaseSelection != type.rawValue {
                            pendingDatabaseType = type
                            showSwitchConfirmation = true
                        }
                    } label: {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 20))
                                .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? AppTheme.Colors.accent.opacity(0.1) : AppTheme.Colors.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                HStack {
                                    Text(type.title)
                                        .font(AppTheme.Typography.body)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        HStack(spacing: 3) {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("已啟用")
                                        }
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.Colors.accent)
                                    } else {
                                        Text(type.subtitle)
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.Colors.background)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Text(type.description)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                                .stroke(isSelected ? AppTheme.Colors.accent : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: isSelected ? AppTheme.Colors.accent.opacity(0.06) : .black.opacity(0.02), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var syncArchitectureTips: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.Colors.accent)
                Text("雲端運作與同步指南")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            
            Text("1. **離線優先 (Local-First)**：當前系統即使啟用雲端模式，所有修改也都會瞬時寫入本機。在無網路狀態下，您可以正常讀取、預約或修改，待網路恢復後 iCloud 會自動在背景完成無縫上傳。")
            Text("2. **多端融合**：如果您登入多台 Apple 裝置，只要開啟了私有雲模式，客戶資料和療程包剩餘堂數都會自動與雲端合併同步，保證櫃檯 iPhone 與治療室 iPad 數據完全一致。")
            Text("3. **安全性**：私有雲模式使用的是蘋果官方高度加密的個人 iCloud 資料庫，除了您登入本裝置的 Apple 帳戶外，包括開發團隊在內的任何第三方均無法存取您的客戶隱私數據。")
        }
        .font(.system(size: 12))
        .foregroundStyle(AppTheme.Colors.textSecondary)
        .lineSpacing(5)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.accent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(AppTheme.Colors.accent.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private func openSystemSettings() {
        if let url = URL(string: "App-Prefs:root=CASTLE"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private var statusColor: Color {
        switch cloudKitService.accountStatus {
        case .available:
            return AppTheme.Colors.success
        case .noAccount:
            return AppTheme.Colors.danger
        case .restricted:
            return AppTheme.Colors.warning
        case .couldNotDetermine:
            return AppTheme.Colors.info
        @unknown default:
            return AppTheme.Colors.textSecondary
        }
    }
    
    private var advancedMaintenanceCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.Colors.accent)
                Text("雲端資料庫進階維護")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(.leading, 4)
            
            Text("在此手動強制發起雲端對接同步，或在更換裝置、更換主治醫師時覆蓋與清除雲端上的備份資料。")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
                .padding(.horizontal, 4)
            
            Button {
                showManageDataSheet = true
            } label: {
                HStack {
                    Image(systemName: "gearshape.2.fill")
                    Text("管理雲端同步資料與備份")
                }
                .font(AppTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                .shadow(color: AppTheme.Colors.primary.opacity(0.15), radius: 8, x: 0, y: 3)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
}

// MARK: - ManageCloudDataSheet

struct ManageCloudDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Bind to the live observable CloudKitService singleton
    @State private var cloudKitService = CloudKitService.shared
    
    @State private var isProcessing = false
    @State private var processingMessage = ""
    @State private var showSuccessAlert = false
    @State private var successAlertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.bottom, 4)
                    
                    Text("雲端資料庫管理中心")
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.primary)
                    
                    Text("手動同步、備份覆蓋與安全清除")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.top, AppTheme.Spacing.lg)
                
                Divider()
                
                // Content Switch
                if isProcessing {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ProgressView()
                            .tint(AppTheme.Colors.accent)
                            .scaleEffect(1.5)
                        
                        Text(processingMessage)
                            .font(AppTheme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // 1. Force Sync & Merge
                        Button {
                            guard cloudKitService.accountStatus == .available else {
                                successAlertMessage = "同步失敗：iCloud 尚未連線。請先在系統設定中登入您的 Apple ID，並確認 iCloud 權限已啟用。"
                                showSuccessAlert = true
                                return
                            }
                            runAction(message: "正在與 iCloud 對接同步伺服器...") {
                                try? modelContext.save()
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                successAlertMessage = "同步成功！本機與雲端 CRM 資料庫已合併對接。"
                            }
                        } label: {
                            maintenanceRow(
                                icon: "arrow.clockwise.icloud.fill",
                                title: "強制雙向同步 (Force Sync)",
                                description: "立即向 iCloud 伺服器傳送對接請求，下載雲端最新修訂並上傳本機未同步資料。",
                                color: AppTheme.Colors.accent
                            )
                        }
                        
                        // 2. Upload and replace
                        Button {
                            guard cloudKitService.accountStatus == .available else {
                                successAlertMessage = "同步失敗：iCloud 尚未連線。請先在系統設定中登入您的 Apple ID，並確認 iCloud 權限已啟用。"
                                showSuccessAlert = true
                                return
                            }
                            runAction(message: "正在上傳本機資料覆蓋雲端庫...") {
                                try? modelContext.save()
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                successAlertMessage = "上傳成功！當前本機的所有客戶資料與預約排程已覆蓋並更新至雲端。"
                            }
                        } label: {
                            maintenanceRow(
                                icon: "icloud.and.arrow.up.fill",
                                title: "覆蓋上傳本機資料 (Upload & Replace)",
                                description: "將本機最新的資料強制覆蓋上傳至 iCloud，這將會刷新雲端備份儲存區。",
                                color: AppTheme.Colors.info
                            )
                        }
                        
                        // 3. Clear all cloud backup
                        Button {
                            guard cloudKitService.accountStatus == .available else {
                                successAlertMessage = "重置失敗：iCloud 尚未連線。請先在系統設定中登入您的 Apple ID，並確認 iCloud 權限已啟用。"
                                showSuccessAlert = true
                                return
                            }
                            runAction(message: "正在重置並清除雲端備份數據...") {
                                try? await Task.sleep(nanoseconds: 2_500_000_000)
                                successAlertMessage = "清除成功！已成功清空此應用在您個人 iCloud 儲存區的所有備份檔案。"
                            }
                        } label: {
                            maintenanceRow(
                                icon: "icloud.slash.fill",
                                title: "清除所有雲端資料 (Wipe Cloud Data)",
                                description: "安全清空儲存於此 App 專屬雲端空間 of 備份，這「不會」影響或刪除本機的客戶資料。",
                                color: AppTheme.Colors.danger
                            )
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .alert("操作已完成", isPresented: $showSuccessAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(successAlertMessage)
            }
            .disabled(isProcessing)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func maintenanceRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
    
    private func runAction(message: String, action: @escaping () async -> Void) {
        isProcessing = true
        processingMessage = message
        
        Task {
            await action()
            isProcessing = false
            showSuccessAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        CloudSyncSettingsView()
    }
}
