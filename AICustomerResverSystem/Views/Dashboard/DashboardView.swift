//  DashboardView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @Query private var customers: [Customer]
    @Query private var appointments: [Appointment]
    @Query private var packages: [TreatmentPackage]
    @Query private var invoices: [Invoice]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Header welcome card
                    DashboardCardView()
                    
                    // Stats 2x2 grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                        StatCard(
                            title: "客戶總數",
                            value: "\(viewModel.totalCustomers)",
                            icon: "person.2.fill",
                            color: AppTheme.Colors.accent,
                            trend: 8.4
                        )
                        
                        StatCard(
                            title: "療程銷量",
                            value: "\(viewModel.totalPackagesSold)",
                            icon: "bag.fill",
                            color: AppTheme.Colors.accentSecondary,
                            trend: 14.2
                        )
                        
                        StatCard(
                            title: "剩餘堂數",
                            value: "\(viewModel.totalRemainingSessions)",
                            icon: "clock.badge.checkmark",
                            color: AppTheme.Colors.warning,
                            trend: -2.1
                        )
                        
                        StatCard(
                            title: "今日預約",
                            value: "\(viewModel.todayAppointmentCount)",
                            icon: "calendar.badge.clock",
                            color: AppTheme.Colors.info,
                            trend: 5.0
                        )
                    }
                    
                    // Revenue chart
                    RevenueChartView(data: viewModel.monthlyRevenueData)
                    
                    // AI Recommendations
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppTheme.Colors.accent)
                            Text("AI 智能營收建議 Recommendations")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                ForEach(viewModel.aiRecommendations, id: \.self) { tip in
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text(tip)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.textPrimary)
                                            .lineLimit(4)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        HStack {
                                            Spacer()
                                            Text("生成於 剛才")
                                                .font(.system(size: 9))
                                                .foregroundStyle(AppTheme.Colors.textTertiary)
                                        }
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .frame(width: 260, height: 120)
                                    .background {
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                            .fill(AppTheme.Colors.accent.opacity(0.06))
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                            .stroke(AppTheme.Colors.accent.opacity(0.15), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                    }
                    
                    // Today's appointments list
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("今日預約 Reservations (\(viewModel.todayAppointments.count))")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            NavigationLink("查看全部", value: "appointments_tab")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                        
                        if viewModel.todayAppointments.isEmpty {
                            HStack {
                                Spacer()
                                Text("今日暫無預約行程")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                    .padding(.vertical, AppTheme.Spacing.md)
                                Spacer()
                            }
                        } else {
                            ForEach(viewModel.todayAppointments) { appointment in
                                HStack(spacing: AppTheme.Spacing.md) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appointment.startTime.formattedTime)
                                            .font(AppTheme.Typography.headline)
                                            .foregroundStyle(AppTheme.Colors.textPrimary)
                                        Text(appointment.endTime.formattedTime)
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                    }
                                    .frame(width: 50, alignment: .leading)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(appointment.status.color)
                                        .frame(width: 4, height: 35)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appointment.customer?.fullName ?? "未知客戶")
                                            .font(AppTheme.Typography.callout)
                                            .fontWeight(.semibold)
                                        Text(appointment.treatmentItem)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    StatusBadge(status: appointment.status, compact: true)
                                }
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .background(Color(.systemGray6).opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("儀表板")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.refresh(context: modelContext)
            }
            .onChange(of: customers) { _, _ in viewModel.refresh(context: modelContext) }
            .onChange(of: appointments) { _, _ in viewModel.refresh(context: modelContext) }
            .onChange(of: packages) { _, _ in viewModel.refresh(context: modelContext) }
            .onChange(of: invoices) { _, _ in viewModel.refresh(context: modelContext) }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
        .environment(AppState())
}
