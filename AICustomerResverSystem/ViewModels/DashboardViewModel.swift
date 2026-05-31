//  DashboardViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
class DashboardViewModel {
    var totalCustomers: Int = 0
    var totalPackagesSold: Int = 0
    var totalRemainingSessions: Int = 0
    var todayAppointmentCount: Int = 0
    var monthlyRevenue: Double = 0.0
    
    var todayAppointments: [Appointment] = []
    var upcomingAppointments: [Appointment] = []
    var recentCustomers: [Customer] = []
    
    struct RevenueDataPoint: Identifiable, Sendable {
        let id = UUID()
        let month: String
        let amount: Double
    }
    
    var monthlyRevenueData: [RevenueDataPoint] = []
    
    var aiRecommendations: [String] = [
        "客戶 林雅琪 的皮秒雷射療程僅剩 1 堂，建議在今日預約結束後，主動推薦加購「緊緻拉提皮秒組合」套裝。",
        "本月「玻尿酸微整」療程需求上升 25%，建議諮詢師針對常客推播玻尿酸保養專題。",
        "分店「台北信義店」今日下午 3 點至 5 點預約較空，可發送 LINE 優惠提醒給附近常客預約微調療程。",
        "客戶 張家豪 連續兩次預約取消，建議指派客服專員主動電話回訪，了解客戶反饋與需求。"
    ]
    
    init() {}
    
    @MainActor
    func refresh(context: ModelContext, branch: Branch? = nil) {
        do {
            // 1. Total Customers
            let customerDesc = FetchDescriptor<Customer>()
            let allCustomers = (try? context.fetch(customerDesc)) ?? []
            
            // Filter customers by selected branch (check if they have packages, appointments, or invoices associated with the branch)
            var filteredCustomers = allCustomers
            if let selectedBranch = branch {
                filteredCustomers = allCustomers.filter { customer in
                    customer.appointments.contains(where: { $0.branch?.persistentModelID == selectedBranch.persistentModelID }) ||
                    customer.packages.contains(where: { $0.purchaseBranch?.persistentModelID == selectedBranch.persistentModelID }) ||
                    customer.invoices.contains(where: { $0.branch?.persistentModelID == selectedBranch.persistentModelID })
                }
            }
            
            self.totalCustomers = filteredCustomers.count
            self.recentCustomers = Array(filteredCustomers.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5))
            
            // 2. Packages Sold & Remaining Sessions
            let packageDesc = FetchDescriptor<TreatmentPackage>()
            let allPackages = (try? context.fetch(packageDesc)) ?? []
            
            var filteredPackages = allPackages
            if let selectedBranch = branch {
                filteredPackages = allPackages.filter { $0.purchaseBranch?.persistentModelID == selectedBranch.persistentModelID }
            }
            
            self.totalPackagesSold = filteredPackages.count
            
            var remaining = 0
            for package in filteredPackages {
                remaining += package.remainingSessions
            }
            self.totalRemainingSessions = remaining
            
            // 3. Appointments
            let appointmentDesc = FetchDescriptor<Appointment>()
            let allAppointments = (try? context.fetch(appointmentDesc)) ?? []
            
            var filteredAppointments = allAppointments
            if let selectedBranch = branch {
                filteredAppointments = allAppointments.filter { $0.branch?.persistentModelID == selectedBranch.persistentModelID }
            }
            
            let today = Date().startOfDay
            let endOfToday = Date().endOfDay
            
            // Today's appointments
            self.todayAppointments = filteredAppointments.filter { 
                $0.appointmentDate >= today && $0.appointmentDate <= endOfToday && $0.status != .cancelled 
            }.sorted(by: { $0.startTime < $1.startTime })
            self.todayAppointmentCount = self.todayAppointments.count
            
            // Upcoming appointments (from tomorrow onwards)
            self.upcomingAppointments = filteredAppointments.filter {
                $0.appointmentDate > endOfToday && $0.status == .confirmed
            }.sorted(by: { $0.appointmentDate < $1.appointmentDate })
            
            // 4. Invoices & Revenue
            let invoiceDesc = FetchDescriptor<Invoice>()
            let allInvoices = (try? context.fetch(invoiceDesc)) ?? []
            
            var filteredInvoices = allInvoices
            if let selectedBranch = branch {
                filteredInvoices = allInvoices.filter { $0.branch?.persistentModelID == selectedBranch.persistentModelID }
            }
            
            let startOfMonth = Date().startOfMonth
            let endOfMonth = Date().endOfMonth
            
            let thisMonthInvoices = filteredInvoices.filter {
                $0.purchaseDate >= startOfMonth && $0.purchaseDate <= endOfMonth
            }
            self.monthlyRevenue = thisMonthInvoices.reduce(0.0) { $0 + $1.amount }
            
            // Compute last 6 months revenue for chart
            var revenuePoints: [RevenueDataPoint] = []
            let calendar = Calendar.current
            
            for i in (0..<6).reversed() {
                if let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) {
                    let mStart = monthDate.startOfMonth
                    let mEnd = monthDate.endOfMonth
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "M月"
                    formatter.locale = Locale(identifier: "zh_TW")
                    let monthName = formatter.string(from: monthDate)
                    
                    let monthInvoices = filteredInvoices.filter {
                        $0.purchaseDate >= mStart && $0.purchaseDate <= mEnd
                    }
                    let monthAmount = monthInvoices.reduce(0.0) { $0 + $1.amount }
                    revenuePoints.append(RevenueDataPoint(month: monthName, amount: monthAmount))
                }
            }
            self.monthlyRevenueData = revenuePoints
            
        } catch {
            print("Error refreshing DashboardViewModel: \(error)")
        }
    }
}
