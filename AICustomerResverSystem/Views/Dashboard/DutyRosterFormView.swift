//  DutyRosterFormView.swift
//  AICustomerResverSystem
//

import SwiftUI
import SwiftData

struct DutyRosterFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let activeBranchID: PersistentIdentifier?
    let activeBranchName: String
    
    @Query(sort: \Branch.name) private var branches: [Branch]
    @State private var selectedBranchID: PersistentIdentifier? = nil
    
    @State private var selectedDate = Date()
    @State private var doctorName = ""
    @State private var managerName = ""
    @State private var consultantName = ""
    @State private var notes = ""
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("排班基本資訊") {
                    DatePicker("值班日期", selection: $selectedDate, displayedComponents: .date)
                        .font(AppTheme.Typography.body)
                    
                    if activeBranchID != nil {
                        HStack {
                            Text("執勤據點")
                                .font(AppTheme.Typography.body)
                            Spacer()
                            Text(activeBranchName)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    } else {
                        Picker("執勤據點", selection: $selectedBranchID) {
                            Text("選擇分店...").tag(nil as PersistentIdentifier?)
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        .font(AppTheme.Typography.body)
                    }
                }
                
                Section("今日值班人員名單") {
                    HStack {
                        Label("值班醫師", systemImage: "stethoscope")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.accent)
                        Spacer()
                        TextField("請輸入醫師姓名", text: $doctorName)
                            .multilineTextAlignment(.trailing)
                            .font(AppTheme.Typography.body)
                    }
                    
                    HStack {
                        Label("值班店長", systemImage: "shield.checkered")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.accentSecondary)
                        Spacer()
                        TextField("請輸入店長姓名", text: $managerName)
                            .multilineTextAlignment(.trailing)
                            .font(AppTheme.Typography.body)
                    }
                    
                    HStack {
                        Label("值班諮詢師", systemImage: "person.badge.clock.fill")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.info)
                        Spacer()
                        TextField("請輸入諮詢師姓名", text: $consultantName)
                            .multilineTextAlignment(.trailing)
                            .font(AppTheme.Typography.body)
                    }
                }
                
                Section("排班備註") {
                    TextField("例如：雷射治療日、團體衛教...", text: $notes)
                        .font(AppTheme.Typography.body)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("登錄今日值班人員")
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
                        saveRoster()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .disabled(isSaving || (activeBranchID == nil && selectedBranchID == nil))
                }
            }
            .onAppear {
                if let branchID = activeBranchID {
                    selectedBranchID = branchID
                }
                loadExistingRoster()
            }
            .onChange(of: selectedDate) { _, _ in
                loadExistingRoster()
            }
            .onChange(of: selectedBranchID) { _, _ in
                loadExistingRoster()
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    private func loadExistingRoster() {
        guard let branchID = selectedBranchID else { return }
        
        let start = selectedDate.startOfDay
        let end = selectedDate.endOfDay
        
        let descriptor = FetchDescriptor<DutyRoster>()
        let rosters = (try? modelContext.fetch(descriptor)) ?? []
        
        // Find existing record matching date and branch
        if let existing = rosters.first(where: {
            $0.branch?.persistentModelID == branchID &&
            $0.date >= start && $0.date <= end
        }) {
            doctorName = existing.onDutyDoctor
            managerName = existing.onDutyManager
            consultantName = existing.onDutyConsultant
            notes = existing.notes
        } else {
            // Reset fields
            doctorName = ""
            managerName = ""
            consultantName = ""
            notes = ""
        }
    }
    
    private func saveRoster() {
        guard let branchID = selectedBranchID else { return }
        isSaving = true
        
        let start = selectedDate.startOfDay
        let end = selectedDate.endOfDay
        
        let descriptor = FetchDescriptor<DutyRoster>()
        let rosters = (try? modelContext.fetch(descriptor)) ?? []
        
        // Find if a record already exists
        let rosterRecord: DutyRoster
        if let existing = rosters.first(where: {
            $0.branch?.persistentModelID == branchID &&
            $0.date >= start && $0.date <= end
        }) {
            rosterRecord = existing
            rosterRecord.onDutyDoctor = doctorName
            rosterRecord.onDutyManager = managerName
            rosterRecord.onDutyConsultant = consultantName
            rosterRecord.notes = notes
        } else {
            rosterRecord = DutyRoster(
                date: selectedDate,
                onDutyDoctor: doctorName,
                onDutyManager: managerName,
                onDutyConsultant: consultantName,
                notes: notes
            )
            modelContext.insert(rosterRecord)
            if let branch = branches.first(where: { $0.persistentModelID == branchID }) {
                rosterRecord.branch = branch
            }
        }
        
        do {
            try modelContext.save()
            print("[DutyRoster] Roster saved successfully.")
            dismiss()
        } catch {
            print("[DutyRoster] Error saving roster: \(error)")
        }
        isSaving = false
    }
}
