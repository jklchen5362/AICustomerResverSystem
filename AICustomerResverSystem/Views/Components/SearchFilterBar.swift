
//  SearchFilterBar.swift
//  AICustomerResverSystem

import SwiftUI

struct SearchFilterBar: View {
    @Binding var searchText: String
    var placeholder: String = "搜尋 Search..."
    var filters: [FilterOption] = []
    @Binding var selectedFilter: String?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Search bar
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField(placeholder, text: $searchText)
                    .font(AppTheme.Typography.body)
                    .focused($isFocused)
                
                if !searchText.isEmpty {
                    Button {
                        withAnimation(AppTheme.Animations.quick) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                    .fill(Color(.systemGray6))
            )
            
            // Filter chips
            if !filters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(filters) { filter in
                            FilterChip(
                                label: filter.label,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter.id
                            ) {
                                withAnimation(AppTheme.Animations.quick) {
                                    if selectedFilter == filter.id {
                                        selectedFilter = nil
                                    } else {
                                        selectedFilter = filter.id
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FilterOption: Identifiable {
    let id: String
    let label: String
    var icon: String? = nil
}

struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.Colors.accent : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(AppTheme.Spacing.xxl)
    }
}

// MARK: - Loading View
struct LoadingOverlay: View {
    var message: String = "載入中..."
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppTheme.Colors.accent)
                
                Text(message)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.xl)
            .glassCard()
        }
    }
}

#Preview {
    VStack {
        SearchFilterBar(
            searchText: .constant(""),
            filters: [
                FilterOption(id: "vip", label: "VIP", icon: "crown.fill"),
                FilterOption(id: "recent", label: "最近", icon: "clock"),
                FilterOption(id: "active", label: "活躍", icon: "checkmark.circle"),
            ],
            selectedFilter: .constant("vip")
        )
        .padding()
        
        Spacer()
        
        EmptyStateView(
            icon: "person.2.slash",
            title: "沒有客戶",
            message: "點擊下方按鈕新增第一位客戶",
            actionTitle: "新增客戶"
        ) { }
    }
}
