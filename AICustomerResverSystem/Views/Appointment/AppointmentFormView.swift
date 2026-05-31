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
    
    // Validation alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var isEditMode: Bool {
        appointment != nil
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
                    
                    Picker("預約分店 Branch *", selection: $selectedBranchID) {
                        Text("請選擇分店").tag(nil as PersistentIdentifier?)
                        ForEach(branches) { branch in
                            Text(branch.name).tag(branch.persistentModelID as PersistentIdentifier?)
                        }
                    }
                }
                
                Section("療程與服務人員 Treatment & Staff") {
                    TextField("療程項目 Treatment *", text: $treatmentItem)
                        .textInputAutocapitalization(.words)
                    
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
        }
    }
    
    private func populateForm() {
        if let appt = appointment {
            selectedCustomerID = appt.customer?.persistentModelID
            selectedBranchID = appt.branch?.persistentModelID
            treatmentItem = appt.treatmentItem
            doctor = appt.doctor ?? ""
            beautician = appt.beautician ?? ""
            appointmentDate = appt.appointmentDate
            startTime = appt.startTime
            endTime = appt.endTime
            if let stat = AppointmentStatus(rawValue: appt.status.rawValue) {
                status = stat
            }
            notes = appt.notes ?? ""
        } else {
            if selectedBranchID == nil, let firstBranch = branches.first {
                selectedBranchID = firstBranch.persistentModelID
            }
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
                notes: notes
            )
            newAppt.customer = customer
            newAppt.branch = branch
            
            modelContext.insert(newAppt)
            
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
