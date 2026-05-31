//  DashboardCustomerListView.swift
//  AICustomerResverSystem
//

import SwiftUI
import SwiftData

struct DashboardCustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedBranchID: PersistentIdentifier?
    let selectedBranchName: String
    
    @Query(sort: \Customer.fullName) private var allCustomers: [Customer]
    @Query private var branches: [Branch]
    
    @State private var searchText = ""
    @State private var dummyFilter: String? = nil
    
    // Compute filtered list based on active dashboard branch & search text
    private var filteredCustomers: [Customer] {
        var result = allCustomers
        
        // 1. Scoped by branch
        if let branchID = selectedBranchID {
            result = allCustomers.filter { customer in
                customer.appointments.contains(where: { $0.branch?.persistentModelID == branchID }) ||
                customer.packages.contains(where: { $0.purchaseBranch?.persistentModelID == branchID }) ||
                customer.invoices.contains(where: { $0.branch?.persistentModelID == branchID })
            }
        }
        
        // 2. Filtered by search text
        if !searchText.isEmpty {
            result = result.filter { customer in
                customer.fullName.localizedCaseInsensitiveContains(searchText) ||
                customer.phone.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchFilterBar(searchText: $searchText, placeholder: "搜尋客戶姓名或電話...", selectedFilter: $dummyFilter)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                
                if filteredCustomers.isEmpty {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        Text(searchText.isEmpty ? "此分店目前暫無客戶資料" : "無相符搜尋結果")
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredCustomers) { customer in
                            DashboardCustomerRow(customer: customer)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("分店客戶清單 (\(selectedBranchName))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Customer Row Component

struct DashboardCustomerRow: View {
    let customer: Customer
    
    // Sum all remaining sessions across treatment packages
    private var totalRemainingSessions: Int {
        customer.packages.reduce(0) { $0 + $1.remainingSessions }
    }
    
    // Retrieve nearest upcoming appointment
    private var nextAppointment: Appointment? {
        let today = Date().startOfDay
        return customer.appointments
            .filter { $0.appointmentDate >= today && $0.status == .confirmed }
            .sorted(by: { $0.startTime < $1.startTime })
            .first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Customer Header Info
            HStack {
                Text(customer.fullName)
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                VIPBadge(level: customer.vipLevel, compact: true)
                
                Spacer()
                
                // Active Sessions Count Capsule
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 10))
                    Text("剩餘 \(totalRemainingSessions) 堂")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(totalRemainingSessions > 0 ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (totalRemainingSessions > 0 ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary).opacity(0.12)
                )
                .clipShape(Capsule())
            }
            
            Divider()
                .opacity(0.4)
            
            // Sub-details (Phone & Next Appointment)
            VStack(spacing: 6) {
                HStack {
                    Label(customer.phone, systemImage: "phone.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Spacer()
                }
                
                HStack {
                    if let appt = nextAppointment {
                        Label(
                            "下次預約：\(appt.appointmentDate.formattedDate) \(appt.startTime.formattedTime)",
                            systemImage: "calendar"
                        )
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                    } else {
                        Label("暫無預約", systemImage: "calendar.badge.clock")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                    Spacer()
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 3)
    }
}
