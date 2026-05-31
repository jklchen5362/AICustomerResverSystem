
//  StatusBadge.swift
//  AICustomerResverSystem

import SwiftUI

struct StatusBadge: View {
    let status: AppointmentStatus
    var compact: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            
            Text(compact ? status.shortName : status.displayName)
                .font(compact ? AppTheme.Typography.caption2 : AppTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - VIP Badge
struct VIPBadge: View {
    let level: VIPLevel
    var compact: Bool = false
    
    var body: some View {
        if level != .regular {
            HStack(spacing: 3) {
                Image(systemName: level.icon)
                    .font(.system(size: compact ? 8 : 10, weight: .bold))
                
                if !compact {
                    Text(level.displayName)
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(level == .gold || level == .diamond ? .white : AppTheme.Colors.textPrimary)
            .padding(.horizontal, compact ? 5 : 8)
            .padding(.vertical, compact ? 2 : 4)
            .background(level.color.opacity(level == .gold || level == .diamond ? 1.0 : 0.2))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Payment Badge
struct PaymentBadge: View {
    let method: PaymentMethod
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: method.icon)
                .font(.system(size: 10))
            Text(method.displayName)
                .font(AppTheme.Typography.caption2)
        }
        .foregroundStyle(AppTheme.Colors.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(AppTheme.Colors.textSecondary.opacity(0.08))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(AppointmentStatus.allCases) { status in
            StatusBadge(status: status)
        }
        Divider()
        ForEach(VIPLevel.allCases) { level in
            VIPBadge(level: level)
        }
    }
    .padding()
}
