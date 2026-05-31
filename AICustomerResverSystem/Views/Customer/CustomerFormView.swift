//  CustomerFormView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct CustomerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let customer: Customer?
    
    // Form fields
    @State private var fullName = ""
    @State private var gender: Gender = .female
    @State private var birthday = Date().adding(months: -300) // approx 25 yrs ago
    @State private var phone = ""
    @State private var email = ""
    @State private var lineID = ""
    @State private var address = ""
    @State private var vipLevel: VIPLevel = .regular
    @State private var notes = ""
    
    // Medical fields
    @State private var allergyHistory = ""
    @State private var treatmentHistory = ""
    @State private var skinType: SkinType = .normal
    @State private var consultationNotes = ""
    
    // Validation alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var isEditMode: Bool {
        customer != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("個人基本資料 Personal Info") {
                    TextField("姓名 Full Name *", text: $fullName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("性別 Gender", selection: $gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    
                    DatePicker("生日 Birthday", selection: $birthday, displayedComponents: .date)
                    
                    TextField("電話 Phone Number *", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("電子郵件 Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                Section("聯絡與會員資訊 Contact & VIP") {
                    TextField("LINE ID", text: $lineID)
                        .textInputAutocapitalization(.never)
                    
                    TextField("通訊地址 Address", text: $address)
                    
                    Picker("會員等級 VIP Level", selection: $vipLevel) {
                        ForEach(VIPLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
                
                Section("醫美膚質健康檔案 Medical & Skin Profile") {
                    Picker("膚質分類 Skin Type", selection: $skinType) {
                        ForEach(SkinType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("過敏病史 Allergy History")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        TextEditor(text: $allergyHistory)
                            .frame(height: 60)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("歷史治療病史 Treatment History")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        TextEditor(text: $treatmentHistory)
                            .frame(height: 60)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("臨床諮詢隨筆 Consultation Notes")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        TextEditor(text: $consultationNotes)
                            .frame(height: 80)
                    }
                }
                
                Section("客戶備註事項 General Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle(isEditMode ? "編輯客戶資料" : "新增客戶檔案")
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
        guard let customer = customer else { return }
        fullName = customer.fullName
        gender = customer.gender
        if let b = customer.birthday {
            birthday = b
        }
        phone = customer.phone
        email = customer.email
        lineID = customer.lineID
        address = customer.address
        vipLevel = customer.vipLevel
        notes = customer.notes
        
        // Medical
        allergyHistory = customer.allergyHistory
        treatmentHistory = customer.treatmentHistory
        skinType = customer.skinType ?? .normal
        consultationNotes = customer.consultationNotes
    }
    
    private func save() {
        // Validation
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = "欄位缺失"
            alertMessage = "客戶姓名為必填項目。"
            showAlert = true
            return
        }
        
        let cleanedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedPhone.isEmpty {
            alertTitle = "欄位缺失"
            alertMessage = "客戶電話為必填項目。"
            showAlert = true
            return
        }
        
        if !email.isEmpty && !email.isValidEmail {
            alertTitle = "格式錯誤"
            alertMessage = "請輸入有效的電子郵件地址。"
            showAlert = true
            return
        }
        
        if isEditMode {
            // Update existing customer
            guard let customer = customer else { return }
            customer.fullName = fullName
            customer.gender = gender
            customer.birthday = birthday
            customer.phone = phone
            customer.email = email
            customer.lineID = lineID
            customer.address = address
            customer.vipLevel = vipLevel
            customer.notes = notes
            
            customer.skinType = skinType
            customer.allergyHistory = allergyHistory
            customer.treatmentHistory = treatmentHistory
            customer.consultationNotes = consultationNotes
            customer.updatedAt = Date()
        } else {
            // Create new customer
            let newCustomer = Customer(
                fullName: fullName,
                gender: gender,
                birthday: birthday,
                phone: phone,
                email: email,
                lineID: lineID,
                address: address,
                vipLevel: vipLevel,
                notes: notes,
                allergyHistory: allergyHistory,
                treatmentHistory: treatmentHistory,
                skinType: skinType,
                consultationNotes: consultationNotes
            )
            modelContext.insert(newCustomer)
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
    CustomerFormView(customer: nil)
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
