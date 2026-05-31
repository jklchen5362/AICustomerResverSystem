//  TreatmentPackageListView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct TreatmentPackageListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TreatmentPackageViewModel()
    @Query private var allPackages: [TreatmentPackage]
    
    @State private var showingForm = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // SearchFilterBar
                SearchFilterBar(
                    searchText: $viewModel.searchText,
                    placeholder: "搜尋療程名稱、客戶姓名...",
                    filters: PackageFilterStatus.allCases.map { status in
                        FilterOption(id: status.rawValue, label: status.rawValue)
                    },
                    selectedFilter: Binding(
                        get: { viewModel.filterStatus.rawValue },
                        set: { viewModel.filterStatus = $0.flatMap(PackageFilterStatus.init(rawValue:)) ?? .all }
                    )
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color.white)
                
                let filtered = viewModel.filteredPackages(allPackages)
                
                if filtered.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "bag.badge.minus",
                            title: "查無療程方案",
                            message: "找不到符合條件的療程包，請更換搜尋詞或新增一筆方案。",
                            actionTitle: "購買新療程"
                        ) {
                            showingForm = true
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filtered) { package in
                            NavigationLink(destination: TreatmentPackageDetailView(package: package)) {
                                TreatmentPackageRowView(package: package)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deletePackage(package, context: modelContext)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("療程方案管理")
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
                TreatmentPackageFormView()
            }
        }
    }
}

// MARK: - Row View
struct TreatmentPackageRowView: View {
    let package: TreatmentPackage
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(package.treatmentName)
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                if isExpiringSoon {
                    Text("即將過期")
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.danger)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.danger.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            HStack {
                Label(package.customer?.fullName ?? "未知客戶", systemImage: "person.fill")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Label(package.purchaseBranch?.name ?? "未指定", systemImage: "building.2.fill")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            SessionProgressBar(used: package.sessionsUsed, total: package.totalSessions)
            
            HStack {
                Text("購買日期: \(package.purchaseDate.formattedDate)")
                    .font(AppTheme.Typography.caption2)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                
                Spacer()
                
                if let exp = package.expirationDate {
                    Text("到期日期: \(exp.formattedDate)")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(isExpired ? AppTheme.Colors.danger : AppTheme.Colors.textSecondary)
                } else {
                    Text("無過期效期")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
    
    private var isExpired: Bool {
        guard let exp = package.expirationDate else { return false }
        return exp <= Date()
    }
    
    private var isExpiringSoon: Bool {
        guard let exp = package.expirationDate else { return false }
        let diff = exp.daysUntil
        return diff >= 0 && diff <= 30 && package.remainingSessions > 0
    }
}

#Preview {
    TreatmentPackageListView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
