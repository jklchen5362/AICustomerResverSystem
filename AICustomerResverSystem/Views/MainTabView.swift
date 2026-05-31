
//  MainTabView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .dashboard
    @State private var animateTabChange = false
    
    var body: some View {
        Group {
            if !appState.hasLoadedSampleData {
                // Premium Clinic-Luxury Splash / Database Loading Screen
                ZStack {
                    AppTheme.Colors.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Spacer()
                        
                        // Golden sparkly logo
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accent.opacity(0.12))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.accent, AppTheme.Colors.accentLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .scaleEffect(animateTabChange ? 1.05 : 0.95)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                animateTabChange = true
                            }
                        }
                        
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("極致美學 CRM 系統")
                                .font(AppTheme.Typography.title)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .tracking(2)
                            
                            Text("Aesthetic CRM & Reservation")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            ProgressView()
                                .tint(AppTheme.Colors.accent)
                                .controlSize(.large)
                            
                            Text("美學資料庫載入中...")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        .padding(.bottom, 60)
                    }
                }
            } else {
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
