//  AppointmentFormView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct AppointmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let appointment: Appointment?
    
    @Query(sort: \Customer.fullName) private var customers: [Customer]
    @Query(sort: \Branch.name) private var branches: [Branch]
    
    // Form fields
    @State private var selectedCustomerID: PersistentIdentifier? = nil
    @State private var selectedBranchID: PersistentIdentifier? = nil
    @State private var treatmentItem = ""
    @State private var doctor = ""
    @State private var beautician = ""
    @State private var appointmentDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // Default 1 hour
    @State private var status: AppointmentStatus = .confirmed
    @State private var notes = ""
    
    // Reminder options
    @State private var reminderLeadTime: ReminderLeadTime = .oneHour
    @State private var reminderSoundType: ReminderSoundType = .systemDefault
    @State private var reminderSpeechText = ""
    
    // Validation alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var isEditMode: Bool {
        appointment != nil
    }
    
    private func generateDefaultSpeechText() {
        let clientName = customers.first(where: { $0.persistentModelID == selectedCustomerID })?.fullName ?? "貴賓"
        let branchName = branches.first(where: { $0.persistentModelID == selectedBranchID })?.name ?? "分店"
        let leadText = reminderLeadTime.displayName
        reminderSpeechText = "親愛的 \(clientName) 您好，提醒您預訂在 \(branchName) 的 \(treatmentItem.isEmpty ? "療程" : treatmentItem) 將於\(leadText)後開始，我們非常期待與您見面。"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("選擇客戶與分店 Customer & Location") {
                    Picker("預約客戶 Customer *", selection: $selectedCustomerID) {
                        Text("請選擇客戶").tag(nil as PersistentIdentifier?)
                        ForEach(customers) { customer in
                            Text(customer.fullName).tag(customer.persistentModelID as PersistentIdentifier?)
                        }
                    }
                    .disabled(isEditMode) // Lock customer on edit
                    .onChange(of: selectedCustomerID) { _, _ in generateDefaultSpeechText() }
                    
                    Picker("預約分店 Branch *", selection: $selectedBranchID) {
                        Text("請選擇分店").tag(nil as PersistentIdentifier?)
                        ForEach(branches) { branch in
                            Text(branch.name).tag(branch.persistentModelID as PersistentIdentifier?)
                        }
                    }
                    .onChange(of: selectedBranchID) { _, _ in generateDefaultSpeechText() }
                }
                
                Section("療程與服務人員 Treatment & Staff") {
                    TextField("療程項目 Treatment *", text: $treatmentItem)
                        .textInputAutocapitalization(.words)
                        .onChange(of: treatmentItem) { _, _ in generateDefaultSpeechText() }
                    
                    TextField("主治醫師 Doctor", text: $doctor)
                        .textInputAutocapitalization(.words)
                    
                    TextField("服務美容師 Beautician", text: $beautician)
                        .textInputAutocapitalization(.words)
                }
                
                Section("預約時間與狀態 Date & Time") {
                    DatePicker("預約日期 Date", selection: $appointmentDate, displayedComponents: .date)
                    
                    DatePicker("開始時間 Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("結束時間 End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    if isEditMode {
                        Picker("預約狀態 Status", selection: $status) {
                            ForEach(AppointmentStatus.allCases) { stat in
                                Text(stat.displayName).tag(stat)
                            }
                        }
                    }
                }
                
                Section("提醒與語音設定 Reminders & Voice") {
                    Picker("提醒時間 Reminder Offset", selection: $reminderLeadTime) {
                        ForEach(ReminderLeadTime.allCases) { time in
                            Text(time.displayName).tag(time)
                        }
                    }
                    .onChange(of: reminderLeadTime) { _, _ in generateDefaultSpeechText() }
                    
                    if reminderLeadTime != .none {
                        Picker("提示音效 Ringtone Style", selection: $reminderSoundType) {
                            ForEach(ReminderSoundType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        if reminderSoundType == .voiceSpeech {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("語音唸讀文字 Speech Text")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                
                                HStack(spacing: 8) {
                                    TextField("請輸入要唸讀的提醒內容", text: $reminderSpeechText)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Button {
                                        if SpeechService.shared.isPlaying {
                                            SpeechService.shared.stop()
                                        } else {
                                            SpeechService.shared.speak(reminderSpeechText)
                                        }
                                    } label: {
                                        Image(systemName: SpeechService.shared.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(AppTheme.Colors.accent)
                                    }
                                }
                                
                                Button(action: {
                                    generateDefaultSpeechText()
                                }) {
                                    Label("自動生成高質感模板", systemImage: "sparkles")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.accent)
                                }
                                .buttonStyle(.borderless)
                                .padding(.top, 2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("預約備註 Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle(isEditMode ? "編輯預約行程" : "預約新服務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        save()
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                    .fontWeight(.bold)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                populateForm()
            }
            .onDisappear {
                SpeechService.shared.stop()
            }
        }
    }
    
    private func populateForm() {
        if let appt = appointment {
            selectedCustomerID = appt.customer?.persistentModelID
            selectedBranchID = appt.branch?.persistentModelID
            treatmentItem = appt.treatmentItem
            doctor = appt.doctor
            beautician = appt.beautician
            appointmentDate = appt.appointmentDate
            startTime = appt.startTime
            endTime = appt.endTime
            if let stat = AppointmentStatus(rawValue: appt.status.rawValue) {
                status = stat
            }
            notes = appt.notes
            reminderLeadTime = appt.reminderLeadTime
            reminderSoundType = appt.reminderSoundType
            reminderSpeechText = appt.reminderSpeechText ?? ""
        } else {
            if selectedBranchID == nil, let firstBranch = branches.first {
                selectedBranchID = firstBranch.persistentModelID
            }
            generateDefaultSpeechText()
        }
    }
    
    private func save() {
        // Validation
        guard let customerID = selectedCustomerID,
              let customer = customers.first(where: { $0.persistentModelID == customerID }) else {
            alertTitle = "欄位缺失"
            alertMessage = "請選擇預約客戶。"
            showAlert = true
            return
        }
        
        guard let branchID = selectedBranchID,
              let branch = branches.first(where: { $0.persistentModelID == branchID }) else {
            alertTitle = "欄位缺失"
            alertMessage = "請選擇預約服務的分店。"
            showAlert = true
            return
        }
        
        if treatmentItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = "欄位缺失"
            alertMessage = "請輸入預約療程項目的名稱。"
            showAlert = true
            return
        }
        
        if startTime >= endTime {
            alertTitle = "時間錯誤"
            alertMessage = "結束時間必須在開始時間之後。"
            showAlert = true
            return
        }
        
        // Merge date and times
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appointmentDate)
        
        var startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        startComponents.year = dateComponents.year
        startComponents.month = dateComponents.month
        startComponents.day = dateComponents.day
        
        var endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        endComponents.year = dateComponents.year
        endComponents.month = dateComponents.month
        endComponents.day = dateComponents.day
        
        guard let finalStartTime = calendar.date(from: startComponents),
              let finalEndTime = calendar.date(from: endComponents) else {
            alertTitle = "日期錯誤"
            alertMessage = "時間戳合成時發生錯誤。"
            showAlert = true
            return
        }
        
        if isEditMode {
            // Edit existing appointment
            guard let appt = appointment else { return }
            appt.branch = branch
            appt.treatmentItem = treatmentItem
            appt.doctor = doctor
            appt.beautician = beautician
            appt.appointmentDate = appointmentDate.startOfDay
            appt.startTime = finalStartTime
            appt.endTime = finalEndTime
            appt.status = status
            appt.notes = notes
            appt.reminderLeadTimeSeconds = reminderLeadTime.rawValue
            appt.reminderSoundTypeRaw = reminderSoundType.rawValue
            appt.reminderSpeechText = reminderSpeechText
            
            NotificationService.shared.scheduleAppointmentReminder(for: appt)
        } else {
            // Create new appointment
            let newAppt = Appointment(
                treatmentItem: treatmentItem,
                doctor: doctor,
                beautician: beautician,
                appointmentDate: appointmentDate.startOfDay,
                startTime: finalStartTime,
                endTime: finalEndTime,
                status: .confirmed,
                notes: notes,
                reminderLeadTimeSeconds: reminderLeadTime.rawValue,
                reminderSoundTypeRaw: reminderSoundType.rawValue,
                reminderSpeechText: reminderSpeechText
            )
            newAppt.customer = customer
            newAppt.branch = branch
            
            modelContext.insert(newAppt)
            
            NotificationService.shared.scheduleAppointmentReminder(for: newAppt)
            
            // Create notification for new booking
            let notif = AppNotification(
                type: .appointmentReminder,
                title: "新預約成立提醒",
                message: "客戶 \(customer.fullName) 成功預約於 \(appointmentDate.formattedDate) \(finalStartTime.formattedTime) 前往 \(branch.name) 進行 \(treatmentItem) 療程。",
                scheduledDate: Date()
            )
            notif.customer = customer
            modelContext.insert(notif)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertTitle = "儲存失敗"
            alertMessage = "寫入資料庫時發生錯誤：\(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    AppointmentFormView(appointment: nil)
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
