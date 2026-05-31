
//  SampleDataService.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

struct SampleDataService {
    
    @MainActor
    static func loadSampleData(into context: ModelContext) {
        // MARK: - Create Branches
        let branches = createBranches()
        branches.forEach { context.insert($0) }
        
        // MARK: - Create Customers
        let customers = createCustomers()
        customers.forEach { context.insert($0) }
        
        // MARK: - Create Treatment Packages
        let packages = createPackages(customers: customers, branches: branches)
        packages.forEach { context.insert($0) }
        
        // MARK: - Create Appointments
        let appointments = createAppointments(customers: customers, branches: branches)
        appointments.forEach { context.insert($0) }
        
        // MARK: - Create Invoices
        let invoices = createInvoices(customers: customers, branches: branches, packages: packages)
        invoices.forEach { context.insert($0) }
        
        // MARK: - Create Consumption Records
        let consumptions = createConsumptions(customers: customers, branches: branches, packages: packages)
        consumptions.forEach { context.insert($0) }
        
        // MARK: - Create Notifications
        let notifications = createNotifications(customers: customers)
        notifications.forEach { context.insert($0) }
        
        // MARK: - Create Default User
        let admin = UserAccount(
            username: "admin",
            displayName: "系統管理員",
            email: "admin@beautyclinic.tw",
            role: .admin
        )
        context.insert(admin)
        
        try? context.save()
    }
    
    // MARK: - Branches
    private static func createBranches() -> [Branch] {
        [
            Branch(branchID: "BR-TPE", name: "台北旗艦店", address: "台北市大安區忠孝東路四段100號3F", phone: "02-2771-1234", manager: "王美麗"),
            Branch(branchID: "BR-TCH", name: "台中店", address: "台中市西屯區台灣大道三段251號2F", phone: "04-2258-5678", manager: "林雅婷"),
            Branch(branchID: "BR-KHH", name: "高雄店", address: "高雄市前鎮區中山二路268號5F", phone: "07-335-9012", manager: "陳佳琪"),
            Branch(branchID: "BR-HSC", name: "新竹店", address: "新竹市東區光復路一段89號", phone: "03-572-3456", manager: "張雯萱"),
            Branch(branchID: "BR-TNN", name: "台南店", address: "台南市中西區民族路二段57號", phone: "06-221-7890", manager: "黃詩涵"),
        ]
    }
    
    // MARK: - Customers
    private static func createCustomers() -> [Customer] {
        [
            Customer(customerID: "C0001", fullName: "林雅琪", gender: .female,
                     birthday: makeDate(1990, 3, 15), phone: "0922-111-222",
                     email: "yachi.lin@email.com", lineID: "yachi_lin",
                     address: "台北市信義區松仁路100號", vipLevel: .gold,
                     allergyHistory: "對Lidocaine過敏", skinType: .combination,
                     consultationNotes: "希望改善法令紋與蘋果肌"),
            
            Customer(customerID: "C0002", fullName: "王怡婷", gender: .female,
                     birthday: makeDate(1988, 7, 22), phone: "0933-222-333",
                     email: "yiting.wang@email.com", lineID: "yiting_w",
                     address: "台北市大安區敦化南路一段200號", vipLevel: .platinum,
                     allergyHistory: "無", skinType: .sensitive,
                     consultationNotes: "長期做皮秒雷射保養，膚況穩定"),
            
            Customer(customerID: "C0003", fullName: "陳美玲", gender: .female,
                     birthday: makeDate(1985, 11, 8), phone: "0955-333-444",
                     email: "meiling.chen@email.com", lineID: "meiling888",
                     address: "台中市南屯區公益路二段50號", vipLevel: .diamond,
                     allergyHistory: "青黴素過敏", skinType: .dry,
                     consultationNotes: "VIP客戶，每月固定回診"),
            
            Customer(customerID: "C0004", fullName: "張雅芳", gender: .female,
                     birthday: makeDate(1992, 5, 30), phone: "0966-444-555",
                     email: "yafang@email.com", lineID: "yafang_c",
                     address: "高雄市苓雅區中正一路120號", vipLevel: .silver,
                     allergyHistory: "無", skinType: .oily,
                     consultationNotes: "想做臉部輪廓調整"),
            
            Customer(customerID: "C0005", fullName: "李佳穎", gender: .female,
                     birthday: makeDate(1995, 9, 12), phone: "0977-555-666",
                     email: "jiaying.li@email.com", lineID: "jiaying_lee",
                     address: "台北市中山區南京東路二段80號", vipLevel: .gold,
                     allergyHistory: "無", skinType: .normal,
                     consultationNotes: "首次諮詢，對電波拉提有興趣"),
            
            Customer(customerID: "C0006", fullName: "黃詩涵", gender: .female,
                     birthday: makeDate(1993, 1, 25), phone: "0988-666-777",
                     email: "shihan.h@email.com", lineID: "shihan_h",
                     address: "新竹市東區光復路二段30號", vipLevel: .bronze,
                     allergyHistory: "無", skinType: .combination,
                     consultationNotes: "學生族群，預算有限"),
            
            Customer(customerID: "C0007", fullName: "吳雅雯", gender: .female,
                     birthday: makeDate(1987, 4, 18), phone: "0911-777-888",
                     email: "yawen.wu@email.com", lineID: "yawen_wu",
                     address: "台北市松山區民生東路五段60號", vipLevel: .gold,
                     allergyHistory: "對A酸過敏", skinType: .sensitive,
                     consultationNotes: "定期做保養療程"),
            
            Customer(customerID: "C0008", fullName: "鄭凱文", gender: .male,
                     birthday: makeDate(1991, 8, 5), phone: "0922-888-999",
                     email: "kevin.cheng@email.com", lineID: "kevin_c",
                     address: "台北市內湖區瑞光路100號", vipLevel: .silver,
                     allergyHistory: "無", skinType: .oily,
                     consultationNotes: "男性保養需求，痘疤處理"),
            
            Customer(customerID: "C0009", fullName: "Amy Chen", gender: .female,
                     birthday: makeDate(1994, 12, 1), phone: "0933-999-000",
                     email: "amy.chen@email.com", lineID: "amy_beauty",
                     address: "台北市大安區復興南路一段150號", vipLevel: .platinum,
                     allergyHistory: "無", skinType: .normal,
                     consultationNotes: "外商主管，重視效率，偏好午休美容"),
            
            Customer(customerID: "C0010", fullName: "趙婉如", gender: .female,
                     birthday: makeDate(1986, 6, 20), phone: "0966-000-111",
                     email: "wanru.zhao@email.com", lineID: "wanru_z",
                     address: "台南市東區長榮路一段88號", vipLevel: .gold,
                     allergyHistory: "海鮮過敏（口服藥物注意）", skinType: .dry,
                     consultationNotes: "產後修復需求"),
            
            Customer(customerID: "C0011", fullName: "周欣怡", gender: .female,
                     birthday: makeDate(1996, 2, 14), phone: "0977-111-222",
                     email: "xinyi.zhou@email.com", lineID: "xinyi_z",
                     address: "台北市信義區基隆路一段180號", vipLevel: .regular,
                     allergyHistory: "無", skinType: .combination),
            
            Customer(customerID: "C0012", fullName: "蔡雅琳", gender: .female,
                     birthday: makeDate(1989, 10, 7), phone: "0988-222-333",
                     email: "yalin.tsai@email.com", lineID: "yalin_t",
                     address: "台中市北屯區文心路四段200號", vipLevel: .silver,
                     allergyHistory: "無", skinType: .oily),
        ]
    }
    
    // MARK: - Treatment Packages
    private static func createPackages(customers: [Customer], branches: [Branch]) -> [TreatmentPackage] {
        var pkgs: [TreatmentPackage] = []
        
        let treatments: [(String, Int, Double)] = [
            ("皮秒雷射 PicoSure", 10, 120000),
            ("電波拉提 Thermage", 3, 180000),
            ("音波拉提 Ultherapy", 5, 150000),
            ("玻尿酸注射 HA Filler", 6, 90000),
            ("肉毒桿菌 Botox", 8, 48000),
            ("水飛梭 HydraFacial", 12, 36000),
            ("脈衝光 IPL", 8, 56000),
            ("淨膚雷射 Gentle Laser", 10, 80000),
            ("CO2飛梭雷射 Fractional CO2", 6, 96000),
            ("鳳凰電波 Thermage FLX", 2, 120000),
        ]
        
        for (i, customer) in customers.prefix(10).enumerated() {
            let t1 = treatments[i % treatments.count]
            let pkg1 = TreatmentPackage(
                packageID: "PKG-\(String(format: "%04d", i * 2 + 1))",
                treatmentName: t1.0,
                totalSessions: t1.1,
                sessionsUsed: Int.random(in: 0...(t1.1 / 2)),
                purchaseAmount: t1.2,
                purchaseDate: Date().adding(months: -Int.random(in: 1...6)),
                expirationDate: Date().adding(months: Int.random(in: 3...12)),
                salesConsultant: ["Amy顧問", "Bella顧問", "Cindy顧問", "Diana顧問"][i % 4]
            )
            pkg1.customer = customer
            pkg1.purchaseBranch = branches[i % branches.count]
            pkgs.append(pkg1)
            
            if i < 6 {
                let t2 = treatments[(i + 3) % treatments.count]
                let pkg2 = TreatmentPackage(
                    packageID: "PKG-\(String(format: "%04d", i * 2 + 2))",
                    treatmentName: t2.0,
                    totalSessions: t2.1,
                    sessionsUsed: Int.random(in: 0...(t2.1 / 3)),
                    purchaseAmount: t2.2,
                    purchaseDate: Date().adding(months: -Int.random(in: 1...4)),
                    expirationDate: Date().adding(months: Int.random(in: 6...18)),
                    salesConsultant: ["Amy顧問", "Bella顧問", "Cindy顧問"][i % 3]
                )
                pkg2.customer = customer
                pkg2.purchaseBranch = branches[i % branches.count]
                pkgs.append(pkg2)
            }
        }
        
        return pkgs
    }
    
    // MARK: - Appointments
    private static func createAppointments(customers: [Customer], branches: [Branch]) -> [Appointment] {
        var apts: [Appointment] = []
        let doctors = ["Dr. 林", "Dr. 王", "Dr. 陳", "Dr. 張", "Dr. 黃"]
        let beauticians = ["小美", "小雅", "小琪", "小婷", "小涵"]
        let treatments = ["皮秒雷射", "電波拉提", "音波拉提", "玻尿酸注射", "肉毒桿菌", "水飛梭", "脈衝光", "淨膚雷射"]
        
        // Today's appointments
        for i in 0..<4 {
            let customer = customers[i]
            let today = Calendar.current.startOfDay(for: Date())
            let startHour = 9 + i * 2
            let start = Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let end = Calendar.current.date(bySettingHour: startHour + 1, minute: 30, second: 0, of: today)!
            
            let apt = Appointment(
                appointmentID: "APT-T\(String(format: "%03d", i + 1))",
                treatmentItem: treatments[i],
                doctor: doctors[i % doctors.count],
                beautician: beauticians[i % beauticians.count],
                appointmentDate: today,
                startTime: start,
                endTime: end,
                status: i == 0 ? .completed : (i == 1 ? .arrived : .confirmed)
            )
            apt.customer = customer
            apt.branch = branches[0]
            apts.append(apt)
        }
        
        // Upcoming appointments (next 7 days)
        for i in 0..<8 {
            let customer = customers[(i + 4) % customers.count]
            let futureDate = Date().adding(days: Int.random(in: 1...7))
            let day = Calendar.current.startOfDay(for: futureDate)
            let startHour = Int.random(in: 9...17)
            let start = Calendar.current.date(bySettingHour: startHour, minute: [0, 30][Int.random(in: 0...1)], second: 0, of: day)!
            let end = start.addingTimeInterval(Double(Int.random(in: 1...2)) * 3600)
            
            let apt = Appointment(
                appointmentID: "APT-F\(String(format: "%03d", i + 1))",
                treatmentItem: treatments[i % treatments.count],
                doctor: doctors[i % doctors.count],
                beautician: beauticians[i % beauticians.count],
                appointmentDate: day,
                startTime: start,
                endTime: end,
                status: .confirmed
            )
            apt.customer = customer
            apt.branch = branches[i % branches.count]
            apts.append(apt)
        }
        
        // Past appointments
        for i in 0..<6 {
            let customer = customers[i]
            let pastDate = Date().adding(days: -Int.random(in: 1...30))
            let day = Calendar.current.startOfDay(for: pastDate)
            let startHour = Int.random(in: 10...16)
            let start = Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: day)!
            let end = start.addingTimeInterval(5400)
            
            let apt = Appointment(
                appointmentID: "APT-P\(String(format: "%03d", i + 1))",
                treatmentItem: treatments[(i + 2) % treatments.count],
                doctor: doctors[i % doctors.count],
                beautician: beauticians[i % beauticians.count],
                appointmentDate: day,
                startTime: start,
                endTime: end,
                status: i == 5 ? .noShow : .completed
            )
            apt.customer = customer
            apt.branch = branches[i % branches.count]
            apts.append(apt)
        }
        
        return apts
    }
    
    // MARK: - Invoices
    private static func createInvoices(customers: [Customer], branches: [Branch], packages: [TreatmentPackage]) -> [Invoice] {
        var invoices: [Invoice] = []
        let consultants = ["Amy顧問", "Bella顧問", "Cindy顧問", "Diana顧問"]
        let payments: [PaymentMethod] = [.creditCard, .cash, .linePay, .bankTransfer, .applePay]
        
        for (i, pkg) in packages.enumerated() {
            let inv = Invoice(
                invoiceNumber: "INV-\(String(format: "%06d", i + 1))",
                packageName: pkg.treatmentName,
                amount: pkg.purchaseAmount,
                paymentMethod: payments[i % payments.count],
                salesConsultant: consultants[i % consultants.count],
                purchaseDate: pkg.purchaseDate
            )
            inv.customer = pkg.customer
            inv.branch = pkg.purchaseBranch
            invoices.append(inv)
        }
        
        return invoices
    }
    
    // MARK: - Consumption Records
    private static func createConsumptions(customers: [Customer], branches: [Branch], packages: [TreatmentPackage]) -> [ConsumptionRecord] {
        var records: [ConsumptionRecord] = []
        let operators = ["小美", "小雅", "小琪", "小婷"]
        
        for (i, pkg) in packages.enumerated() {
            for j in 0..<pkg.sessionsUsed {
                let cr = ConsumptionRecord(
                    recordID: "CR-\(String(format: "%04d", i))-\(j + 1)",
                    date: pkg.purchaseDate.adding(days: (j + 1) * Int.random(in: 7...21)),
                    treatmentName: pkg.treatmentName,
                    sessionsConsumed: 1,
                    operatorName: operators[(i + j) % operators.count]
                )
                cr.customer = pkg.customer
                cr.package = pkg
                cr.branch = pkg.purchaseBranch
                records.append(cr)
            }
        }
        
        return records
    }
    
    // MARK: - Notifications
    private static func createNotifications(customers: [Customer]) -> [AppNotification] {
        var notifs: [AppNotification] = []
        
        // Appointment reminders
        for customer in customers.prefix(4) {
            let n = AppNotification(
                type: .appointmentReminder,
                title: "預約提醒",
                message: "\(customer.fullName) 明天有預約，請記得提前到達。",
                scheduledDate: Date().adding(days: 1)
            )
            n.customer = customer
            notifs.append(n)
        }
        
        // Birthday
        if let bdayCustomer = customers.first(where: { $0.birthday?.isThisMonth == true }) {
            let n = AppNotification(
                type: .birthdayGreeting,
                title: "🎂 生日快樂！",
                message: "\(bdayCustomer.fullName) 生日快樂！可發送生日優惠券。",
                scheduledDate: bdayCustomer.birthday ?? Date()
            )
            n.customer = bdayCustomer
            notifs.append(n)
        }
        
        // Expiration warning
        let expNotif = AppNotification(
            type: .packageExpiration,
            title: "療程即將到期",
            message: "陳美玲 的電波拉提療程將在30天後到期，剩餘2堂未使用。",
            scheduledDate: Date().adding(days: 30)
        )
        expNotif.customer = customers.count > 2 ? customers[2] : nil
        notifs.append(expNotif)
        
        // Follow-up
        let followUp = AppNotification(
            type: .followUpReminder,
            title: "回訪提醒",
            message: "張雅芳 已超過30天未回診，建議安排回訪。"
        )
        followUp.customer = customers.count > 3 ? customers[3] : nil
        notifs.append(followUp)
        
        return notifs
    }
    
    // MARK: - Helper
    private static func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
