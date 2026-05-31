//  CustomerListView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct CustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CustomerViewModel()
    @Query private var allCustomers: [Customer]
    
    @State private var showingForm = false
    @State private var customerToEdit: Customer? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search & Filter Component
                SearchFilterBar(
                    searchText: $viewModel.searchText,
                    placeholder: "搜尋姓名、電話、LINE ID...",
                    filters: VIPLevel.allCases.map { level in
                        FilterOption(
                            id: level.rawValue,
                            label: level.displayName,
                            icon: level == .regular ? "person" : level.icon
                        )
                    },
                    selectedFilter: Binding(
                        get: { viewModel.selectedVIPFilter?.rawValue },
                        set: { viewModel.selectedVIPFilter = $0.flatMap(VIPLevel.init(rawValue:)) }
                    )
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color.white)
                
                let filtered = viewModel.filteredCustomers(allCustomers)
                
                if filtered.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "person.2.slash",
                            title: "沒有找到客戶",
                            message: "請嘗試調整搜尋關鍵字或篩選條件，或直接新增一位客戶。",
                            actionTitle: "新增客戶"
                        ) {
                            showingForm = true
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filtered) { customer in
                            NavigationLink(destination: CustomerDetailView(customer: customer)) {
                                CustomerRowView(customer: customer)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteCustomer(customer, context: modelContext)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                                
                                Button {
                                    customerToEdit = customer
                                } label: {
                                    Label("編輯", systemImage: "pencil")
                                }
                                .tint(AppTheme.Colors.accent)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("客戶管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("排序方式", selection: $viewModel.sortOrder) {
                            ForEach(CustomerSortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label("排序", systemImage: "arrow.up.arrow.down")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                CustomerFormView(customer: nil)
            }
            .sheet(item: $customerToEdit) { customer in
                CustomerFormView(customer: customer)
            }
        }
    }
}

// MARK: - Customer Row View
struct CustomerRowView: View {
    let customer: Customer
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Initial Avatar Circle with VIP Color
            let initials = String(customer.fullName.prefix(2))
            
            Text(initials)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(customer.vipLevel == .gold || customer.vipLevel == .diamond ? .white : AppTheme.Colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(customer.vipLevel.color.opacity(customer.vipLevel == .gold || customer.vipLevel == .diamond ? 1.0 : 0.15))
                )
                .overlay(
                    Circle()
                        .stroke(customer.vipLevel.color.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(customer.fullName)
                        .font(AppTheme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    VIPBadge(level: customer.vipLevel, compact: true)
                }
                
                Text(customer.phone.maskedPhone)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let lastVisit = customer.lastVisitDate {
                    Text("最近來訪")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Text(lastVisit.formattedDate)
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                } else {
                    Text("全新客戶")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.accentSecondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
}

#Preview {
    CustomerListView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
