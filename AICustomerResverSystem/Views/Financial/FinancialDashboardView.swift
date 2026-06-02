//  FinancialDashboardView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData
import Charts

struct FinancialDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FinancialViewModel()
    @Query private var invoices: [Invoice]
    @Query private var branches: [Branch]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Period Selector
                    Picker("週期選擇", selection: $viewModel.selectedPeriod) {
                        ForEach(FinancialPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppTheme.Spacing.xs)
                    
                    let stats = viewModel.calculateStats(invoices: invoices)
                    
                    // Main KPI Statistics Card
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("總營業額 Revenue")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textOnDark.opacity(0.7))
                        
                        Text(stats.totalRevenue.formattedCurrency)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textOnDark)
                        
                        Divider().background(.white.opacity(0.2))
                        
                        HStack(spacing: AppTheme.Spacing.md) {
                            VStack {
                                Text(stats.avgTransaction.formattedCurrency)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.accent)
                                Text("客單價")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack {
                                Text("\(stats.invoiceCount) 筆")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textOnDark)
                                Text("交易筆數")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack {
                                Text(stats.topPaymentMethod)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.accentSecondary)
                                Text("主要支付")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
                    
                    // Revenue Trend Line Chart
                    let trendData = viewModel.revenueByMonth(invoices: invoices)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("月度營收趨勢 Monthly Trend")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        Chart {
                            ForEach(trendData) { point in
                                LineMark(
                                    x: .value("月份", point.monthName),
                                    y: .value("營收", point.revenue)
                                )
                                .foregroundStyle(AppTheme.Colors.accent)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                
                                AreaMark(
                                    x: .value("月份", point.monthName),
                                    y: .value("營收", point.revenue)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.accent.opacity(0.3), AppTheme.Colors.accent.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
                    
                    // Branch Performance Bar Chart
                    let branchData = viewModel.revenueByBranch(invoices: invoices, branches: branches)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("分店業績佔比 Branch Share")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        Chart {
                            ForEach(branchData) { point in
                                BarMark(
                                    x: .value("業績", point.revenue),
                                    y: .value("分店", point.branchName)
                                )
                                .foregroundStyle(AppTheme.Colors.accentSecondary)
                                .cornerRadius(5)
                            }
                        }
                        .frame(height: max(100, CGFloat(branches.count) * 45))
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
                    
                    // Top 5 Customers List
                    let customersSpending = viewModel.topCustomers(invoices: invoices)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("會員消費排行榜 Top 5 Customers")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        if customersSpending.isEmpty {
                            HStack {
                                Spacer()
                                Text("此區間暫無消費排行數據")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                                Spacer()
                            }
                            .padding(.vertical, AppTheme.Spacing.md)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(customersSpending.enumerated()), id: \.element.id) { index, item in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(AppTheme.Typography.body)
                                            .fontWeight(.bold)
                                            .foregroundStyle(index == 0 ? AppTheme.Colors.accent : (index == 1 ? AppTheme.Colors.accentSecondary : AppTheme.Colors.textSecondary))
                                            .frame(width: 24, alignment: .leading)
                                        
                                        Text(item.name)
                                            .font(AppTheme.Typography.callout)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text(item.amount.formattedCurrency)
                                            .font(AppTheme.Typography.body)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.Colors.accent)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if index < customersSpending.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
                    
                    // Consultant Sales Performance Rank Card
                    let consultantData = viewModel.consultantPerformance(invoices: invoices)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("人員銷售業績排行 Consultant Performance")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        if consultantData.isEmpty {
                            HStack {
                                Spacer()
                                Text("此區間暫無業績統計數據")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                                Spacer()
                            }
                            .padding(.vertical, AppTheme.Spacing.md)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(consultantData.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        // Rank badge
                                        ZStack {
                                            Circle()
                                                .fill(index == 0 ? AppTheme.Colors.vipGold.opacity(0.2) : (index == 1 ? AppTheme.Colors.vipSilver.opacity(0.2) : AppTheme.Colors.textTertiary.opacity(0.12)))
                                                .frame(width: 24, height: 24)
                                            
                                            Text("\(index + 1)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(index == 0 ? AppTheme.Colors.vipGold : (index == 1 ? AppTheme.Colors.vipSilver : AppTheme.Colors.textSecondary))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(AppTheme.Typography.callout)
                                                .fontWeight(.bold)
                                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                            
                                            Text("成交 \(item.transactionCount) 筆")
                                                .font(AppTheme.Typography.caption2)
                                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(item.amount.formattedCurrency)
                                            .font(AppTheme.Typography.body)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.Colors.accent)
                                    }
                                    .padding(.vertical, 10)
                                    
                                    if index < consultantData.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("財務業績概覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: InvoiceListView()) {
                        Text("交易發票")
                            .foregroundStyle(AppTheme.Colors.accent)
                            .font(AppTheme.Typography.headline)
                    }
                }
            }
        }
    }
}

#Preview {
    FinancialDashboardView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
