//  ConsumptionFormView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct ConsumptionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Customer.fullName) private var customers: [Customer]
    @Query(sort: \Branch.name) private var branches: [Branch]
    @Query private var allPackages: [TreatmentPackage]
    
    @State private var viewModel = ConsumptionViewModel()
    
    // Form fields
    @State private var selectedCustomerID: PersistentIdentifier? = nil
    @State private var selectedPackageID: PersistentIdentifier? = nil
    @State private var sessionsToConsume = 1
    @State private var operatorName = ""
    @State private var selectedBranchID: PersistentIdentifier? = nil
    @State private var notes = ""
    
    // Photo mock data
    @State private var mockBeforePhoto = false
    @State private var mockAfterPhoto = false
    @State private var mockSignature = false
    
    // Validation alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    // Computeds
    var selectedCustomerPackages: [TreatmentPackage] {
        guard let cid = selectedCustomerID else { return [] }
        return allPackages.filter { 
            $0.customer?.persistentModelID == cid && $0.remainingSessions > 0 
        }
    }
    
    var selectedPackage: TreatmentPackage? {
        guard let pid = selectedPackageID else { return nil }
        return allPackages.first(where: { $0.persistentModelID == pid })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("選擇客戶與療程方案 Customer & Package") {
                    Picker("選擇客戶 Customer *", selection: $selectedCustomerID) {
                        Text("請選擇客戶").tag(nil as PersistentIdentifier?)
                        ForEach(customers) { customer in
                            Text(customer.fullName).tag(customer.persistentModelID as PersistentIdentifier?)
                        }
                    }
                    .onChange(of: selectedCustomerID) { _, _ in
                        selectedPackageID = nil
                        sessionsToConsume = 1
                    }
                    
                    if selectedCustomerID != nil {
                        Picker("扣堂療程方案 Package *", selection: $selectedPackageID) {
                            Text("請選擇合約方案").tag(nil as PersistentIdentifier?)
                            ForEach(selectedCustomerPackages) { package in
                                Text("\(package.treatmentName) (剩餘 \(package.remainingSessions) 堂)").tag(package.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        .onChange(of: selectedPackageID) { _, _ in
                            sessionsToConsume = 1
                        }
                    }
                }
                
                if let package = selectedPackage {
                    Section("核銷扣堂堂數 Sessions Deduct") {
                        Stepper("扣除堂數: \(sessionsToConsume) 堂", value: $sessionsToConsume, in: 1...package.remainingSessions)
                        
                        HStack {
                            Text("核銷前餘額")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            Spacer()
                            Text("\(package.remainingSessions) 堂")
                                .font(AppTheme.Typography.callout)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("核銷後預估餘額")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            Spacer()
                            Text("\(max(0, package.remainingSessions - sessionsToConsume)) 堂")
                                .font(AppTheme.Typography.callout)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.sessionColor(percentage: package.totalSessions > 0 ? Double(max(0, package.remainingSessions - sessionsToConsume)) / Double(package.totalSessions) : 0))
                        }
                    }
                    
                    Section("營運細節 Details") {
                        TextField("核銷經手美容師/諮詢師 *", text: $operatorName)
                        
                        Picker("執行分店 Branch *", selection: $selectedBranchID) {
                            Text("請選擇分店").tag(nil as PersistentIdentifier?)
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        
                        TextField("核銷備註/部位紀錄 Notes", text: $notes)
                    }
                    
                    Section("相片與簽名記錄 Mock Photos & Signature") {
                        HStack {
                            Button {
                                mockBeforePhoto.toggle()
                            } label: {
                                Label(mockBeforePhoto ? "已擷取術前照" : "拍術前照 (Before)", systemImage: mockBeforePhoto ? "checkmark.circle.fill" : "camera.fill")
                                    .foregroundStyle(mockBeforePhoto ? AppTheme.Colors.success : AppTheme.Colors.accent)
                            }
                            .buttonStyle(.borderless)
                            
                            Spacer()
                            
                            Button {
                                mockAfterPhoto.toggle()
                            } label: {
                                Label(mockAfterPhoto ? "已擷取術後照" : "拍術後照 (After)", systemImage: mockAfterPhoto ? "checkmark.circle.fill" : "camera.fill")
                                    .foregroundStyle(mockAfterPhoto ? AppTheme.Colors.success : AppTheme.Colors.accent)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                        
                        Button {
                            mockSignature.toggle()
                        } label: {
                            Label(mockSignature ? "客戶已完成親簽" : "客戶電子手寫簽名 *", systemImage: mockSignature ? "signature.checkmark" : "hand.and.sparkles.fill")
                                .foregroundStyle(mockSignature ? AppTheme.Colors.success : AppTheme.Colors.accent)
                        }
                        .buttonStyle(.borderless)
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("登記療程扣堂")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("扣堂") {
                        save()
                    }
                    .foregroundStyle(AppTheme.Colors.danger)
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
        guard selectedCustomerID != nil else {
            alertTitle = "欄位缺失"
            alertMessage = "請選擇扣堂客戶。"
            showAlert = true
            return
        }
        
        guard let package = selectedPackage else {
            alertTitle = "欄位缺失"
            alertMessage = "請選擇此客戶的某一療程合約方案。"
            showAlert = true
            return
        }
        
        if operatorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = "欄位缺失"
            alertMessage = "請輸入執行核銷的人員名稱。"
            showAlert = true
            return
        }
        
        guard let branchID = selectedBranchID,
              let branch = branches.first(where: { $0.persistentModelID == branchID }) else {
            alertTitle = "欄位缺失"
            alertMessage = "請指定執行此療程分店據點。"
            showAlert = true
            return
        }
        
        if !mockSignature {
            alertTitle = "簽名缺失"
            alertMessage = "為保障客戶與診所權益，扣堂必須請客戶進行手寫簽名確認。"
            showAlert = true
            return
        }
        
        // Save using ViewModel
        viewModel.recordConsumption(
            package: package,
            sessions: sessionsToConsume,
            operatorName: operatorName,
            branch: branch,
            notes: notes,
            context: modelContext
        )
        
        dismiss()
    }
}

#Preview {
    ConsumptionFormView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
