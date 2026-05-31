//  AppointmentWeekView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct AppointmentWeekView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: Date
    let appointments: [Appointment]
    
    @State private var appointmentToEdit: Appointment? = nil
    
    private var weekDates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        
        // Find Sunday of selected week
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        guard let startOfWeek = calendar.date(from: components) else {
            return []
        }
        
        for i in 0..<7 {
            if let nextDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(nextDate)
            }
        }
        return dates
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Horizontal Week Days Strip
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = date.isToday
                    
                    VStack(spacing: 6) {
                        Text(weekdayAbbreviated(date))
                            .font(AppTheme.Typography.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
                        
                        Text(dateComponents(date))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isSelected ? .white : (isToday ? AppTheme.Colors.accent : AppTheme.Colors.textPrimary))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isSelected ? AppTheme.Colors.accent : (isToday ? AppTheme.Colors.accent.opacity(0.12) : Color.clear))
                            )
                        
                        // Count dots
                        let dayAppts = appointmentsFor(date)
                        HStack(spacing: 2) {
                            ForEach(Array(dayAppts.prefix(3).enumerated()), id: \.offset) { _, appt in
                                Circle()
                                    .fill(isSelected ? .white : appt.status.color)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(isSelected ? AppTheme.Colors.primary : Color.clear)
                    )
                    .onTapGesture {
                        withAnimation(AppTheme.Animations.quick) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
            .padding(.horizontal, AppTheme.Spacing.md)
            
            // Week agenda for the selected day
            AppointmentDayView(selectedDate: $selectedDate, appointments: appointments)
        }
    }
    
    private func weekdayAbbreviated(_ date: Date) -> String {
        let calendar = Calendar.current
        let idx = calendar.component(.weekday, from: date)
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        return weekdays[idx - 1]
    }
    
    private func dateComponents(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func appointmentsFor(_ date: Date) -> [Appointment] {
        let start = date.startOfDay
        let end = date.endOfDay
        return appointments.filter { $0.appointmentDate >= start && $0.appointmentDate <= end && $0.status != .cancelled }
    }
}
