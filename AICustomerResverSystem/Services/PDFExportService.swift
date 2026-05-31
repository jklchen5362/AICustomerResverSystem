//  PDFExportService.swift
//  AICustomerResverSystem

import UIKit
import SwiftData

class PDFExportService {
    static func generateCustomerReport(customers: [Customer]) -> Data? {
        let pdfMetaData = [
            kCGPDFContextAuthor as String: "AI Beauty CRM",
            kCGPDFContextSubject as String: "客戶分析報表",
            kCGPDFContextCreator as String: "AICustomerResverSystem"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4 Paper Size: 595 x 842 points
        let pageWidth = 595.2
        let pageHeight = 842.0
        let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Draw Header Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0)
            ]
            let titleText = "醫美系統客戶統計報表"
            titleText.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
            
            // Draw Subtitle / Meta
            let metaFont = UIFont.systemFont(ofSize: 11)
            let metaAttributes: [NSAttributedString.Key: Any] = [
                .font: metaFont,
                .foregroundColor: UIColor.gray
            ]
            let dateStr = "生成日期: \(Date().formattedDateTime)"
            dateStr.draw(at: CGPoint(x: 40, y: 75), withAttributes: metaAttributes)
            
            let countStr = "客戶總數: \(customers.count) 位"
            countStr.draw(at: CGPoint(x: 40, y: 92), withAttributes: metaAttributes)
            
            // Draw a Divider
            let contextGraphics = context.cgContext
            contextGraphics.setStrokeColor(UIColor.lightGray.cgColor)
            contextGraphics.setLineWidth(1.0)
            contextGraphics.move(to: CGPoint(x: 40, y: 120))
            contextGraphics.addLine(to: CGPoint(x: 555, y: 120))
            contextGraphics.strokePath()
            
            // Draw List Header
            let headerFont = UIFont.boldSystemFont(ofSize: 12)
            let headerAttributes = [NSAttributedString.Key.font: headerFont]
            
            "姓名".draw(at: CGPoint(x: 40, y: 140), withAttributes: headerAttributes)
            "電話".draw(at: CGPoint(x: 120, y: 140), withAttributes: headerAttributes)
            "會員級別".draw(at: CGPoint(x: 240, y: 140), withAttributes: headerAttributes)
            "膚質".draw(at: CGPoint(x: 350, y: 140), withAttributes: headerAttributes)
            "加入時間".draw(at: CGPoint(x: 450, y: 140), withAttributes: headerAttributes)
            
            contextGraphics.move(to: CGPoint(x: 40, y: 160))
            contextGraphics.addLine(to: CGPoint(x: 555, y: 160))
            contextGraphics.strokePath()
            
            // Draw Rows
            let rowFont = UIFont.systemFont(ofSize: 10)
            let rowAttributes = [NSAttributedString.Key.font: rowFont]
            var currentY = 175.0
            
            for customer in customers.prefix(20) {
                if currentY > 780 { // Page break check
                    context.beginPage()
                    currentY = 40.0
                }
                
                customer.fullName.draw(at: CGPoint(x: 40, y: currentY), withAttributes: rowAttributes)
                customer.phone.draw(at: CGPoint(x: 120, y: currentY), withAttributes: rowAttributes)
                customer.vipLevel.displayName.draw(at: CGPoint(x: 240, y: currentY), withAttributes: rowAttributes)
                (customer.skinType?.displayName ?? "未註記").draw(at: CGPoint(x: 350, y: currentY), withAttributes: rowAttributes)
                customer.createdAt.formattedDate.draw(at: CGPoint(x: 450, y: currentY), withAttributes: rowAttributes)
                
                currentY += 24.0
            }
            
            if customers.count > 20 {
                let noteStr = "* 僅顯示前 20 筆客戶，其餘 \(customers.count - 20) 筆請在 App 中查看全量篩選數據。"
                noteStr.draw(at: CGPoint(x: 40, y: currentY + 10), withAttributes: metaAttributes)
            }
        }
        
        return data
    }
    
    static func generateRevenueReport(invoices: [Invoice]) -> Data? {
        let pdfMetaData = [
            kCGPDFContextAuthor as String: "AI Beauty CRM",
            kCGPDFContextSubject as String: "財務營收報表"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 595.2
        let pageHeight = 842.0
        let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Draw Header Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0)
            ]
            let titleText = "醫美財務營收統計表"
            titleText.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)
            
            // Subtitle
            let metaFont = UIFont.systemFont(ofSize: 11)
            let metaAttributes = [NSAttributedString.Key.font: metaFont, NSAttributedString.Key.foregroundColor: UIColor.gray]
            let dateStr = "生成日期: \(Date().formattedDateTime)"
            dateStr.draw(at: CGPoint(x: 40, y: 75), withAttributes: metaAttributes)
            
            let totalRevenue = invoices.reduce(0.0) { $0 + $1.amount }
            let totalStr = "交易總筆數: \(invoices.count) 筆 • 實收營業總額: \(totalRevenue.formattedCurrency)"
            totalStr.draw(at: CGPoint(x: 40, y: 92), withAttributes: metaAttributes)
            
            // Divider
            let contextGraphics = context.cgContext
            contextGraphics.setStrokeColor(UIColor.lightGray.cgColor)
            contextGraphics.setLineWidth(1.0)
            contextGraphics.move(to: CGPoint(x: 40, y: 120))
            contextGraphics.addLine(to: CGPoint(x: 555, y: 120))
            contextGraphics.strokePath()
            
            // List Header
            let headerFont = UIFont.boldSystemFont(ofSize: 12)
            let headerAttributes = [NSAttributedString.Key.font: headerFont]
            
            "發票號碼".draw(at: CGPoint(x: 40, y: 140), withAttributes: headerAttributes)
            "客戶".draw(at: CGPoint(x: 160, y: 140), withAttributes: headerAttributes)
            "購買項目".draw(at: CGPoint(x: 240, y: 140), withAttributes: headerAttributes)
            "金額 (NT$)".draw(at: CGPoint(x: 380, y: 140), withAttributes: headerAttributes)
            "購買分店".draw(at: CGPoint(x: 470, y: 140), withAttributes: headerAttributes)
            
            contextGraphics.move(to: CGPoint(x: 40, y: 160))
            contextGraphics.addLine(to: CGPoint(x: 555, y: 160))
            contextGraphics.strokePath()
            
            // Rows
            let rowFont = UIFont.systemFont(ofSize: 10)
            let rowAttributes = [NSAttributedString.Key.font: rowFont]
            var currentY = 175.0
            
            for invoice in invoices.prefix(20) {
                if currentY > 780 {
                    context.beginPage()
                    currentY = 40.0
                }
                
                invoice.invoiceNumber.draw(at: CGPoint(x: 40, y: currentY), withAttributes: rowAttributes)
                (invoice.customer?.fullName ?? "未知").draw(at: CGPoint(x: 160, y: currentY), withAttributes: rowAttributes)
                invoice.packageName.draw(at: CGPoint(x: 240, y: currentY), withAttributes: rowAttributes)
                invoice.amount.formattedCurrency.draw(at: CGPoint(x: 380, y: currentY), withAttributes: rowAttributes)
                (invoice.branch?.name ?? "總店").draw(at: CGPoint(x: 470, y: currentY), withAttributes: rowAttributes)
                
                currentY += 24.0
            }
            
            if invoices.count > 20 {
                let noteStr = "* 僅顯示前 20 筆財務流水發票，其餘 \(invoices.count - 20) 筆請在 App 財務報表中查閱。"
                noteStr.draw(at: CGPoint(x: 40, y: currentY + 10), withAttributes: metaAttributes)
            }
        }
        
        return data
    }
}
