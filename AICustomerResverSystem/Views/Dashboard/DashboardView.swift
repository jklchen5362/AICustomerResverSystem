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
    
    @Query(sort: \Branch.name) private var branches: [Branch]
    @State private var selectedBranchID: PersistentIdentifier? = nil
    @State private var showCustomerDetailSheet = false
    
    @Query private var dutyRosters: [DutyRoster]
    @State private var showDutyRosterForm = false
    
    private var selectedBranchName: String {
        if let branchID = selectedBranchID,
           let branch = branches.first(where: { $0.persistentModelID == branchID }) {
            return branch.name
        }
        return "全部分店"
    }
    
    private var todayRoster: DutyRoster? {
        let start = Date().startOfDay
        let end = Date().endOfDay
        
        if let branchID = selectedBranchID {
            return dutyRosters.first(where: {
                $0.branch?.persistentModelID == branchID &&
                $0.date >= start && $0.date <= end
            })
        } else {
            return dutyRosters.first(where: { $0.date >= start && $0.date <= end })
        }
    }
    
    private func refreshData() {
        let branch = selectedBranchID.flatMap { id in
            branches.first(where: { $0.persistentModelID == id })
        }
        viewModel.refresh(context: modelContext, branch: branch)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Header welcome card
                    DashboardCardView()
                    
                    // Today's Duty Roster Card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(AppTheme.Colors.accent)
                            Text("今日值班人員 On-Duty Staff")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                showDutyRosterForm = true
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "pencil.line")
                                    Text("登錄排班")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.Colors.accent.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.bottom, 2)
                        
                        if let roster = todayRoster,
                           (!roster.onDutyDoctor.isEmpty || !roster.onDutyManager.isEmpty || !roster.onDutyConsultant.isEmpty) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                rosterStaffItem(
                                    role: "值班醫師",
                                    name: roster.onDutyDoctor.isEmpty ? "未安排" : roster.onDutyDoctor,
                                    icon: "stethoscope",
                                    color: AppTheme.Colors.accent
                                )
                                
                                Divider().frame(height: 30)
                                
                                rosterStaffItem(
                                    role: "值班店長",
                                    name: roster.onDutyManager.isEmpty ? "未安排" : roster.onDutyManager,
                                    icon: "shield.checkered",
                                    color: AppTheme.Colors.accentSecondary
                                )
                                
                                Divider().frame(height: 30)
                                
                                rosterStaffItem(
                                    role: "值班諮詢師",
                                    name: roster.onDutyConsultant.isEmpty ? "未安排" : roster.onDutyConsultant,
                                    icon: "person.badge.clock.fill",
                                    color: AppTheme.Colors.info
                                )
                            }
                            .padding(.vertical, 6)
                            
                            if !roster.notes.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 10))
                                    Text("排班備註：\(roster.notes)")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .padding(.top, 2)
                            }
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Text("今日尚未登錄值班人員名單")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                    Text("點選右上角「登錄排班」即可快速設定")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.Colors.textTertiary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                    }
                    
                    // Stats 2x2 grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                        Button {
                            showCustomerDetailSheet = true
                        } label: {
                            StatCard(
                                title: "客戶總數",
                                value: "\(viewModel.totalCustomers)",
                                icon: "person.2.fill",
                                color: AppTheme.Colors.accent,
                                trend: 8.4
                            )
                        }
                        .buttonStyle(.plain)
                        
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            withAnimation(AppTheme.Animations.quick) {
                                selectedBranchID = nil
                            }
                        } label: {
                            HStack {
                                Text("全部分店 (All)")
                                if selectedBranchID == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        ForEach(branches) { branch in
                            Button {
                                withAnimation(AppTheme.Animations.quick) {
                                    selectedBranchID = branch.persistentModelID
                                }
                            } label: {
                                HStack {
                                    Text(branch.name)
                                    if selectedBranchID == branch.persistentModelID {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11))
                            Text(selectedBranchName)
                                .font(.system(size: 11, weight: .bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.Colors.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .onAppear {
                refreshData()
            }
            .onChange(of: selectedBranchID) { _, _ in refreshData() }
            .onChange(of: customers.map { $0.persistentModelID }) { _, _ in refreshData() }
            .onChange(of: appointments.map { "\($0.persistentModelID)-\($0.status.rawValue)-\($0.appointmentDate.timeIntervalSince1970)" }) { _, _ in refreshData() }
            .onChange(of: packages.map { "\($0.persistentModelID)-\($0.remainingSessions)" }) { _, _ in refreshData() }
            .onChange(of: invoices.map { "\($0.persistentModelID)-\($0.amount)" }) { _, _ in refreshData() }
            .onChange(of: dutyRosters.map { "\($0.persistentModelID)-\($0.onDutyDoctor)-\($0.onDutyManager)-\($0.onDutyConsultant)" }) { _, _ in refreshData() }
        }
        .sheet(isPresented: $showCustomerDetailSheet) {
            DashboardCustomerListView(
                selectedBranchID: selectedBranchID,
                selectedBranchName: selectedBranchName
            )
            .modelContext(modelContext)
        }
        .sheet(isPresented: $showDutyRosterForm) {
            DutyRosterFormView(
                activeBranchID: selectedBranchID,
                activeBranchName: selectedBranchName
            )
            .modelContext(modelContext)
        }
    }
    
    private func rosterStaffItem(role: String, name: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(color)
                Text(role)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Text(name)
                .font(AppTheme.Typography.body)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
        .environment(AppState())
}
