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
        // 1. Check if reminders are disabled
        let leadSeconds = Double(appointment.reminderLeadTimeSeconds)
        guard leadSeconds > 0 else { return }
        
        let content = UNMutableNotificationContent()
        
        let clientName = appointment.customer?.fullName ?? "客戶"
        let branchName = appointment.branch?.name ?? "台北總店"
        let leadText = appointment.reminderLeadTime.displayName
        
        // 2. Configure body text (use custom TTS speech text if available, else generate default elegant message)
        let defaultBody = "親愛的 \(clientName)，提醒您在 \(branchName) 的 \(appointment.treatmentItem) 預約將於 \(leadText) 後 (\(appointment.startTime.formattedTime)) 開始。期待您的光臨！"
        let finalBody = appointment.reminderSpeechText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? defaultBody 
            : appointment.reminderSpeechText
        
        content.title = "📅 專屬預約提醒"
        content.body = finalBody
        
        // 3. Configure Sound type
        switch appointment.reminderSoundType {
        case .systemDefault:
            content.sound = .default
        case .classicChime:
            // Custom sound file. If chime.caf is missing from bundle, iOS automatically falls back to system default.
            content.sound = UNNotificationSound(named: UNNotificationSoundName("chime.caf"))
        case .voiceSpeech:
            content.sound = .default
            // Embed TTS payload into userInfo
            content.userInfo = [
                "speechText": finalBody,
                "speakOnOpen": true,
                "appointmentID": appointment.appointmentID
            ]
        }
        
        // 4. Calculate exact trigger time
        let triggerDate = appointment.startTime.addingTimeInterval(-leadSeconds)
        var leadTime = triggerDate.timeIntervalSinceNow
        
        if leadTime <= 0 {
            // If the calculated trigger time has passed, but the appointment itself is in the future,
            // fire the notification in 2 seconds so the user can test the TTS/chime immediately!
            if appointment.startTime > Date() {
                leadTime = 2.0
            } else {
                return
            }
        }
        
        // Cancel any existing reminder for this appointment first
        cancelNotification(id: "appt-\(appointment.appointmentID)")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: leadTime, repeats: false)
        let request = UNNotificationRequest(identifier: "appt-\(appointment.appointmentID)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule custom appointment local notification: \(error)")
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
