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
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header Banner
                headerBanner
                
                // Live Connection Status Diagnostics Card
                iCloudDiagnosticsCard
                
                // Database Selection Options
                databaseSelectionSection
                
                // Technical Architecture / Safety Guidelines
                syncArchitectureTips
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("雲端同步設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("確認切換資料庫？", isPresented: $showSwitchConfirmation) {
            Button("取消", role: .cancel) {
                pendingDatabaseType = nil
            }
            Button("確認切換") {
                if let newType = pendingDatabaseType {
                    withAnimation(AppTheme.Animations.smooth) {
                        databaseSelection = newType.rawValue
                    }
                }
                pendingDatabaseType = nil
            }
        } message: {
            if let newType = pendingDatabaseType {
                Text("您即將將資料庫模式切換至「\(newType.title)」。\n\n切換後，系統會將本機儲存與該雲端資料庫重新加載，可能需要幾秒鐘進行初始對接。確認繼續嗎？")
            } else {
                Text("確認切換資料庫模式嗎？")
            }
        }
        .onAppear {
            Task {
                await cloudKitService.checkAccountStatus()
            }
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
                Image(systemName: "iphone.personal")
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
}

#Preview {
    NavigationStack {
        CloudSyncSettingsView()
    }
}
