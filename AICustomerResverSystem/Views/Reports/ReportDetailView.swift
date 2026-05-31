//  ReportDetailView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData
import Charts

struct ReportDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let type: ReportType
    
    @State private var viewModel = ReportViewModel()
    @Query private var customers: [Customer]
    @Query private var invoices: [Invoice]
    @Query private var packages: [TreatmentPackage]
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                switch type {
                case .customer:
                    customerReportDetails
                case .revenue:
                    revenueReportDetails
                case .treatment:
                    treatmentReportDetails
                case .branch:
                    branchReportDetails
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle(type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Customer Analysis Details
    private var customerReportDetails: some View {
        let data = viewModel.generateCustomerReport(customers: customers)
        return VStack(spacing: AppTheme.Spacing.md) {
            // Stats Row
            HStack(spacing: AppTheme.Spacing.md) {
                StatCard(
                    title: "客戶總數",
                    value: "\(data.totalCount)",
                    icon: "person.2.fill",
                    color: AppTheme.Colors.accent
                )
                
                StatCard(
                    title: "本月新客增長",
                    value: "\(data.growthCount)",
                    icon: "arrow.up.forward.path.fill",
                    color: AppTheme.Colors.success
                )
            }
            
            // VIP levels chart list
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("會員等級分佈 VIP Levels")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                if data.vipCount.isEmpty {
                    Text("無會員分佈統計數據")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                } else {
                    Chart {
                        ForEach(data.vipCount.sorted(by: { $0.value > $1.value }), id: \.key) { key, val in
                            BarMark(
                                x: .value("數量", val),
                                y: .value("等級", key)
                            )
                            .foregroundStyle(AppTheme.Colors.accent)
                        }
                    }
                    .frame(height: 180)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Revenue stats details
    private var revenueReportDetails: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let finVM = FinancialViewModel()
            let stats = finVM.calculateStats(invoices: invoices)
            
            HStack(spacing: AppTheme.Spacing.md) {
                StatCard(
                    title: "總營業額",
                    value: stats.totalRevenue.formattedCompact,
                    icon: "dollarsign.circle.fill",
                    color: AppTheme.Colors.accent
                )
                
                StatCard(
                    title: "客單價",
                    value: stats.avgTransaction.formattedCompact,
                    icon: "tag.fill",
                    color: AppTheme.Colors.accentSecondary
                )
            }
            
            // Monthly Trend Chart
            let trendData = finVM.revenueByMonth(invoices: invoices)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("月度營業額分析 Monthly Revenue")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Chart {
                    ForEach(trendData) { point in
                        BarMark(
                            x: .value("月份", point.monthName),
                            y: .value("營收", point.revenue)
                        )
                        .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
                .frame(height: 180)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Treatment report details
    private var treatmentReportDetails: some View {
        let list = viewModel.generateTreatmentReport(packages: packages)
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("療程銷量排行 Top Treatments")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xs)
            
            if list.isEmpty {
                HStack {
                    Spacer()
                    Text("無任何療程銷量統計")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(AppTheme.Typography.body)
                                .fontWeight(.bold)
                                .foregroundStyle(index == 0 ? AppTheme.Colors.accent : (index == 1 ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textSecondary))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(AppTheme.Typography.callout)
                                    .fontWeight(.bold)
                                
                                ProgressView(value: item.percentage)
                                    .tint(index == 0 ? AppTheme.Colors.accent : AppTheme.Colors.accentSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.count) 套")
                                    .font(AppTheme.Typography.callout)
                                    .fontWeight(.bold)
                                
                                Text(item.percentage.formattedPercentage)
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 10)
                        
                        if index < list.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Branch report details
    private var branchReportDetails: some View {
        let finVM = FinancialViewModel()
        let invoiceDesc = FetchDescriptor<Invoice>()
        let allInvoices = (try? modelContext.fetch(invoiceDesc)) ?? []
        let branchDesc = FetchDescriptor<Branch>()
        let allBranches = (try? modelContext.fetch(branchDesc)) ?? []
        
        let branchData = finVM.revenueByBranch(invoices: allInvoices, branches: allBranches)
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("分店業績總合 Performance by Location")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xs)
            
            if branchData.isEmpty {
                HStack {
                    Spacer()
                    Text("無任何分店據點財務數據")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                Chart {
                    ForEach(branchData) { point in
                        BarMark(
                            x: .value("營業額", point.revenue),
                            y: .value("分店", point.branchName)
                        )
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                    }
                }
                .frame(height: 180)
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
            }
        }
    }
}
