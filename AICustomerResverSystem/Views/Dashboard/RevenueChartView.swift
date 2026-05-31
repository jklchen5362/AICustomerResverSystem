//  RevenueChartView.swift
//  AICustomerResverSystem

import SwiftUI
import Charts

struct RevenueChartView: View {
    let data: [DashboardViewModel.RevenueDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("營收趨勢 Revenue Trend")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("近 6 個月營業額統計")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                
                Text(totalRevenueText)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.accent.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.bottom, AppTheme.Spacing.xs)
            
            if data.isEmpty {
                VStack {
                    Spacer()
                    Text("尚無足夠營收數據")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Spacer()
                }
                .frame(height: 180)
            } else {
                Chart {
                    ForEach(data) { point in
                        BarMark(
                            x: .value("月份", point.month),
                            y: .value("營收", point.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.accent, AppTheme.Colors.accentLight],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                        
                        LineMark(
                            x: .value("月份", point.month),
                            y: .value("營收", point.amount)
                        )
                        .foregroundStyle(AppTheme.Colors.primaryLight)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("月份", point.month),
                            y: .value("營收", point.amount)
                        )
                        .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount.formattedCompact)
                                    .font(AppTheme.Typography.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(AppTheme.Typography.caption2)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
    }
    
    private var totalRevenueText: String {
        let total = data.reduce(0.0) { $0 + $1.amount }
        return "累計：\(total.formattedCurrency)"
    }
}

#Preview {
    RevenueChartView(data: [
        DashboardViewModel.RevenueDataPoint(month: "12月", amount: 280000),
        DashboardViewModel.RevenueDataPoint(month: "1月", amount: 320000),
        DashboardViewModel.RevenueDataPoint(month: "2月", amount: 240000),
        DashboardViewModel.RevenueDataPoint(month: "3月", amount: 410000),
        DashboardViewModel.RevenueDataPoint(month: "4月", amount: 350000),
        DashboardViewModel.RevenueDataPoint(month: "5月", amount: 520000)
    ])
    .padding()
    .background(AppTheme.Colors.background)
}
