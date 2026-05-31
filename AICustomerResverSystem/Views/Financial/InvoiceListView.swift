//  InvoiceListView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct InvoiceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Invoice.purchaseDate, order: .reverse) private var invoices: [Invoice]
    
    @State private var searchText = ""
    @State private var selectedMethod: PaymentMethod? = nil
    
    var filteredInvoices: [Invoice] {
        var results = invoices
        
        // Search
        if !searchText.isEmpty {
            results = results.filter { invoice in
                invoice.packageName.localizedCaseInsensitiveContains(searchText) ||
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                (invoice.customer?.fullName.localizedCaseInsensitiveContains(searchText) ?? false) ||
                invoice.salesConsultant.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Payment method filter
        if let method = selectedMethod {
            results = results.filter { $0.paymentMethod == method }
        }
        
        return results
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search filter bar
            SearchFilterBar(
                searchText: $searchText,
                placeholder: "搜尋發票號、療程、客戶、顧問...",
                filters: PaymentMethod.allCases.map { method in
                    FilterOption(id: method.rawValue, label: method.displayName, icon: method.icon)
                },
                selectedFilter: Binding(
                    get: { selectedMethod?.rawValue },
                    set: { selectedMethod = $0.flatMap(PaymentMethod.init(rawValue:)) }
                )
            )
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.white)
            
            if filteredInvoices.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "查無發票紀錄",
                        message: "找不到符合條件的交易發票項目，請嘗試調整篩選條件。"
                    )
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredInvoices) { invoice in
                        InvoiceRow(invoice: invoice)
                    }
                }
                .listStyle(.plain)
                
                // Summary Footer
                let totalAmount = filteredInvoices.reduce(0.0) { $0 + $1.amount }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("當前篩選累計交易數")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Text("\(filteredInvoices.count) 筆交易")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("實收累計營業額")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Text(totalAmount.formattedCurrency)
                            .font(AppTheme.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("交易發票管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Row View
struct InvoiceRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(invoice.customer?.fullName ?? "未知客戶")
                        .font(AppTheme.Typography.callout)
                        .fontWeight(.bold)
                    
                    if let vip = invoice.customer?.vipLevel {
                        VIPBadge(level: vip, compact: true)
                    }
                }
                
                Text(invoice.packageName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                HStack(spacing: 8) {
                    Text(invoice.invoiceNumber)
                    Text("•")
                    Text(invoice.branch?.name ?? "台北店")
                }
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(invoice.amount.formattedCurrency)
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.accent)
                
                PaymentBadge(method: invoice.paymentMethod)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
}

#Preview {
    InvoiceListView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
