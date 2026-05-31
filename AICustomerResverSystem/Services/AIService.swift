//  AIService.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
class AIService {
    var isProcessing = false
    
    init() {}
    
    @MainActor
    func processQuery(_ query: String, context: ModelContext) async -> String {
        isProcessing = true
        // Simulate thinking network delay
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        isProcessing = false
        
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Phone number query
        let phoneRegex = /[0-9]{4}-?[0-9]{3}-?[0-9]{3}/
        if let phoneMatch = try? phoneRegex.firstMatch(in: cleanedQuery) {
            let phoneStr = String(phoneMatch.output).replacingOccurrences(of: "-", with: "")
            
            let desc = FetchDescriptor<Customer>()
            let customers = (try? context.fetch(desc)) ?? []
            
            if let matched = customers.first(where: { $0.phone.replacingOccurrences(of: "-", with: "") == phoneStr }) {
                var reply = "🔍 **AI 智能客戶速查系統**\n\n找到符合的客戶資料如下：\n"
                reply += "• **姓名**: \(matched.fullName) (\(matched.gender == .male ? "男" : "女"))\n"
                reply += "• **VIP 等級**: \(matched.vipLevel.displayName) \(matched.vipLevel.icon)\n"
                reply += "• **膚質**: \(matched.skinType?.displayName ?? "未註記")\n"
                
                let pkgs = matched.packages
                if pkgs.isEmpty {
                    reply += "• **療程方案**: 目前無購買療程包\n"
                } else {
                    reply += "• **療程剩餘堂數**:\n"
                    for pkg in pkgs {
                        reply += "  - \(pkg.treatmentName): 剩餘 **\(pkg.remainingSessions)**/\(pkg.totalSessions) 堂\n"
                    }
                }
                
                let appts = matched.appointments.filter({ $0.status == .confirmed }).sorted(by: { $0.startTime < $1.startTime })
                if let nextAppt = appts.first {
                    reply += "• **下次預約**: \(nextAppt.appointmentDate.formattedDate) \(nextAppt.startTime.formattedTime) (\(nextAppt.treatmentItem))\n"
                } else {
                    reply += "• **下次預約**: 尚無即將到來的預約行程\n"
                }
                
                return reply
            } else {
                return "🔍 找不到電話中包含 `\(phoneStr)` 的客戶檔案。請確認號碼輸入正確。"
            }
        }
        
        // 2. Customer Name query
        let customerDesc = FetchDescriptor<Customer>()
        let allCustomers = (try? context.fetch(customerDesc)) ?? []
        
        for customer in allCustomers {
            if cleanedQuery.localizedCaseInsensitiveContains(customer.fullName) {
                var reply = "👤 **AI 智能會員履歷摘要 (\(customer.fullName))**\n\n"
                reply += "• **會員等級**: \(customer.vipLevel.displayName) \(customer.vipLevel.icon)\n"
                reply += "• **膚質狀態**: \(customer.skinType?.displayName ?? "未註記")\n"
                reply += "• **過敏史**: \(customer.allergyHistory.isEmpty ? "無過敏歷史紀錄" : customer.allergyHistory)\n"
                
                let pkgs = customer.packages
                if pkgs.isEmpty {
                    reply += "• **方案餘額**: 暫無購買合約\n"
                } else {
                    reply += "• **方案餘額**:\n"
                    for pkg in pkgs {
                        reply += "  - \(pkg.treatmentName): 剩餘 **\(pkg.remainingSessions)** 堂\n"
                    }
                }
                
                let lastVisit = customer.appointments.filter({ $0.status == .completed }).map({ $0.appointmentDate }).max()
                reply += "• **上次來訪**: \(lastVisit?.formattedDate ?? "無完成紀錄")\n"
                
                if !customer.notes.isEmpty {
                    reply += "• **備忘**: \(customer.notes)\n"
                }
                
                return reply
            }
        }
        
        // 3. "預約" or "appointment" query
        if cleanedQuery.localizedCaseInsensitiveContains("預約") || cleanedQuery.localizedCaseInsensitiveContains("appointment") {
            let apptDesc = FetchDescriptor<Appointment>()
            let allAppts = (try? context.fetch(apptDesc)) ?? []
            
            let todayAppts = allAppts.filter { $0.appointmentDate.isToday && $0.status != .cancelled }.sorted(by: { $0.startTime < $1.startTime })
            let upcomingAppts = allAppts.filter { $0.appointmentDate > Date().endOfDay && $0.status == .confirmed }.sorted(by: { $0.appointmentDate < $1.appointmentDate })
            
            var reply = "📅 **AI 預約排程動態摘要**\n\n"
            reply += "🟢 **今日預約 (共 \(todayAppts.count) 堂)**:\n"
            if todayAppts.isEmpty {
                reply += "  今日無預約行程。\n"
            } else {
                for appt in todayAppts {
                    reply += "  - [\(appt.startTime.formattedTime)] \(appt.customer?.fullName ?? "未知") • \(appt.treatmentItem) (\(appt.status.displayName))\n"
                }
            }
            
            reply += "\n🔵 **未來預約排程精選 (前 3 筆)**:\n"
            if upcomingAppts.isEmpty {
                reply += "  未來尚無預約行程。\n"
            } else {
                for appt in upcomingAppts.prefix(3) {
                    reply += "  - [\(appt.appointmentDate.formattedShortDate) \(appt.startTime.formattedTime)] \(appt.customer?.fullName ?? "未知") • \(appt.treatmentItem) (\(appt.branch?.name ?? "未指定"))\n"
                }
            }
            
            return reply
        }
        
        // 4. "剩餘" or "sessions" query
        if cleanedQuery.localizedCaseInsensitiveContains("剩餘") || cleanedQuery.localizedCaseInsensitiveContains("sessions") || cleanedQuery.localizedCaseInsensitiveContains("堂數") {
            let pkgDesc = FetchDescriptor<TreatmentPackage>()
            let allPkgs = (try? context.fetch(pkgDesc)) ?? []
            
            let runningOut = allPkgs.filter { $0.remainingSessions <= 2 && $0.remainingSessions > 0 }
            
            var reply = "📊 **AI 療程庫存堂數警示**\n\n"
            if runningOut.isEmpty {
                reply += "✅ 目前所有客戶的療程堂數餘額皆在安全水位 (大於 2 堂)。"
            } else {
                reply += "⚠️ **以下客戶的療程方案即將用畢 (餘額 <= 2 堂)，建議盡快通知回訪並推廣續購：**\n"
                for pkg in runningOut {
                    reply += "  - **\(pkg.customer?.fullName ?? "未知")**: \(pkg.treatmentName) (剩餘 **\(pkg.remainingSessions)** 堂 / 共 \(pkg.totalSessions) 堂)\n"
                }
            }
            
            return reply
        }
        
        // 5. "營收" or "revenue" query
        if cleanedQuery.localizedCaseInsensitiveContains("營收") || cleanedQuery.localizedCaseInsensitiveContains("revenue") || cleanedQuery.localizedCaseInsensitiveContains("業績") {
            let invoiceDesc = FetchDescriptor<Invoice>()
            let allInvoices = (try? context.fetch(invoiceDesc)) ?? []
            
            let start = Date().startOfMonth
            let end = Date().endOfDay
            let thisMonthInvoices = allInvoices.filter { $0.purchaseDate >= start && $0.purchaseDate <= end }
            
            let total = thisMonthInvoices.reduce(0.0) { $0 + $1.amount }
            
            var reply = "💰 **AI 本月財務分析動態**\n\n"
            reply += "• **本月總實收營收**: \(total.formattedCurrency)\n"
            reply += "• **交易總筆數**: \(thisMonthInvoices.count) 筆\n"
            if thisMonthInvoices.count > 0 {
                reply += "• **均單實收 (客單價)**: \((total / Double(thisMonthInvoices.count)).formattedCurrency)\n"
            }
            
            // Payment method stats
            var payCounts: [String: Double] = [:]
            for invoice in thisMonthInvoices {
                payCounts[invoice.paymentMethod.rawValue, default: 0.0] += invoice.amount
            }
            
            reply += "• **支付管道分佈**:\n"
            for (method, amt) in payCounts {
                let name = PaymentMethod(rawValue: method)?.displayName ?? method
                reply += "  - \(name): \(amt.formattedCurrency)\n"
            }
            
            return reply
        }
        
        // 6. Default response
        return "🤖 **您好！我是您的醫美智能助理**\n\n您可以輸入以下查詢語句來協助您進行診所營運：\n" +
            "1. `查詢 0912-345-678` - 快速查驗某客戶的手機、VIP、療程剩餘與預約狀況。\n" +
            "2. `林雅琪` - 調閱林雅琪的醫美檔案、膚質分類與諮詢病史。\n" +
            "3. `今日預約` 或 `預約` - 盤點今日預約與未來排班行程。\n" +
            "4. `剩餘堂數` - 警示剩餘不到 2 堂即將用畢的療程包，以利續購銷售。\n" +
            "5. `營收業績` - 即時統計分析本月總營業額與支付比例。\n\n*提示：您可以直接在下方輸入框中發送指令！*"
    }
}
