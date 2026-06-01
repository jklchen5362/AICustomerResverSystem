//
//  GoogleSheetsSyncEngine.swift
//  AICustomerResverSystem
//

import Foundation
import SwiftData

@MainActor
class GoogleSheetsSyncEngine {
    static let shared = GoogleSheetsSyncEngine()
    private init() {}
    
    private let sheetsService = GoogleSheetsService.shared
    
    // Worksheet Titles
    let customersSheet = "客戶資料 (Customers)"
    let appointmentsSheet = "預約記錄 (Appointments)"
    let packagesSheet = "療程方案 (Packages)"
    let invoicesSheet = "財務發票 (Invoices)"
    
    func syncAllData(context: ModelContext, spreadsheetID: String) async throws {
        guard !spreadsheetID.isEmpty else {
            throw NSError(domain: "GoogleSheetsSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "尚未連接 Google 試算表檔案。"])
        }
        
        print("[SyncEngine] Starting full database sync to Google Sheets ID: \(spreadsheetID)")
        
        // 1. Ensure all 4 standard worksheets exist
        let titles = [customersSheet, appointmentsSheet, packagesSheet, invoicesSheet]
        try await sheetsService.ensureWorksheetsExist(spreadsheetID: spreadsheetID, titles: titles)
        
        // 2. Sync Customers
        try await syncCustomers(context: context, spreadsheetID: spreadsheetID)
        
        // 3. Sync Appointments
        try await syncAppointments(context: context, spreadsheetID: spreadsheetID)
        
        // 4. Sync Treatment Packages
        try await syncPackages(context: context, spreadsheetID: spreadsheetID)
        
        // 5. Sync Invoices
        try await syncInvoices(context: context, spreadsheetID: spreadsheetID)
        
        print("[SyncEngine] Full database synchronization completed successfully.")
        
        // Update last sync time in AppState or UserDefaults
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "google_last_sync_time")
    }
    
    // MARK: - Model Core Mappings
    
    private func syncCustomers(context: ModelContext, spreadsheetID: String) async throws {
        let descriptor = FetchDescriptor<Customer>(sortBy: [SortDescriptor(\.fullName)])
        let customers = (try? context.fetch(descriptor)) ?? []
        
        let headers = [
            "客戶編號 (ID)", "姓名 (Name)", "生理性別 (Gender)", "聯絡電話 (Phone)", 
            "電子郵件 (Email)", "LINE ID", "通訊地址 (Address)", "會員等級 (VIP)", 
            "重要過敏史 (Allergies)", "膚質類型 (Skin Type)", "備註 (Notes)", "加入時間 (Joined At)"
        ]
        
        let rows = customers.map { customer -> [String] in
            return [
                customer.customerID,
                customer.fullName,
                customer.gender.displayName,
                customer.phone,
                customer.email,
                customer.lineID,
                customer.address,
                customer.vipLevel.displayName,
                customer.allergyHistory.isEmpty ? "無" : customer.allergyHistory,
                customer.skinType?.displayName ?? "未設定",
                customer.notes,
                customer.createdAt.formattedISODate
            ]
        }
        
        try await sheetsService.overwriteWorksheet(
            spreadsheetID: spreadsheetID,
            sheetTitle: customersSheet,
            headers: headers,
            rows: rows
        )
    }
    
    private func syncAppointments(context: ModelContext, spreadsheetID: String) async throws {
        let descriptor = FetchDescriptor<Appointment>(sortBy: [SortDescriptor(\.appointmentDate, order: .reverse)])
        let appointments = (try? context.fetch(descriptor)) ?? []
        
        let headers = [
            "預約編號 (ID)", "客戶姓名 (Client)", "手機號碼 (Phone)", "預約日期 (Date)", 
            "開始時間 (Start)", "結束時間 (End)", "預約療程 (Treatment)", "主治醫師 (Doctor)", 
            "美容師 (Beautician)", "預約狀態 (Status)", "備註事項 (Notes)"
        ]
        
        let rows = appointments.map { appt -> [String] in
            return [
                appt.appointmentID,
                appt.customer?.fullName ?? "未知客戶",
                appt.customer?.phone ?? "",
                appt.appointmentDate.formattedISODate,
                appt.startTime.formattedTime,
                appt.endTime.formattedTime,
                appt.treatmentItem,
                appt.doctor,
                appt.beautician,
                appt.status.displayName,
                appt.notes
            ]
        }
        
        try await sheetsService.overwriteWorksheet(
            spreadsheetID: spreadsheetID,
            sheetTitle: appointmentsSheet,
            headers: headers,
            rows: rows
        )
    }
    
    private func syncPackages(context: ModelContext, spreadsheetID: String) async throws {
        let descriptor = FetchDescriptor<TreatmentPackage>(sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)])
        let packages = (try? context.fetch(descriptor)) ?? []
        
        let headers = [
            "療程合約編號 (ID)", "客戶姓名 (Client)", "療程名稱 (Package)", "總堂數 (Total)", 
            "已用堂數 (Used)", "剩餘堂數 (Remaining)", "購買金額 (Amount)", "購買日期 (Date)", 
            "合約效期 (Expires At)", "經手諮詢師 (Consultant)", "入帳據點 (Branch)"
        ]
        
        let rows = packages.map { pkg -> [String] in
            // Write numeric values as simple plain numbers so users can write native formulas (e.g. SUM) in Google Sheets
            return [
                pkg.packageID,
                pkg.customer?.fullName ?? "未知客戶",
                pkg.treatmentName,
                "\(pkg.totalSessions)",
                "\(pkg.sessionsUsed)",
                "\(pkg.remainingSessions)",
                "\(Int(pkg.purchaseAmount))",
                pkg.purchaseDate.formattedISODate,
                pkg.expirationDate?.formattedISODate ?? "無效期限制",
                pkg.salesConsultant,
                pkg.purchaseBranch?.name ?? "台北旗艦店"
            ]
        }
        
        try await sheetsService.overwriteWorksheet(
            spreadsheetID: spreadsheetID,
            sheetTitle: packagesSheet,
            headers: headers,
            rows: rows
        )
    }
    
    private func syncInvoices(context: ModelContext, spreadsheetID: String) async throws {
        let descriptor = FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)])
        let invoices = (try? context.fetch(descriptor)) ?? []
        
        let headers = [
            "發票編號 (Invoice #)", "客戶姓名 (Client)", "購買方案 (Package)", 
            "實收金額 (Amount)", "付款方式 (Payment)", "經手諮詢師 (Consultant)", 
            "交易日期 (Date)", "交易分店 (Branch)"
        ]
        
        let rows = invoices.map { inv -> [String] in
            return [
                inv.invoiceNumber,
                inv.customer?.fullName ?? "未知客戶",
                inv.packageName,
                "\(Int(inv.amount))",
                inv.paymentMethod.displayName,
                inv.salesConsultant,
                inv.purchaseDate.formattedISODate,
                inv.branch?.name ?? "台北旗艦店"
            ]
        }
        
        try await sheetsService.overwriteWorksheet(
            spreadsheetID: spreadsheetID,
            sheetTitle: invoicesSheet,
            headers: headers,
            rows: rows
        )
    }
    
    // MARK: - Download & Synchronize Pull Engine
    
    func downloadAllData(context: ModelContext, spreadsheetID: String) async throws {
        guard !spreadsheetID.isEmpty else {
            throw NSError(domain: "GoogleSheetsSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "尚未連接 Google 試算表檔案。"])
        }
        
        print("[SyncEngine] Starting full pull/download from Google Sheets ID: \(spreadsheetID)")
        
        // 1. Ensure all 4 standard worksheets exist prior to download to avoid range errors
        let titles = [customersSheet, appointmentsSheet, packagesSheet, invoicesSheet]
        try await sheetsService.ensureWorksheetsExist(spreadsheetID: spreadsheetID, titles: titles)
        
        // 2. Pull Customers first (since appointments, packages, invoices refer to them)
        try await pullCustomers(context: context, spreadsheetID: spreadsheetID)
        
        // 3. Pull Appointments
        try await pullAppointments(context: context, spreadsheetID: spreadsheetID)
        
        // 4. Pull Packages
        try await pullPackages(context: context, spreadsheetID: spreadsheetID)
        
        // 5. Pull Invoices
        try await pullInvoices(context: context, spreadsheetID: spreadsheetID)
        
        print("[SyncEngine] Full pull/download completed successfully.")
        
        // Update last sync time
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "google_last_sync_time")
    }
    
    private func pullCustomers(context: ModelContext, spreadsheetID: String) async throws {
        let values = try await sheetsService.fetchWorksheetValues(spreadsheetID: spreadsheetID, range: customersSheet)
        guard values.count > 1 else { return }
        
        let dataRows = values.dropFirst()
        
        for row in dataRows {
            guard row.count >= 2 else { continue }
            let id = row[0]
            let name = row[1]
            
            // Check if customer already exists in SwiftData
            let descriptor = FetchDescriptor<Customer>(predicate: #Predicate<Customer> { $0.customerID == id })
            let existing = try? context.fetch(descriptor).first
            
            let genderStr = row.indices.contains(2) ? row[2] : "其他"
            let gender = Gender.fromDisplayName(genderStr)
            
            let phone = row.indices.contains(3) ? row[3] : ""
            let email = row.indices.contains(4) ? row[4] : ""
            let lineID = row.indices.contains(5) ? row[5] : ""
            let address = row.indices.contains(6) ? row[6] : ""
            
            let vipStr = row.indices.contains(7) ? row[7] : "普通客戶"
            let vipLevel = VIPLevel.fromDisplayName(vipStr)
            
            let allergies = row.indices.contains(8) ? row[8] : "無"
            
            let skinStr = row.indices.contains(9) ? row[9] : "未設定"
            let skinType = SkinType.fromDisplayName(skinStr)
            
            let notes = row.indices.contains(10) ? row[10] : ""
            
            let joinedStr = row.indices.contains(11) ? row[11] : ""
            let joinedDate = parseDate(joinedStr) ?? Date()
            
            if let customer = existing {
                customer.fullName = name
                customer.gender = gender
                customer.phone = phone
                customer.email = email
                customer.lineID = lineID
                customer.address = address
                customer.vipLevel = vipLevel
                customer.allergyHistory = allergies
                customer.skinType = skinType
                customer.notes = notes
                customer.createdAt = joinedDate
            } else {
                let newCustomer = Customer(
                    customerID: id,
                    fullName: name,
                    gender: gender,
                    phone: phone,
                    email: email,
                    lineID: lineID,
                    address: address,
                    vipLevel: vipLevel,
                    notes: notes,
                    allergyHistory: allergies,
                    skinType: skinType
                )
                newCustomer.createdAt = joinedDate
                context.insert(newCustomer)
            }
        }
        try? context.save()
    }
    
    private func pullAppointments(context: ModelContext, spreadsheetID: String) async throws {
        let values = try await sheetsService.fetchWorksheetValues(spreadsheetID: spreadsheetID, range: appointmentsSheet)
        guard values.count > 1 else { return }
        
        let dataRows = values.dropFirst()
        
        for row in dataRows {
            guard row.count >= 4 else { continue }
            let id = row[0]
            let clientName = row[1]
            let phone = row[2]
            
            let dateStr = row[3]
            guard let apptDate = parseDate(dateStr) else { continue }
            
            let startStr = row.indices.contains(4) ? row[4] : "09:00"
            let endStr = row.indices.contains(5) ? row[5] : "10:00"
            let startTime = parseTime(startStr)
            let endTime = parseTime(endStr)
            
            let treatment = row.indices.contains(6) ? row[6] : ""
            let doctor = row.indices.contains(7) ? row[7] : ""
            let beautician = row.indices.contains(8) ? row[8] : ""
            
            let statusStr = row.indices.contains(9) ? row[9] : "已確認"
            let status = AppointmentStatus.fromDisplayName(statusStr)
            
            let notes = row.indices.contains(10) ? row[10] : ""
            
            let descriptor = FetchDescriptor<Appointment>(predicate: #Predicate<Appointment> { $0.appointmentID == id })
            let existing = try? context.fetch(descriptor).first
            
            var targetCustomer: Customer? = nil
            if !phone.isEmpty {
                let custDesc = FetchDescriptor<Customer>(predicate: #Predicate<Customer> { $0.phone == phone })
                targetCustomer = try? context.fetch(custDesc).first
            }
            if targetCustomer == nil && !clientName.isEmpty {
                let custDesc = FetchDescriptor<Customer>(predicate: #Predicate<Customer> { $0.fullName == clientName })
                targetCustomer = try? context.fetch(custDesc).first
            }
            
            if let appt = existing {
                appt.appointmentDate = apptDate
                appt.startTime = startTime
                appt.endTime = endTime
                appt.treatmentItem = treatment
                appt.doctor = doctor
                appt.beautician = beautician
                appt.status = status
                appt.notes = notes
                if let tc = targetCustomer {
                    appt.customer = tc
                }
            } else {
                let newAppt = Appointment(
                    appointmentID: id,
                    treatmentItem: treatment,
                    doctor: doctor,
                    beautician: beautician,
                    appointmentDate: apptDate,
                    startTime: startTime,
                    endTime: endTime,
                    status: status,
                    notes: notes
                )
                if let tc = targetCustomer {
                    newAppt.customer = tc
                }
                context.insert(newAppt)
            }
        }
        try? context.save()
    }
    
    private func pullPackages(context: ModelContext, spreadsheetID: String) async throws {
        let values = try await sheetsService.fetchWorksheetValues(spreadsheetID: spreadsheetID, range: packagesSheet)
        guard values.count > 1 else { return }
        
        let dataRows = values.dropFirst()
        
        for row in dataRows {
            guard row.count >= 3 else { continue }
            let id = row[0]
            let clientName = row[1]
            let treatment = row[2]
            
            let total = row.indices.contains(3) ? (Int(row[3]) ?? 10) : 10
            let used = row.indices.contains(4) ? (Int(row[4]) ?? 0) : 0
            
            let amount = row.indices.contains(6) ? (Double(row[6]) ?? 0) : 0
            let dateStr = row.indices.contains(7) ? row[7] : ""
            let purchaseDate = parseDate(dateStr) ?? Date()
            
            let expStr = row.indices.contains(8) ? row[8] : ""
            let expirationDate = parseDate(expStr)
            
            let consultant = row.indices.contains(9) ? row[9] : ""
            let branchName = row.indices.contains(10) ? row[10] : "台北總店"
            
            let descriptor = FetchDescriptor<TreatmentPackage>(predicate: #Predicate<TreatmentPackage> { $0.packageID == id })
            let existing = try? context.fetch(descriptor).first
            
            let custDesc = FetchDescriptor<Customer>(predicate: #Predicate<Customer> { $0.fullName == clientName })
            let targetCustomer = try? context.fetch(custDesc).first
            
            let targetBranch = getOrCreateBranch(context: context, name: branchName)
            
            if let pkg = existing {
                pkg.treatmentName = treatment
                pkg.totalSessions = total
                pkg.sessionsUsed = used
                pkg.purchaseAmount = amount
                pkg.purchaseDate = purchaseDate
                pkg.expirationDate = expirationDate
                pkg.salesConsultant = consultant
                pkg.purchaseBranch = targetBranch
                if let tc = targetCustomer {
                    pkg.customer = tc
                }
            } else {
                let newPkg = TreatmentPackage(
                    packageID: id,
                    treatmentName: treatment,
                    totalSessions: total,
                    sessionsUsed: used,
                    purchaseAmount: amount,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    salesConsultant: consultant
                )
                newPkg.purchaseBranch = targetBranch
                if let tc = targetCustomer {
                    newPkg.customer = tc
                }
                context.insert(newPkg)
            }
        }
        try? context.save()
    }
    
    private func pullInvoices(context: ModelContext, spreadsheetID: String) async throws {
        let values = try await sheetsService.fetchWorksheetValues(spreadsheetID: spreadsheetID, range: invoicesSheet)
        guard values.count > 1 else { return }
        
        let dataRows = values.dropFirst()
        
        for row in dataRows {
            guard row.count >= 3 else { continue }
            let id = row[0]
            let clientName = row[1]
            let packageName = row[2]
            
            let amount = row.indices.contains(3) ? (Double(row[3]) ?? 0) : 0
            
            let payStr = row.indices.contains(4) ? row[4] : "信用卡"
            let paymentMethod = PaymentMethod.fromDisplayName(payStr)
            
            let consultant = row.indices.contains(5) ? row[5] : ""
            
            let dateStr = row.indices.contains(6) ? row[6] : ""
            let purchaseDate = parseDate(dateStr) ?? Date()
            
            let branchName = row.indices.contains(7) ? row[7] : "台北總店"
            
            let descriptor = FetchDescriptor<Invoice>(predicate: #Predicate<Invoice> { $0.invoiceNumber == id })
            let existing = try? context.fetch(descriptor).first
            
            let custDesc = FetchDescriptor<Customer>(predicate: #Predicate<Customer> { $0.fullName == clientName })
            let targetCustomer = try? context.fetch(custDesc).first
            
            let targetBranch = getOrCreateBranch(context: context, name: branchName)
            
            if let inv = existing {
                inv.packageName = packageName
                inv.amount = amount
                inv.paymentMethod = paymentMethod
                inv.salesConsultant = consultant
                inv.purchaseDate = purchaseDate
                inv.branch = targetBranch
                if let tc = targetCustomer {
                    inv.customer = tc
                }
            } else {
                let newInv = Invoice(
                    invoiceNumber: id,
                    packageName: packageName,
                    amount: amount,
                    paymentMethod: paymentMethod,
                    salesConsultant: consultant,
                    purchaseDate: purchaseDate
                )
                newInv.branch = targetBranch
                if let tc = targetCustomer {
                    newInv.customer = tc
                }
                context.insert(newInv)
            }
        }
        try? context.save()
    }
    
    private func getOrCreateBranch(context: ModelContext, name: String) -> Branch {
        let descriptor = FetchDescriptor<Branch>(predicate: #Predicate<Branch> { $0.name == name })
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let newBranch = Branch(name: name)
        context.insert(newBranch)
        try? context.save()
        return newBranch
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.dateFormat = "yyyy/MM/dd"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeString) {
            return date
        }
        return Date()
    }
}

// MARK: - Enums Parse Extensions

extension Gender {
    static func fromDisplayName(_ name: String) -> Gender {
        for val in Gender.allCases {
            if name.contains(val.displayName) || val.displayName.contains(name) {
                return val
            }
        }
        if name.contains("男") { return .male }
        if name.contains("女") { return .female }
        return .other
    }
}

extension VIPLevel {
    static func fromDisplayName(_ name: String) -> VIPLevel {
        for val in VIPLevel.allCases {
            if name.contains(val.displayName) || val.displayName.contains(name) {
                return val
            }
        }
        if name.contains("銅") { return .bronze }
        if name.contains("銀") { return .silver }
        if name.contains("金") { return .gold }
        if name.contains("白金") { return .platinum }
        if name.contains("鑽") { return .diamond }
        return .regular
    }
}

extension SkinType {
    static func fromDisplayName(_ name: String) -> SkinType? {
        for val in SkinType.allCases {
            if name.contains(val.displayName) || val.displayName.contains(name) {
                return val
            }
        }
        if name.contains("乾") { return .dry }
        if name.contains("油") { return .oily }
        if name.contains("混合") { return .combination }
        if name.contains("敏") { return .sensitive }
        if name.contains("中") { return .normal }
        return nil
    }
}

extension AppointmentStatus {
    static func fromDisplayName(_ name: String) -> AppointmentStatus {
        for val in AppointmentStatus.allCases {
            if name.contains(val.displayName) || val.displayName.contains(name) || name.contains(val.shortName) {
                return val
            }
        }
        return .confirmed
    }
}

extension PaymentMethod {
    static func fromDisplayName(_ name: String) -> PaymentMethod {
        for val in PaymentMethod.allCases {
            if name.contains(val.displayName) || val.displayName.contains(name) {
                return val
            }
        }
        return .cash
    }
}

// MARK: - Core Date Formatting Extension Helper

extension Date {
    var formattedISODate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
