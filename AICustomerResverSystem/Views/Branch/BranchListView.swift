//  BranchListView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct BranchListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BranchViewModel()
    @Query(sort: \Branch.name) private var branches: [Branch]
    
    @State private var showingForm = false
    @State private var branchToEdit: Branch? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    if branches.isEmpty {
                        EmptyStateView(
                            icon: "building.2.fill",
                            title: "尚無分店據點",
                            message: "目前系統中無註冊任何醫美分店，請新增據點以開啟營運管理。",
                            actionTitle: "新增分店"
                        ) {
                            showingForm = true
                        }
                    } else {
                        ForEach(branches) { branch in
                            BranchCard(branch: branch)
                                .onTapGesture {
                                    branchToEdit = branch
                                }
                                .contextMenu {
                                    Button {
                                        branchToEdit = branch
                                    } label: {
                                        Label("編輯資料", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        viewModel.deleteBranch(branch, context: modelContext)
                                    } label: {
                                        Label("刪除分店", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("分店管理")
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
                BranchFormView(branch: nil)
            }
            .sheet(item: $branchToEdit) { branch in
                BranchFormView(branch: branch)
            }
        }
    }
}

// MARK: - Branch Card
struct BranchCard: View {
    let branch: Branch
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(branch.name)
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.Colors.success)
                        .frame(width: 6, height: 6)
                    Text("營運中")
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.success)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.15))
                .clipShape(Capsule())
            }
            
            Divider().background(.white.opacity(0.2))
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Label("負責人: \(branch.manager)", systemImage: "person.circle.fill")
                Label("電話: \(branch.phone)", systemImage: "phone.fill")
                Label("地址: \(branch.address)", systemImage: "mappin.and.ellipse")
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.white.opacity(0.85))
            
            HStack(spacing: AppTheme.Spacing.md) {
                Spacer()
                
                let apptsCount = branch.appointments.filter({ $0.appointmentDate.isToday && $0.status != .cancelled }).count
                Text("今日預約: \(apptsCount) 堂")
                    .font(AppTheme.Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    BranchListView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
