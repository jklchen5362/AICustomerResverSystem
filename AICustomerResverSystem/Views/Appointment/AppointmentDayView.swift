//  AppointmentDayView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct AppointmentDayView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: Date
    let appointments: [Appointment]
    
    @State private var appointmentToEdit: Appointment? = nil
    
    var filteredAppointments: [Appointment] {
        let start = selectedDate.startOfDay
        let end = selectedDate.endOfDay
        return appointments.filter { $0.appointmentDate >= start && $0.appointmentDate <= end }
            .sorted(by: { $0.startTime < $1.startTime })
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Day date display header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formattedWeekday)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.accent)
                    
                    Text(selectedDate.formattedDate)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                
                Spacer()
                
                Text("\(filteredAppointments.count) 筆預約")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
            
            if filteredAppointments.isEmpty {
                VStack {
                    Spacer().frame(height: 40)
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "本日無預約",
                        message: "此日尚無登記任何客戶預約。可以點選右上角的新增按鈕來新增預約行程。"
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(filteredAppointments) { appointment in
                            AppointmentCardView(appointment: appointment)
                                .onTapGesture {
                                    appointmentToEdit = appointment
                                }
                                .contextMenu {
                                    Button {
                                        appointmentToEdit = appointment
                                    } label: {
                                        Label("編輯預約", systemImage: "pencil")
                                    }
                                    
                                    Menu("變更狀態") {
                                        ForEach(AppointmentStatus.allCases) { status in
                                            Button {
                                                appointment.status = status
                                                try? modelContext.save()
                                            } label: {
                                                HStack {
                                                    if appointment.status == status {
                                                        Image(systemName: "checkmark")
                                                    }
                                                    Text(status.displayName)
                                                }
                                            }
                                        }
                                    }
                                    
                                    Button(role: .destructive) {
                                        modelContext.delete(appointment)
                                        try? modelContext.save()
                                    } label: {
                                        Label("取消/刪除預約", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .sheet(item: $appointmentToEdit) { appt in
            AppointmentFormView(appointment: appt)
        }
    }
}
