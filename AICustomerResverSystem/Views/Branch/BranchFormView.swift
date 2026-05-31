//  BranchFormView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct BranchFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let branch: Branch?
    
    @State private var name = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var manager = ""
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var isEditMode: Bool {
        branch != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("分店基本資料 Location Info") {
                    TextField("分店名稱 Branch Name *", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("負責人 Manager *", text: $manager)
                        .textInputAutocapitalization(.words)
                    
                    TextField("分店電話 Phone *", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("分店地址 Address *", text: $address)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle(isEditMode ? "編輯分店資料" : "新增分店據點")
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
        guard let branch = branch else { return }
        name = branch.name
        address = branch.address
        phone = branch.phone
        manager = branch.manager
    }
    
    private func save() {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            manager.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            alertTitle = "欄位缺失"
            alertMessage = "所有標示為星號 (*) 的欄位皆為必填項目。"
            showAlert = true
            return
        }
        
        if isEditMode {
            guard let b = branch else { return }
            b.name = name
            b.address = address
            b.phone = phone
            b.manager = manager
        } else {
            let newBranch = Branch(
                name: name,
                address: address,
                phone: phone,
                manager: manager
            )
            modelContext.insert(newBranch)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertTitle = "儲存失敗"
            alertMessage = "寫入分店資料庫時發生錯誤：\(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    BranchFormView(branch: nil)
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
