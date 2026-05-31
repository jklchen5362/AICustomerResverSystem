//  NotificationService.swift
//  AICustomerResverSystem

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("Failed to request push notifications authorization: \(error)")
            return false
        }
    }
    
    func scheduleAppointmentReminder(for appointment: Appointment) {
        let content = UNMutableNotificationContent()
        content.title = "📅 明日預約提醒"
        
        let clientName = appointment.customer?.fullName ?? "客戶"
        let branchName = appointment.branch?.name ?? "台北總店"
        content.body = "親愛的 \(clientName)，提醒您明日有登記 \(appointment.treatmentItem) 療程於 \(branchName) \(appointment.startTime.formattedTime)。期待您的光臨！"
        content.sound = .default
        
        // Trigger 24 hours before appointment
        let triggerDate = appointment.startTime.addingTimeInterval(-86400)
        let leadTime = triggerDate.timeIntervalSinceNow
        
        guard leadTime > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: leadTime, repeats: false)
        let request = UNNotificationRequest(identifier: "appt-\(appointment.appointmentID)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule appointment local notification: \(error)")
            }
        }
    }
    
    func scheduleExpirationWarning(for package: TreatmentPackage) {
        guard let exp = package.expirationDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ 療程合約即將到期提醒"
        
        let clientName = package.customer?.fullName ?? "客戶"
        content.body = "客戶 \(clientName) 的 \(package.treatmentName) 療程將於 30 天後 (\(exp.formattedDate)) 過期，目前尚有 \(package.remainingSessions) 堂未核銷，請提醒客戶預約扣堂。"
        content.sound = .default
        
        // Trigger 30 days before expiration date
        let triggerDate = exp.addingTimeInterval(-30 * 86400)
        let leadTime = triggerDate.timeIntervalSinceNow
        
        guard leadTime > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: leadTime, repeats: false)
        let request = UNNotificationRequest(identifier: "pkg-\(package.packageID)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule package expiration local notification: \(error)")
            }
        }
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
