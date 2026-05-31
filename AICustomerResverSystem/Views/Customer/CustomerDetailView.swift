//  CustomerDetailView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct CustomerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let customer: Customer
    
    @State private var selectedSection = 0
    @State private var showingEditForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Header Profile Card
                VStack(spacing: AppTheme.Spacing.sm) {
                    let initials = String(customer.fullName.prefix(2))
                    Text(initials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(customer.vipLevel == .gold || customer.vipLevel == .diamond ? .white : AppTheme.Colors.textPrimary)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(customer.vipLevel.color.opacity(customer.vipLevel == .gold || customer.vipLevel == .diamond ? 1.0 : 0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(customer.vipLevel.color.opacity(0.4), lineWidth: 2)
                        )
                    
                    VStack(spacing: 4) {
                        Text(customer.fullName)
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        HStack(spacing: 6) {
                            VIPBadge(level: customer.vipLevel)
                            
                            Text("ID: \(customer.customerID.prefix(8))")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 3)
                .padding(.horizontal, AppTheme.Spacing.md)
                
                // Segmented Control Picker
                Picker("詳細資料分類", selection: $selectedSection) {
                    Text("基本資料").tag(0)
                    Text("醫療資訊").tag(1)
                    Text("療程方案").tag(2)
                    Text("預約記錄").tag(3)
                    Text("消費記錄").tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)
                
                // Content based on picker selection
                VStack(spacing: AppTheme.Spacing.md) {
                    switch selectedSection {
                    case 0:
                        basicInfoSection
                    case 1:
                        medicalInfoSection
                    case 2:
                        packagesSection
                    case 3:
                        appointmentsSection
                    case 4:
                        purchasesSection
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationTitle(customer.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditForm = true
                } label: {
                    Text("編輯")
                        .foregroundStyle(AppTheme.Colors.accent)
                        .font(AppTheme.Typography.headline)
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            CustomerFormView(customer: customer)
        }
    }
    
    // MARK: - Basic Info Section View
    private var basicInfoSection: some View {
        VStack(spacing: 1) {
            infoRow(label: "性別 Gender", value: customer.gender.displayName, icon: "figure.stand")
            infoRow(label: "生日 Birthday", value: customer.birthday?.formattedDate ?? "未設定", icon: "gift")
            infoRow(label: "年齡 Age", value: customer.birthday != nil ? "\(customer.birthday!.age) 歲" : "未設定", icon: "birthday.cake")
            infoRow(label: "電話 Phone", value: customer.phone, icon: "phone")
            infoRow(label: "Email", value: customer.email.isEmpty ? "未設定" : customer.email, icon: "envelope")
            infoRow(label: "LINE ID", value: customer.lineID.isEmpty ? "未設定" : customer.lineID, icon: "message")
            infoRow(label: "地址 Address", value: customer.address.isEmpty ? "未設定" : customer.address, icon: "mappin.and.ellipse")
            infoRow(label: "加入日期", value: customer.createdAt.formattedDate, icon: "calendar")
            
            if !customer.notes.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.accent)
                        Text("備註事項")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Text(customer.notes)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Medical Info Section View
    private var medicalInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            medicalCard(title: "膚質分類 Skin Type", content: customer.skinType?.displayName ?? "未註記", icon: "face.smiling", color: AppTheme.Colors.accentSecondary)
            
            medicalCard(title: "過敏病史 Allergy History", content: customer.allergyHistory.isEmpty ? "無過敏紀錄" : customer.allergyHistory, icon: "exclamationmark.triangle.fill", color: AppTheme.Colors.danger)
            
            medicalCard(title: "治療病史 Treatment History", content: customer.treatmentHistory.isEmpty ? "無歷史治療紀錄" : customer.treatmentHistory, icon: "stethoscope", color: AppTheme.Colors.info)
            
            medicalCard(title: "專業諮詢紀錄 Consultation Notes", content: customer.consultationNotes.isEmpty ? "無備忘諮詢紀錄" : customer.consultationNotes, icon: "doc.text.fill", color: AppTheme.Colors.accent)
        }
    }
    
    // MARK: - Packages Section View
    private var packagesSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let userPackages = customer.packages
            if userPackages.isEmpty {
                EmptyStateView(
                    icon: "bag.badge.minus",
                    title: "無購買任何療程",
                    message: "此客戶目前沒有購買或尚未使用任何療程包。"
                )
            } else {
                ForEach(userPackages) { package in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text(package.treatmentName)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            VIPBadge(level: customer.vipLevel, compact: true)
                        }
                        
                        SessionProgressBar(used: package.sessionsUsed, total: package.totalSessions)
                        
                        HStack {
                            Text("分店: \(package.purchaseBranch?.name ?? "台北總店")")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                            Spacer()
                            Text("購買於: \(package.purchaseDate.formattedDate)")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Appointments Section View
    private var appointmentsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let appts = customer.appointments.sorted(by: { $0.appointmentDate > $1.appointmentDate })
            if appts.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.minus",
                    title: "無預約紀錄",
                    message: "此客戶目前沒有任何預約行程紀錄。"
                )
            } else {
                ForEach(appts) { appointment in
                    HStack(spacing: AppTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appointment.appointmentDate.formattedDate)
                                .font(AppTheme.Typography.callout)
                                .fontWeight(.bold)
                            Text("\(appointment.startTime.formattedTime) - \(appointment.endTime.formattedTime)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(appointment.status.color)
                            .frame(width: 3, height: 35)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appointment.treatmentItem)
                                .font(AppTheme.Typography.body)
                                .fontWeight(.semibold)
                            Text("醫師: \(appointment.doctor.isEmpty ? "未指定" : appointment.doctor) / 美容師: \(appointment.beautician.isEmpty ? "未指定" : appointment.beautician)")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: appointment.status, compact: true)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Purchases Section View
    private var purchasesSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let invoices = customer.invoices.sorted(by: { $0.purchaseDate > $1.purchaseDate })
            if invoices.isEmpty {
                EmptyStateView(
                    icon: "creditcard.trianglebadge.exclamationmark",
                    title: "無消費紀錄",
                    message: "此客戶目前沒有開立任何發票或消費紀錄。"
                )
            } else {
                ForEach(invoices) { invoice in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invoice.packageName)
                                .font(AppTheme.Typography.body)
                                .fontWeight(.semibold)
                            Text("單號: \(invoice.invoiceNumber)")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                            Text("經手人: \(invoice.salesConsultant.isEmpty ? "未註記" : invoice.salesConsultant) • \(invoice.purchaseDate.formattedDate)")
                                .font(AppTheme.Typography.caption2)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(invoice.amount.formattedCurrency)
                                .font(AppTheme.Typography.callout)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.accent)
                            
                            PaymentBadge(method: invoice.paymentMethod)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                }
                
                // Total spending summary
                let totalSpent = invoices.reduce(0.0, { $0 + $1.amount })
                HStack {
                    Text("累計消費金額")
                        .font(AppTheme.Typography.headline)
                    Spacer()
                    Text(totalSpent.formattedCurrency)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            }
        }
    }
    
    // MARK: - Row helper
    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 20)
            
            Text(label)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
    }
    
    // MARK: - Medical Card helper
    private func medicalCard(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Text(content)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .stroke(color.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 3)
    }
}
