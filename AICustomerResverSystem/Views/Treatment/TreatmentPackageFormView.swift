//  TreatmentPackageFormView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct TreatmentPackageFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Customer.fullName) private var customers: [Customer]
    @Query(sort: \Branch.name) private var branches: [Branch]
    
    // Form fields
    @State private var selectedCustomerID: PersistentIdentifier? = nil
    @State private var treatmentName = ""
    @State private var totalSessions = 10
    @State private var purchaseAmountString = "15000"
    @State private var purchaseDate = Date()
    @State private var hasExpiration = true
    @State private var expirationDate = Date().adding(months: 12)
    @State private var selectedBranchID: PersistentIdentifier? = nil
    @State private var salesConsultant = ""
    @State private var paymentMethod: PaymentMethod = .creditCard
    
    // Validation alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("選擇客戶與療程 Customer & Treatment") {
                    Picker("選擇客戶 Customer *", selection: $selectedCustomerID) {
                        Text("請選擇客戶").tag(nil as PersistentIdentifier?)
                        ForEach(customers) { customer in
                            Text(customer.fullName).tag(customer.persistentModelID as PersistentIdentifier?)
                        }
                    }
                    
                    TextField("療程名稱 Treatment Name *", text: $treatmentName)
                        .textInputAutocapitalization(.words)
                }
                
                Section("堂數與金額 Sessions & Pricing") {
                    Stepper("購買總堂數: \(totalSessions) 堂", value: $totalSessions, in: 1...100)
                    
                    TextField("實付金額 Purchase Amount (NT$)*", text: $purchaseAmountString)
                        .keyboardType(.numberPad)
                    
                    Picker("付款方式 Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                }
                
                Section("銷售與時間設定 Details & Expiration") {
                    DatePicker("購買日期 Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    Toggle("是否有合約過期效期", isOn: $hasExpiration)
                    
                    if hasExpiration {
                        DatePicker("到期日期 Expiration Date", selection: $expirationDate, displayedComponents: .date)
                    }
                    
                    Picker("所屬分店 Branch *", selection: $selectedBranchID) {
                        Text("請選擇分店").tag(nil as PersistentIdentifier?)
                        ForEach(branches) { branch in
                            Text(branch.name).tag(branch.persistentModelID as PersistentIdentifier?)
                        }
                    }
                    
                    TextField("經手諮詢顧問 Consultant", text: $salesConsultant)
                }
            }
            .navigationTitle("購買新療程")
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
                if selectedBranchID == nil, let firstBranch = branches.first {
                    selectedBranchID = firstBranch.persistentModelID
                }
            }
        }
    }
    
    private func save() {
        // Validation
        guard let customerID = selectedCustomerID,
              let customer = customers.first(where: { $0.persistentModelID == customerID }) else {
            alertTitle = "欄位缺失"
            alertMessage = "請選擇此療程方案的購買客戶。"
            showAlert = true
            return
        }
        
        if treatmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = "欄位缺失"
            alertMessage = "請輸入購買的療程項目名稱。"
            showAlert = true
            return
        }
        
        guard let amount = Double(purchaseAmountString.filter { $0.isNumber }), amount > 0 else {
            alertTitle = "金額錯誤"
            alertMessage = "請輸入有效的購買實付金額。"
            showAlert = true
            return
        }
        
        guard let branchID = selectedBranchID,
              let branch = branches.first(where: { $0.persistentModelID == branchID }) else {
            alertTitle = "欄位缺失"
            alertMessage = "請指定銷售入帳的分店。"
            showAlert = true
            return
        }
        
        let expDate = hasExpiration ? expirationDate : nil
        
        // 1. Create Treatment Package
        let package = TreatmentPackage(
            treatmentName: treatmentName,
            totalSessions: totalSessions,
            sessionsUsed: 0,
            purchaseAmount: amount,
            purchaseDate: purchaseDate,
            expirationDate: expDate,
            salesConsultant: salesConsultant.isEmpty ? "未指定" : salesConsultant
        )
        
        package.customer = customer
        package.purchaseBranch = branch
        modelContext.insert(package)
        
        // 2. Generate matching Invoice for financials
        let invoiceNum = "INV-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"
        let invoice = Invoice(
            invoiceNumber: invoiceNum,
            packageName: treatmentName,
            amount: amount,
            paymentMethod: paymentMethod,
            salesConsultant: salesConsultant.isEmpty ? "未指定" : salesConsultant,
            purchaseDate: purchaseDate
        )
        invoice.customer = customer
        invoice.branch = branch
        modelContext.insert(invoice)
        
        // 3. Trigger Notification about purchase
        let notification = AppNotification(
            type: .systemAlert,
            title: "新療程購買通知",
            message: "客戶 \(customer.fullName) 成功購買了 \(treatmentName) 療程方案共 \(totalSessions) 堂，實收 \(amount.formattedCurrency)。",
            scheduledDate: Date()
        )
        notification.customer = customer
        modelContext.insert(notification)
        
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
    TreatmentPackageFormView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
