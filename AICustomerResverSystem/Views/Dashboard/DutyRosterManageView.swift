//  DutyRosterManageView.swift
//  AICustomerResverSystem
//

import SwiftUI
import SwiftData

struct DutyRosterManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let activeBranchID: PersistentIdentifier?
    let activeBranchName: String
    
    @Query(sort: \DutyRoster.date) private var allRosters: [DutyRoster]
    @Query(sort: \Branch.name) private var branches: [Branch]
    
    @State private var searchText = ""
    @State private var filterMode: RosterFilterMode = .all
    @State private var selectedDateForForm: DateHolder? = nil
    
    enum RosterFilterMode: String, CaseIterable, Identifiable {
        case all = "全部日程"
        case scheduled = "已排妥"
        case unscheduled = "待排班"
        
        var id: String { self.rawValue }
    }
    
    // Compute 180 days list starting from today's start of day
    private var futureDates: [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<180).compactMap { days in
            calendar.date(byAdding: .day, value: days, to: today)
        }
    }
    
    // Scoped rosters matching the selected branch
    private var branchRosters: [DutyRoster] {
        guard let branchID = activeBranchID else { return allRosters }
        return allRosters.filter { $0.branch?.persistentModelID == branchID }
    }
    
    // Helper to find a roster for a specific date
    private func rosterForDate(_ date: Date) -> DutyRoster? {
        let start = date.startOfDay
        let end = date.endOfDay
        return branchRosters.first(where: { $0.date >= start && $0.date <= end })
    }
    
    // Grid or List filtered results
    struct RosterDateItem: Identifiable {
        let id = UUID()
        let date: Date
        let roster: DutyRoster?
    }
    
    private var filteredItems: [RosterDateItem] {
        let rawItems = futureDates.map { date in
            RosterDateItem(date: date, roster: rosterForDate(date))
        }
        
        return rawItems.filter { item in
            // 1. Filter by Status Mode
            switch filterMode {
            case .all:
                break
            case .scheduled:
                if item.roster == nil { return false }
            case .unscheduled:
                if item.roster != nil { return false }
            }
            
            // 2. Filter by Search Query
            if !searchText.isEmpty {
                guard let roster = item.roster else { return false }
                let doctorsMatch = roster.onDutyDoctors.contains { $0.localizedCaseInsensitiveContains(searchText) }
                let managersMatch = roster.onDutyManagers.contains { $0.localizedCaseInsensitiveContains(searchText) }
                let consultantsMatch = roster.onDutyConsultants.contains { $0.localizedCaseInsensitiveContains(searchText) }
                let notesMatch = roster.notes.localizedCaseInsensitiveContains(searchText)
                return doctorsMatch || managersMatch || consultantsMatch || notesMatch
            }
            
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeBranchName)
                            .font(AppTheme.Typography.title3)
                            .foregroundStyle(AppTheme.Colors.accent)
                            .fontWeight(.bold)
                        Text("預計排班主控台 • 規劃半年內值班人員")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.background)
                
                // Search Bar & Filter Controls
                VStack(spacing: AppTheme.Spacing.sm) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        TextField("搜尋值班醫師/店長/諮詢師...", text: $searchText)
                            .font(AppTheme.Typography.body)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .stroke(AppTheme.Colors.textTertiary.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Filter Mode Picker
                    Picker("排班狀態", selection: $filterMode) {
                        ForEach(RosterFilterMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.md)
                .background(AppTheme.Colors.background)
                
                // Dates List
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.sm) {
                        if filteredItems.isEmpty {
                            VStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                                Text("無相符的值班日程資料")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(filteredItems) { item in
                                rosterRow(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .background(AppTheme.Colors.background)
            }
            .navigationTitle("未來 180 天排班規劃")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .sheet(item: $selectedDateForForm) { dateHolder in
                DutyRosterFormView(
                    activeBranchID: activeBranchID,
                    activeBranchName: activeBranchName,
                    initialDate: dateHolder.date
                )
                .modelContext(modelContext)
            }
        }
    }
    
    // MARK: - Row Components
    
    private func rosterRow(item: RosterDateItem) -> some View {
        Button {
            selectedDateForForm = DateHolder(date: item.date)
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Left side: Date Block
                VStack(spacing: 2) {
                    Text(item.date.formattedDay)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(isWeekend(item.date) ? AppTheme.Colors.accent : AppTheme.Colors.primary)
                    Text(item.date.formattedWeekday)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(isWeekend(item.date) ? AppTheme.Colors.accent.opacity(0.8) : AppTheme.Colors.textSecondary)
                    Text(item.date.formattedMonth)
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .frame(width: 55, height: 65)
                .background(isWeekend(item.date) ? AppTheme.Colors.accent.opacity(0.08) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
                
                // Middle/Right side: Staff listings or empty trigger
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    if let roster = item.roster,
                       (!roster.onDutyDoctors.isEmpty || !roster.onDutyManagers.isEmpty || !roster.onDutyConsultants.isEmpty) {
                        // Managers list
                        if !roster.onDutyManagers.isEmpty {
                            badgeStaffList(role: "店長/副店", names: roster.onDutyManagers, icon: "shield.checkered", color: AppTheme.Colors.accentSecondary)
                        }
                        
                        // Doctors list
                        if !roster.onDutyDoctors.isEmpty {
                            badgeStaffList(role: "值班醫師", names: roster.onDutyDoctors, icon: "stethoscope", color: AppTheme.Colors.accent)
                        }
                        
                        // Consultants list
                        if !roster.onDutyConsultants.isEmpty {
                            badgeStaffList(role: "諮詢師", names: roster.onDutyConsultants, icon: "person.badge.clock.fill", color: AppTheme.Colors.info)
                        }
                        
                        // Remarks Notes
                        if !roster.notes.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 9))
                                Text(roster.notes)
                                    .font(AppTheme.Typography.footnote)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                            .padding(.top, 2)
                        }
                    } else {
                        // Unscheduled Placeholder
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.Colors.warning)
                                Text("尚未登錄排班")
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.Colors.warning)
                            }
                            Text("點擊進行快速排班規劃")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Action Arrow or status dot
                Image(systemName: item.roster == nil ? "plus.circle.fill" : "chevron.right")
                    .font(.system(size: item.roster == nil ? 18 : 12))
                    .foregroundStyle(item.roster == nil ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.sm)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .shadow(
                color: AppTheme.Shadows.card.color,
                radius: AppTheme.Shadows.card.radius,
                x: AppTheme.Shadows.card.x,
                y: AppTheme.Shadows.card.y
            )
        }
        .buttonStyle(.plain)
    }
    
    private func badgeStaffList(role: String, names: [String], icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(role)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text(names.joined(separator: "、"))
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Helpers
    
    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // 1 is Sunday, 7 is Saturday
    }
}

// Helper Identifiable Date structure for Sheet presentation
struct DateHolder: Identifiable {
    let id = UUID()
    let date: Date
}

// MARK: - Date Formatting Extensions Scoped locally
private extension Date {
    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: self)
    }
}
