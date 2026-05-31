//  ReportsView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReportViewModel()
    @Query private var customers: [Customer]
    @Query private var invoices: [Invoice]
    @Query private var packages: [TreatmentPackage]
    
    // PDF share sheet triggers
    @State private var pdfData: Data? = nil
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Date range picker header card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("選擇報表分析統計時間區間")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        DatePicker("起始日期 Start", selection: $viewModel.startDate, displayedComponents: .date)
                        DatePicker("截止日期 End", selection: $viewModel.endDate, displayedComponents: .date)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                    
                    // Report grid / selection list
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("選擇統計分析報表類型")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        ForEach(ReportType.allCases) { type in
                            NavigationLink(destination: ReportDetailView(type: type)) {
                                HStack(spacing: AppTheme.Spacing.md) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 22))
                                        .foregroundStyle(AppTheme.Colors.accent)
                                        .frame(width: 44, height: 44)
                                        .background(AppTheme.Colors.accent.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(type.rawValue)
                                            .font(AppTheme.Typography.body)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.Colors.textPrimary)
                                        
                                        Text(type.description)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppTheme.Colors.textTertiary)
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                                .shadow(color: .black.opacity(0.01), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xs)
                    
                    // Export Card Actions
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("統計數據匯出 Export Options")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        HStack(spacing: AppTheme.Spacing.md) {
                            Button {
                                exportPDF(type: .customer)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "doc.plaintext.fill")
                                        .font(.system(size: 24))
                                    Text("匯出客戶 PDF")
                                        .font(AppTheme.Typography.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(AppTheme.Colors.accent.opacity(0.12))
                                .foregroundStyle(AppTheme.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                            }
                            
                            Button {
                                exportPDF(type: .revenue)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 24))
                                    Text("匯出財務 PDF")
                                        .font(AppTheme.Typography.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(AppTheme.Colors.accentSecondary.opacity(0.12))
                                .foregroundStyle(AppTheme.Colors.accentSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                    .padding(.top, AppTheme.Spacing.xs)
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("系統統計報表")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(activityItems: [pdfData])
                }
            }
        }
    }
    
    private func exportPDF(type: ReportType) {
        if type == .customer {
            pdfData = PDFExportService.generateCustomerReport(customers: customers)
        } else {
            pdfData = PDFExportService.generateRevenueReport(invoices: invoices)
        }
        
        if pdfData != nil {
            showingShareSheet = true
        }
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReportsView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
