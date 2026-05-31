
//  MainTabView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .dashboard
    @State private var animateTabChange = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("儀表板", systemImage: "chart.bar.fill", value: .dashboard) {
                DashboardView()
            }
            
            Tab("客戶", systemImage: "person.2.fill", value: .customers) {
                CustomerListView()
            }
            
            Tab("預約", systemImage: "calendar", value: .appointments) {
                AppointmentCalendarView()
            }
            
            Tab("AI 助理", systemImage: "sparkles", value: .aiAssistant) {
                AIAssistantView()
            }
            
            Tab("更多", systemImage: "ellipsis.circle.fill", value: .more) {
                MoreMenuView()
            }
        }
        .tint(AppTheme.Colors.accent)
        .onChange(of: selectedTab) { _, _ in
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

// MARK: - More Menu View
struct MoreMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        TreatmentPackageListView()
                    } label: {
                        Label("療程方案 Packages", systemImage: "bag.fill")
                    }
                    
                    NavigationLink {
                        ConsumptionListView()
                    } label: {
                        Label("消費記錄 Consumption", systemImage: "list.clipboard.fill")
                    }
                    
                    NavigationLink {
                        BranchListView()
                    } label: {
                        Label("分店管理 Branches", systemImage: "building.2.fill")
                    }
                }
                
                Section {
                    NavigationLink {
                        FinancialDashboardView()
                    } label: {
                        Label("財務管理 Financial", systemImage: "dollarsign.circle.fill")
                    }
                    
                    NavigationLink {
                        ReportsView()
                    } label: {
                        Label("報表 Reports", systemImage: "chart.pie.fill")
                    }
                }
                
                Section {
                    NavigationLink {
                        NotificationCenterView()
                    } label: {
                        Label("通知中心 Notifications", systemImage: "bell.badge.fill")
                    }
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("設定 Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("更多功能")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
        .environment(AppState())
}
