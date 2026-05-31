
//  Invoice.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class Invoice {
    var invoiceNumber: String
    var packageName: String
    var amount: Double
    var paymentMethod: PaymentMethod
    var salesConsultant: String
    var purchaseDate: Date
    var notes: String
    
    // Relationships
    var customer: Customer?
    
    @Relationship(deleteRule: .nullify)
    var branch: Branch?
    
    init(
        invoiceNumber: String = "INV-" + UUID().uuidString.prefix(6).uppercased(),
        packageName: String,
        amount: Double,
        paymentMethod: PaymentMethod = .creditCard,
        salesConsultant: String = "",
        purchaseDate: Date = Date(),
        notes: String = ""
    ) {
        self.invoiceNumber = invoiceNumber
        self.packageName = packageName
        self.amount = amount
        self.paymentMethod = paymentMethod
        self.salesConsultant = salesConsultant
        self.purchaseDate = purchaseDate
        self.notes = notes
    }
    
    var customerName: String {
        customer?.fullName ?? "未指定"
    }
    
    var branchName: String {
        branch?.name ?? "未指定"
    }
    
    var formattedAmount: String {
        amount.formattedCurrency
    }
}
