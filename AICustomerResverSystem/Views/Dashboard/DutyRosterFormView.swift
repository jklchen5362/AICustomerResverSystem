//  DutyRosterFormView.swift
//  AICustomerResverSystem
//

import SwiftUI
import SwiftData

struct RosterStaff: Identifiable, Equatable {
    let id = UUID()
    var name: String
}

// Extracted Subview for clean, fast compilation in SwiftUI view builders
struct StaffRowView: View {
    let roleName: String
    let index: Int
    let systemImage: String
    let accentColor: Color
    @Binding var name: String
    let onDelete: () -> Void
    let canDelete: Bool
    
    var body: some View {
        HStack {
            Label("\(roleName) \(index + 1)", systemImage: systemImage)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(accentColor)
                .frame(width: 80, alignment: .leading)
            
            TextField("請輸入姓名", text: $name)
                .font(AppTheme.Typography.body)
            
            if canDelete {
                Button(action: {
                    withAnimation(AppTheme.Animations.quick) {
                        onDelete()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless) // Prevent triggering row selection in Form
            }
        }
    }
}

struct DutyRosterFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let activeBranchID: PersistentIdentifier?
    let activeBranchName: String
    
    @Query(sort: \Branch.name) private var branches: [Branch]
    @State private var selectedBranchID: PersistentIdentifier? = nil
    
    @State private var selectedDate = Date()
    
    // Roster arrays with initial empty field using RosterStaff helper
    @State private var doctors: [RosterStaff] = [RosterStaff(name: "")]
    @State private var managers: [RosterStaff] = [RosterStaff(name: "")]
    @State private var consultants: [RosterStaff] = [RosterStaff(name: "")]
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
                
                // 1. Doctors (1-8位)
                Section(header: HStack {
                    Text("今日值班醫師 (最多 8 位)")
                    Spacer()
                    if doctors.count < 8 {
                        Button {
                            withAnimation(AppTheme.Animations.quick) {
                                doctors.append(RosterStaff(name: ""))
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                    }
                }) {
                    ForEach(Array(doctors.enumerated()), id: \.element.id) { index, doctor in
                        StaffRowView(
                            roleName: "醫師",
                            index: index,
                            systemImage: "stethoscope",
                            accentColor: AppTheme.Colors.accent,
                            name: $doctors[index].name,
                            onDelete: {
                                doctors.remove(at: index)
                            },
                            canDelete: doctors.count > 1
                        )
                    }
                }
                
                // 2. Managers / Assistant Managers (1-3位)
                Section(header: HStack {
                    Text("今日值班店長/副店長 (最多 3 位)")
                    Spacer()
                    if managers.count < 3 {
                        Button {
                            withAnimation(AppTheme.Animations.quick) {
                                managers.append(RosterStaff(name: ""))
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.Colors.accentSecondary)
                        }
                    }
                }) {
                    ForEach(Array(managers.enumerated()), id: \.element.id) { index, manager in
                        StaffRowView(
                            roleName: "店長/副店",
                            index: index,
                            systemImage: "shield.checkered",
                            accentColor: AppTheme.Colors.accentSecondary,
                            name: $managers[index].name,
                            onDelete: {
                                managers.remove(at: index)
                            },
                            canDelete: managers.count > 1
                        )
                    }
                }
                
                // 3. Consultants (1-8位)
                Section(header: HStack {
                    Text("今日值班諮詢師 (最多 8 位)")
                    Spacer()
                    if consultants.count < 8 {
                        Button {
                            withAnimation(AppTheme.Animations.quick) {
                                consultants.append(RosterStaff(name: ""))
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.Colors.info)
                        }
                    }
                }) {
                    ForEach(Array(consultants.enumerated()), id: \.element.id) { index, consultant in
                        StaffRowView(
                            roleName: "諮詢師",
                            index: index,
                            systemImage: "person.badge.clock.fill",
                            accentColor: AppTheme.Colors.info,
                            name: $consultants[index].name,
                            onDelete: {
                                consultants.remove(at: index)
                            },
                            canDelete: consultants.count > 1
                        )
                    }
                }
                
                Section("排班備註") {
                    TextField("例如：雷射治療日、團體衛教...", text: $notes)
                        .font(AppTheme.Typography.body)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("登錄今日值班名單")
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
                    .disabled(isSaving || (selectedBranchID == nil))
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
        
        if let existing = rosters.first(where: {
            $0.branch?.persistentModelID == branchID &&
            $0.date >= start && $0.date <= end
        }) {
            doctors = existing.onDutyDoctors.isEmpty ? [RosterStaff(name: "")] : existing.onDutyDoctors.map { RosterStaff(name: $0) }
            managers = existing.onDutyManagers.isEmpty ? [RosterStaff(name: "")] : existing.onDutyManagers.map { RosterStaff(name: $0) }
            consultants = existing.onDutyConsultants.isEmpty ? [RosterStaff(name: "")] : existing.onDutyConsultants.map { RosterStaff(name: $0) }
            notes = existing.notes
        } else {
            doctors = [RosterStaff(name: "")]
            managers = [RosterStaff(name: "")]
            consultants = [RosterStaff(name: "")]
            notes = ""
        }
    }
    
    private func saveRoster() {
        guard let branchID = selectedBranchID else { return }
        isSaving = true
        
        let start = selectedDate.startOfDay
        let end = selectedDate.endOfDay
        
        // Clean empty fields
        let cleanedDoctors = doctors.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let cleanedManagers = managers.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let cleanedConsultants = consultants.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        let descriptor = FetchDescriptor<DutyRoster>()
        let rosters = (try? modelContext.fetch(descriptor)) ?? []
        
        let rosterRecord: DutyRoster
        if let existing = rosters.first(where: {
            $0.branch?.persistentModelID == branchID &&
            $0.date >= start && $0.date <= end
        }) {
            rosterRecord = existing
            rosterRecord.onDutyDoctors = cleanedDoctors
            rosterRecord.onDutyManagers = cleanedManagers
            rosterRecord.onDutyConsultants = cleanedConsultants
            rosterRecord.notes = notes
        } else {
            rosterRecord = DutyRoster(
                date: selectedDate,
                onDutyDoctors: cleanedDoctors,
                onDutyManagers: cleanedManagers,
                onDutyConsultants: cleanedConsultants,
                notes: notes
            )
            modelContext.insert(rosterRecord)
            if let branch = branches.first(where: { $0.persistentModelID == branchID }) {
                rosterRecord.branch = branch
            }
        }
        
        do {
            try modelContext.save()
            print("[DutyRoster] Multi-staff roster saved successfully.")
            dismiss()
        } catch {
            print("[DutyRoster] Error saving roster: \(error)")
        }
        isSaving = false
    }
}
