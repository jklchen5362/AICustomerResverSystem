//  AppointmentCardView.swift
//  AICustomerResverSystem

import SwiftUI

struct AppointmentCardView: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Status left vertical accent line
            RoundedRectangle(cornerRadius: 3)
                .fill(appointment.status.color)
                .frame(width: 4, height: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(appointment.customer?.fullName ?? "未知客戶")
                        .font(AppTheme.Typography.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    if let vip = appointment.customer?.vipLevel {
                        VIPBadge(level: vip, compact: true)
                    }
                    
                    Spacer()
                    
                    Text("\(appointment.startTime.formattedTime) - \(appointment.endTime.formattedTime)")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Label(appointment.treatmentItem, systemImage: "sparkles")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 10))
                        Text(appointment.doctor.isEmpty ? "未分派" : appointment.doctor)
                            .font(AppTheme.Typography.caption2)
                        
                        Text("•")
                            .font(.system(size: 10))
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text(appointment.beautician.isEmpty ? "未分派" : appointment.beautician)
                            .font(AppTheme.Typography.caption2)
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Label(appointment.branch?.name ?? "未指定分店", systemImage: "building.2")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    StatusBadge(status: appointment.status, compact: true)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}
