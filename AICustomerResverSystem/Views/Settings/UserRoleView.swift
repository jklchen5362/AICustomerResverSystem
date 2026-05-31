//  UserRoleView.swift
//  AICustomerResverSystem

import SwiftUI

struct UserRoleView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        List {
            Section("我的職責角色 Position") {
                if let user = appState.currentUser {
                    let role = user.role
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: role.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Colors.primaryGradient)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(AppTheme.Typography.body)
                                .fontWeight(.bold)
                            
                            Text(role.displayName)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                        
                        Spacer()
                        
                        Text("當前登入角色")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.Colors.success.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("所有系統權限與角色架構 Roles & Permissions") {
                ForEach(UserRole.allCases) { role in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: role.icon)
                                .foregroundStyle(AppTheme.Colors.accent)
                            Text(role.displayName)
                                .font(AppTheme.Typography.callout)
                                .fontWeight(.bold)
                        }
                        
                        Text(roleDescription(role))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        // Permissions chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(role.permissions).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { perm in
                                    Text(permissionDisplayName(perm))
                                        .font(.system(size: 9, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color(.systemGray6))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("系統權限與角色")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func roleDescription(_ role: UserRole) -> String {
        switch role {
        case .admin: return "擁有診所最高核心設定權限，可管理分店、刪除客戶、調整財務。"
        case .doctor: return "主治臨床作業，可調閱病歷與膚質、填寫諮詢紀錄與排程。"
        case .consultant: return "主力銷售與客戶關懷，可建檔療程、補錄交易發票、扣堂等。"
        case .receptionist: return "協助預約掛號與基本個資建檔，無核心財務與刪除權限。"
        case .beautician: return "協助核銷療程堂數、填寫美容操作紀錄，無報表與設定權限。"
        }
    }
    
    private func permissionDisplayName(_ perm: Permission) -> String {
        switch perm {
        case .viewCustomers: return "👀 檢視客戶"
        case .editCustomers: return "✏️ 編輯客戶"
        case .deleteCustomers: return "❌ 刪除客戶"
        case .viewAppointments: return "📅 檢視預約"
        case .editAppointments: return "✏️ 調整預約"
        case .deleteAppointments: return "❌ 取消預約"
        case .viewPackages: return "🛍️ 檢視療程"
        case .editPackages: return "✏️ 新增療程"
        case .deletePackages: return "❌ 刪除療程"
        case .addConsumption: return "✂️ 扣堂核銷"
        case .viewFinancials: return "💰 檢視財務"
        case .editFinancials: return "✏️ 管理發票"
        case .viewReports: return "📊 檢視報表"
        case .manageUsers: return "👥 帳號管理"
        case .manageBranches: return "🏢 分店管理"
        case .manageSettings: return "⚙️ 核心設定"
        }
    }
}

#Preview {
    UserRoleView()
        .environment(AppState())
}
