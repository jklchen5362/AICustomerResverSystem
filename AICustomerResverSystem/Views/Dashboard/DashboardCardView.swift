//  DashboardCardView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct DashboardCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @State private var animateGradient = false
    @State private var showEditProfileSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(greetingText)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Button {
                        showEditProfileSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("\(appState.consultantName)")
                                .font(AppTheme.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.Colors.accent.opacity(0.8))
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button {
                    showEditProfileSheet = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                        Text(appState.branchName)
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date().formattedWeekday)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.accent)
                    
                    Text(Date().formattedShortDate)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("系統狀態")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.Colors.success)
                                .frame(width: 6, height: 6)
                            Text("已同步 Online")
                                .font(AppTheme.Typography.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.success)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(height: 170)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1A2E"),
                            animateGradient ? Color(hex: "16213E") : Color(hex: "252A4A"),
                            Color(hex: "0F3460")
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                )
                .animation(.linear(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color(hex: "1A1A2E").opacity(0.15), radius: 15, x: 0, y: 8)
        .onAppear {
            animateGradient = true
            
            // Sync initial values from SwiftData to AppState for immediate observation
            if let user = appState.currentUser {
                appState.consultantName = user.displayName
            } else {
                let userDescriptor = FetchDescriptor<UserAccount>()
                if let firstUser = try? modelContext.fetch(userDescriptor).first {
                    appState.currentUser = firstUser
                    appState.consultantName = firstUser.displayName
                }
            }
            
            if let branch = appState.selectedBranch {
                appState.branchName = branch.name
            } else {
                let branchDescriptor = FetchDescriptor<Branch>()
                if let firstBranch = try? modelContext.fetch(branchDescriptor).first {
                    appState.selectedBranch = firstBranch
                    appState.branchName = firstBranch.name
                }
            }
        }
        .sheet(isPresented: $showEditProfileSheet) {
            EditProfileBranchSheet()
                .environment(appState)
                .modelContext(modelContext)
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 5 { return "深夜好，辛苦了" }
        if hour < 11 { return "早安，開啟美好的一天" }
        if hour < 14 { return "午安，辛苦了" }
        if hour < 18 { return "下午好， clinic 精英" }
        return "晚安，願您今晚愉快"
    }
}

// MARK: - EditProfileBranchSheet

struct EditProfileBranchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query private var branches: [Branch]
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    
    @State private var selectedBranchID: String = ""
    @State private var branchName: String = ""
    @State private var branchAddress: String = ""
    @State private var branchPhone: String = ""
    @State private var branchManager: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("諮詢顧問帳戶設定") {
                    HStack {
                        Label("顧問姓名", systemImage: "person.text.rectangle.fill")
                        Spacer()
                        TextField("請輸入姓名", text: $displayName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    HStack {
                        Label("電子郵件", systemImage: "envelope.fill")
                        Spacer()
                        TextField("請輸入信箱", text: $email)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                
                Section("執勤分店選擇") {
                    if branches.isEmpty {
                        Text("系統中無分店資料，將自動建立。")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    } else {
                        Picker("選擇分店", selection: $selectedBranchID) {
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch.branchID)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("所選分店詳細資料編輯") {
                    HStack {
                        Label("分店名稱", systemImage: "building.2.fill")
                        Spacer()
                        TextField("請輸入分店名稱", text: $branchName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    HStack {
                        Label("分店地址", systemImage: "map.fill")
                        Spacer()
                        TextField("請輸入分店地址", text: $branchAddress)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    HStack {
                        Label("聯絡電話", systemImage: "phone.fill")
                        Spacer()
                        TextField("請輸入聯絡電話", text: $branchPhone)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .keyboardType(.phonePad)
                    }
                    HStack {
                        Label("分店負責人", systemImage: "person.badge.key.fill")
                        Spacer()
                        TextField("請輸入負責人姓名", text: $branchManager)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
            }
            .navigationTitle("編輯個人與分店資料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .onAppear {
                if let user = appState.currentUser {
                    displayName = user.displayName
                    email = user.email
                } else {
                    displayName = appState.consultantName
                    email = "consultant@beautyclinic.tw"
                }
                
                if let branch = appState.selectedBranch {
                    selectedBranchID = branch.branchID
                } else if let firstBranch = branches.first {
                    selectedBranchID = firstBranch.branchID
                } else {
                    selectedBranchID = "BR-TPE"
                }
                
                if let branch = branches.first(where: { $0.branchID == selectedBranchID }) {
                    branchName = branch.name
                    branchAddress = branch.address
                    branchPhone = branch.phone
                    branchManager = branch.manager
                } else {
                    branchName = appState.branchName
                    branchAddress = "台北市大安區忠孝東路四段100號"
                    branchPhone = "02-2771-1234"
                    branchManager = "王美麗"
                }
            }
            .onChange(of: selectedBranchID) { _, newID in
                if let branch = branches.first(where: { $0.branchID == newID }) {
                    branchName = branch.name
                    branchAddress = branch.address
                    branchPhone = branch.phone
                    branchManager = branch.manager
                }
            }
        }
    }
    
    private func saveChanges() {
        // 1. Update user account
        if let user = appState.currentUser {
            user.displayName = displayName
            user.email = email
        } else {
            let newUser = UserAccount(username: "consultant", displayName: displayName, email: email, role: .consultant)
            modelContext.insert(newUser)
            appState.currentUser = newUser
        }
        
        // 2. Update branch details
        var branchToUse: Branch
        if let existingBranch = branches.first(where: { $0.branchID == selectedBranchID }) {
            existingBranch.name = branchName
            existingBranch.address = branchAddress
            existingBranch.phone = branchPhone
            existingBranch.manager = branchManager
            branchToUse = existingBranch
        } else {
            let newBranch = Branch(branchID: selectedBranchID, name: branchName, address: branchAddress, phone: branchPhone, manager: branchManager)
            modelContext.insert(newBranch)
            branchToUse = newBranch
        }
        
        // Update selection in AppState
        appState.selectedBranch = branchToUse
        appState.currentUser?.assignedBranchID = branchToUse.branchID
        
        // Update observable strings for instant UI refresh
        appState.consultantName = displayName
        appState.branchName = branchName
        
        // 3. Save to SwiftData
        try? modelContext.save()
        
        print("[Dashboard] Saved consultant '\(displayName)' and branch '\(branchName)' successfully.")
    }
}

#Preview {
    DashboardCardView()
        .padding()
        .environment(AppState())
}
