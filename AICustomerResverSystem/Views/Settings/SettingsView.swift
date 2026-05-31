//  SettingsView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var notificationsEnabled = true
    @State private var faceIDEnabled = false
    @State private var selectedThemeIndex = 0
    
    @State private var showingResetAlert = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        List {
            // Profile Card Section
            Section("登入使用者 Profile") {
                if let user = appState.currentUser {
                    HStack(spacing: AppTheme.Spacing.md) {
                        let initials = String(user.displayName.prefix(2))
                        Text(initials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(AppTheme.Colors.primaryGradient)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.Colors.accent.opacity(0.4), lineWidth: 1.5))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(AppTheme.Typography.body)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: UserRoleView()) {
                            Text(user.role.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.Colors.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // App settings
            Section("應用程式設定 Preference") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("啟用預約提醒通知", systemImage: "bell.badge.fill")
                }
                
                Toggle(isOn: $faceIDEnabled) {
                    Label("啟用 Face ID 生物解鎖", systemImage: "faceid")
                }
                
                Picker(selection: $selectedThemeIndex, label: Label("介面外觀 Theme", systemImage: "paintbrush.fill")) {
                    Text("智能白皙 (預設)").tag(0)
                    Text("奢華曜黑 (暗黑)").tag(1)
                }
            }
            
            // Branch Assignment
            Section("執勤分店據點 Assignment") {
                if let branch = appState.selectedBranch {
                    HStack {
                        Label("當前駐店據點", systemImage: "building.2.fill")
                        Spacer()
                        Text(branch.name)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            // Data options
            Section("資料安全與系統重置 Database") {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Label("清除快取並還原系統範例資料", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                }
            }
            
            // About info
            Section("關於系統 About") {
                HStack {
                    Text("系統名稱")
                    Spacer()
                    Text(AppConstants.appName)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text("軟體版本")
                    Spacer()
                    Text(AppConstants.version)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text("開發團隊")
                    Spacer()
                    Text("AICustomerResverSystem Team")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .navigationTitle("系統核心設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("確認還原系統嗎？", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("還原", role: .destructive) {
                resetDatabase()
            }
        } message: {
            Text("此動作將會清除系統中所有的客戶檔案、購買方案與排程，並重新載入 20+ 筆全新的奢華台灣據點示範資料。確認執行嗎？")
        }
        .alert("系統已重置", isPresented: $showSuccessAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("範例數據已成功重新寫入資料庫！")
        }
    }
    
    @MainActor
    private func resetDatabase() {
        do {
            // 1. Delete all invoices
            let invDesc = FetchDescriptor<Invoice>()
            let invs = (try? modelContext.fetch(invDesc)) ?? []
            for item in invs { modelContext.delete(item) }
            
            // 2. Delete all appointments
            let apptDesc = FetchDescriptor<Appointment>()
            let appts = (try? modelContext.fetch(apptDesc)) ?? []
            for item in appts { modelContext.delete(item) }
            
            // 3. Delete all packages
            let pkgDesc = FetchDescriptor<TreatmentPackage>()
            let pkgs = (try? modelContext.fetch(pkgDesc)) ?? []
            for item in pkgs { modelContext.delete(item) }
            
            // 4. Delete all customers
            let custDesc = FetchDescriptor<Customer>()
            let custs = (try? modelContext.fetch(custDesc)) ?? []
            for item in custs { modelContext.delete(item) }
            
            // 5. Delete all branches
            let branchDesc = FetchDescriptor<Branch>()
            let branches = (try? modelContext.fetch(branchDesc)) ?? []
            for item in branches { modelContext.delete(item) }
            
            // 6. Delete all notifications
            let notifDesc = FetchDescriptor<AppNotification>()
            let notifs = (try? modelContext.fetch(notifDesc)) ?? []
            for item in notifs { modelContext.delete(item) }
            
            // 7. Delete all chat messages
            let msgDesc = FetchDescriptor<ChatMessage>()
            let msgs = (try? modelContext.fetch(msgDesc)) ?? []
            for item in msgs { modelContext.delete(item) }
            
            try modelContext.save()
            
            // 8. Re-load sample data
            SampleDataService.loadSampleData(into: modelContext)
            
            showSuccessAlert = true
        } catch {
            print("Failed to reset database: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppState())
    .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
