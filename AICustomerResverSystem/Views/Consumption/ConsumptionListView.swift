//  ConsumptionListView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct ConsumptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ConsumptionViewModel()
    @Query(sort: \ConsumptionRecord.date, order: .reverse) private var allRecords: [ConsumptionRecord]
    
    @State private var showingForm = false
    
    var filteredRecords: [ConsumptionRecord] {
        if viewModel.searchText.isEmpty {
            return allRecords
        } else {
            return allRecords.filter { record in
                record.treatmentName.localizedCaseInsensitiveContains(viewModel.searchText) ||
                (record.customer?.fullName.localizedCaseInsensitiveContains(viewModel.searchText) ?? false) ||
                record.operatorName.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchFilterBar(
                    searchText: $viewModel.searchText,
                    placeholder: "搜尋客戶姓名、療程、核銷人...",
                    filters: [],
                    selectedFilter: .constant(nil)
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color.white)
                
                if filteredRecords.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "list.bullet.rectangle.portrait",
                            title: "無核銷扣堂記錄",
                            message: "目前系統中無任何客戶療程的扣堂扣會記錄。",
                            actionTitle: "登記扣堂"
                        ) {
                            showingForm = true
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            ConsumptionRecordRow(record: record)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteRecord(record, context: modelContext)
                                    } label: {
                                        Label("撤銷", systemImage: "arrow.uturn.backward")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("核銷扣堂歷史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                ConsumptionFormView()
            }
        }
    }
}

// MARK: - Row View
struct ConsumptionRecordRow: View {
    let record: ConsumptionRecord
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.customer?.fullName ?? "未知客戶")
                        .font(AppTheme.Typography.callout)
                        .fontWeight(.bold)
                    
                    if let vip = record.customer?.vipLevel {
                        VIPBadge(level: vip, compact: true)
                    }
                }
                
                Text(record.treatmentName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                HStack(spacing: 8) {
                    Text("核銷: \(record.operatorName)")
                    Text("•")
                    Text("分店: \(record.branch?.name ?? "台北總店")")
                }
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("-\(record.sessionsConsumed) 堂")
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.danger)
                
                Text(record.date.formattedDate)
                    .font(AppTheme.Typography.caption2)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
}

#Preview {
    ConsumptionListView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
