//  NotificationCenterView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct NotificationCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NotificationViewModel()
    @Query(sort: \AppNotification.scheduledDate, order: .reverse) private var allNotifications: [AppNotification]
    
    var body: some View {
        VStack(spacing: 0) {
            // Horizontal Type Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    FilterChip(
                        label: "全部通知",
                        icon: "bell.fill",
                        isSelected: viewModel.selectedTypeFilter == nil
                    ) {
                        withAnimation(AppTheme.Animations.quick) {
                            viewModel.selectedTypeFilter = nil
                        }
                    }
                    
                    ForEach(NotificationType.allCases) { type in
                        FilterChip(
                            label: type.displayName,
                            icon: type.icon,
                            isSelected: viewModel.selectedTypeFilter == type
                        ) {
                            withAnimation(AppTheme.Animations.quick) {
                                viewModel.selectedTypeFilter = type
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .background(Color.white)
            
            let filtered = viewModel.filteredNotifications(allNotifications)
            
            if filtered.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "尚無通知提醒",
                        message: "目前系統中無任何預約提醒、生日祝福或核銷系統警報。"
                    )
                    Spacer()
                }
            } else {
                List {
                    ForEach(filtered) { notification in
                        NotificationRow(notification: notification)
                            .listRowSeparator(.visible)
                            .swipeActions(edge: .leading) {
                                if !notification.isRead {
                                    Button {
                                        viewModel.markAsRead(notification, context: modelContext)
                                    } label: {
                                        Label("標示已讀", systemImage: "checkmark.circle")
                                    }
                                    .tint(AppTheme.Colors.success)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteNotification(notification, context: modelContext)
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
        .navigationTitle("通知中心")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let unread = viewModel.unreadCount(notifications: allNotifications)
                if unread > 0 {
                    Button("全部標示已讀") {
                        viewModel.markAllAsRead(notifications: allNotifications, context: modelContext)
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.accent)
                }
            }
        }
    }
}

// MARK: - Row Component
struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            // Icon Background
            let type = notification.type
            
            Image(systemName: type.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(type.color)
                .frame(width: 36, height: 36)
                .background(type.color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(AppTheme.Typography.callout)
                        .fontWeight(notification.isRead ? .regular : .bold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(timeAgoString(notification.scheduledDate))
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                
                Text(notification.message)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if let customer = notification.customer {
                    HStack(spacing: 2) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 10))
                        Text(customer.fullName)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.accent.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.top, 2)
                }
            }
            
            // Unread Dot
            if !notification.isRead {
                Circle()
                    .fill(AppTheme.Colors.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
        .opacity(notification.isRead ? 0.75 : 1.0)
    }
    
    private func timeAgoString(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "剛才" }
        let mins = Int(diff / 60)
        if mins < 60 { return "\(mins) 分鐘前" }
        let hours = Int(mins / 60)
        if hours < 24 { return "\(hours) 小時前" }
        let days = Int(hours / 24)
        if days < 7 { return "\(days) 天前" }
        return date.formattedDate
    }
}

#Preview {
    NavigationStack {
        NotificationCenterView()
    }
    .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
