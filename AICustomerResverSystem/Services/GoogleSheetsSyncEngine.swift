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
}

// MARK: - Core Date Formatting Extension Helper

extension Date {
    var formattedISODate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
