//  AppointmentViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day = "單日 Day"
    case week = "週視圖 Week"
    case month = "月視圖 Month"
    
    var id: String { rawValue }
}

@Observable
class AppointmentViewModel {
    var selectedDate: Date = Date()
    var viewMode: CalendarViewMode = .month
    
    init() {}
    
    func appointmentsForDate(_ date: Date, appointments: [Appointment]) -> [Appointment] {
        let start = date.startOfDay
        let end = date.endOfDay
        return appointments.filter { $0.appointmentDate >= start && $0.appointmentDate <= end }
            .sorted(by: { $0.startTime < $1.startTime })
    }
    
    func appointmentsForWeek(_ date: Date, appointments: [Appointment]) -> [Date: [Appointment]] {
        var dict: [Date: [Appointment]] = [:]
        let weekDates = weekDatesFor(date)
        
        for wDate in weekDates {
            let dayAppts = appointmentsForDate(wDate, appointments: appointments)
            dict[wDate.startOfDay] = dayAppts
        }
        
        return dict
    }
    
    func weekDatesFor(_ date: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        
        // Find Sunday of this week
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return []
        }
        
        for i in 0..<7 {
            if let nextDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(nextDate)
            }
        }
        
        return dates
    }
    
    // Monthly grid dates helper (includes preceding and succeeding month padding to form perfect 6x7 grid)
    func monthGridDatesFor(_ date: Date) -> [Date] {
        let calendar = Calendar.current
        
        // Start of month
        let startOfMonth = date.startOfMonth
        
        // Weekday index of start of month (1 = Sunday, 2 = Monday, etc.)
        let weekday = calendar.component(.weekday, from: startOfMonth)
        
        // Number of preceding days to pad
        let paddingDays = weekday - 1
        
        // Start of the grid
        guard let gridStart = calendar.date(byAdding: .day, value: -paddingDays, to: startOfMonth) else {
            return []
        }
        
        var dates: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let nextDate = calendar.date(byAdding: .day, value: i, to: gridStart) {
                dates.append(nextDate)
            }
        }
        
        return dates
    }
    
    @MainActor
    func updateStatus(_ appointment: Appointment, to status: AppointmentStatus, context: ModelContext) {
        appointment.status = status
        try? context.save()
        
        // If appointment completed, trigger system follow up notification in 3 days
        if status == .completed, let customer = appointment.customer {
            let followUpDate = Date().adding(days: 3)
            let followUpNotif = AppNotification(
                type: .followUpReminder,
                title: "回訪問候通知",
                message: "客戶 \(customer.fullName) 於 3 天前完成了 \(appointment.treatmentItem) 療程，建議今日進行電話或 LINE 關懷膚質狀況與滿意度。",
                scheduledDate: followUpDate
            )
            followUpNotif.customer = customer
            context.insert(followUpNotif)
            try? context.save()
        }
    }
    
    @MainActor
    func deleteAppointment(_ appointment: Appointment, context: ModelContext) {
        context.delete(appointment)
        try? context.save()
    }
}
