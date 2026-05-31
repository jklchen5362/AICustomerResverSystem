//  TreatmentPackageDetailView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct TreatmentPackageDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let package: TreatmentPackage
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Header Ring Card
                VStack(spacing: AppTheme.Spacing.md) {
                    Text(package.treatmentName)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    let progress = package.totalSessions > 0 ? Double(package.remainingSessions) / Double(package.totalSessions) : 0.0
                    CircularProgressView(progress: progress, lineWidth: 10, size: 100)
                        .padding(.vertical, AppTheme.Spacing.xs)
                    
                    HStack(spacing: AppTheme.Spacing.xl) {
                        VStack {
                            Text("\(package.sessionsUsed)")
                                .font(AppTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("已使用")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        
                        Divider().frame(height: 30)
                        
                        VStack {
                            Text("\(package.remainingSessions)")
                                .font(AppTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.sessionColor(percentage: progress))
                            Text("剩餘")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    // Status Badge
                    statusLabel(progress: progress)
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 3)
                .padding(.horizontal, AppTheme.Spacing.md)
                
                // Detailed Information Rows
                VStack(spacing: 1) {
                    detailRow(label: "所屬客戶 Customer", value: package.customer?.fullName ?? "未知客戶", icon: "person")
                    detailRow(label: "購買分店 Branch", value: package.purchaseBranch?.name ?? "未指定", icon: "building.2")
                    detailRow(label: "購買日期 Date", value: package.purchaseDate.formattedDate, icon: "calendar")
                    detailRow(label: "到期日期 Expiration", value: package.expirationDate?.formattedDate ?? "無限期", icon: "clock")
                    detailRow(label: "諮詢顧問 Consultant", value: package.salesConsultant.isEmpty ? "未註記" : package.salesConsultant, icon: "person.badge.clock")
                    detailRow(label: "單堂均價 Rate", value: (package.purchaseAmount / Double(package.totalSessions)).formattedCurrency, icon: "tag")
                    detailRow(label: "實付總額 Paid Total", value: package.purchaseAmount.formattedCurrency, icon: "dollarsign.circle")
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 3)
                .padding(.horizontal, AppTheme.Spacing.md)
                
                // Consumption History Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("核銷扣堂記錄 Consumption Records")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                    
                    let records = package.consumptions.sorted(by: { $0.date > $1.date })
                    if records.isEmpty {
                        HStack {
                            Spacer()
                            Text("目前尚無核銷紀錄")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .padding(.vertical, AppTheme.Spacing.lg)
                            Spacer()
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                        .padding(.horizontal, AppTheme.Spacing.md)
                    } else {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            ForEach(records) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.date.formattedDate)
                                            .font(AppTheme.Typography.callout)
                                            .fontWeight(.bold)
                                        Text("經手人: \(record.operatorName) • \(record.branchName)")
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("扣除 \(record.sessionsConsumed) 堂")
                                        .font(AppTheme.Typography.callout)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.Colors.danger)
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                                .shadow(color: .black.opacity(0.01), radius: 3, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("療程方案詳情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Row builder
    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 20)
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
    }
    
    // MARK: - Status Badge
    private func statusLabel(progress: Double) -> some View {
        let isExpired = package.expirationDate != nil && package.expirationDate! <= Date()
        
        let labelText: String
        let color: Color
        
        if package.remainingSessions == 0 {
            labelText = "已結案 Completed"
            color = AppTheme.Colors.statusCompleted
        } else if isExpired {
            labelText = "已過期 Expired"
            color = AppTheme.Colors.danger
        } else {
            labelText = "使用中 Active"
            color = AppTheme.Colors.statusArrived
        }
        
        return Text(labelText)
            .font(AppTheme.Typography.caption)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
