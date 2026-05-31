//  UserGuideView.swift
//  AICustomerResverSystem
//

import SwiftUI

struct UserGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header Hero
                VStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.bottom, 4)
                    
                    Text("醫美智能管理系統")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.accent)
                    
                    Text("系統操作使用手冊")
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
                
                // 1. Overview
                GroupBox(label: Label("系統設計概述", systemImage: "info.circle.fill").foregroundStyle(AppTheme.Colors.accent)) {
                    Text("本系統專為頂級醫美診所打造，底層基於 Apple 官方最新的原生 SwiftData 離線資料庫，搭配離線智能語義 AI 助理與高解析 PDF 報表匯出功能，提供全方位的高效、尊貴管理體驗。")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.top, 4)
                        .lineSpacing(4)
                }
                
                // 2. Modules
                GroupBox(label: Label("系統核心模組指引", systemImage: "square.grid.2x2.fill").foregroundStyle(AppTheme.Colors.accent)) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        guideSectionItem(title: "1. 數據儀表板 (Dashboard)", content: "實時匯總顧客總量、累計合約、賸餘堂數及今日待辦預約。整合 Swift Charts 展示近 6 個月營業額增長趨勢圖，並有 AI 主動推薦營運決策。")
                        guideSectionItem(title: "2. 客戶檔案 360° (Customer)", content: "管理電話、生日、LINE ID。特設「醫療安全檔案」記錄過敏史、膚質分類與諮詢病史；分頁卡一鍵切換該客戶的所有購買合約、預約日程及流水發票。")
                        guideSectionItem(title: "3. 日曆排程引擎 (Scheduler)", content: "支援日 (9-20點區間表)、週 (七日橫卡)、月 (日曆彩點網格) 三維切換，自動檢驗預約時間防呆，支援狀態即時轉換（如已到店、已核銷等）。")
                        guideSectionItem(title: "4. 方案合約與核銷 (Packages)", content: "監控合約賸餘堂數，低於30%時進度條自動變更為警告色。核銷時支援上傳術前術後對比照、美容師核章與顧客螢幕電子手寫簽名。")
                        guideSectionItem(title: "5. 財務與發票 (Financial)", content: "精準統計實收營業額、客單價、均單價及支付途徑佔比（如現金、信用卡、LINE Pay、Apple Pay分期等）。")
                    }
                    .padding(.top, 4)
                }
                
                // 3. AI Assistant
                GroupBox(label: Label("🤖 離線 AI 語義助理提問", systemImage: "sparkles").foregroundStyle(AppTheme.Colors.accent)) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("點擊「AI 助理」頁面即可進入對話。本系統採用本機離線語義引擎，輸入以下內容秒級解析數據：")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineSpacing(3)
                        
                        Divider().padding(.vertical, 2)
                        
                        aiQueryRow(query: "查詢 0922-111-222", desc: "速查匹配客戶的VIP卡、剩餘堂數及下次確認預約")
                        aiQueryRow(query: "林雅琪", desc: "調閱該顧客膚質病史、臨床諮詢備註與未消耗療程")
                        aiQueryRow(query: "今日預約", desc: "盤點今日預約行程流水與跨據點班表")
                        aiQueryRow(query: "剩餘堂數", desc: "警示賸餘 <= 2 堂的療程包，以利續購銷售推廣")
                        aiQueryRow(query: "營收業績", desc: "即時統計本月營業總額、均單及支付途徑佔比")
                    }
                    .padding(.top, 4)
                }
                
                // 4. Reports & Exports
                GroupBox(label: Label("📄 A4 PDF 報告匯出", systemImage: "doc.text.fill").foregroundStyle(AppTheme.Colors.accent)) {
                    Text("在「更多 -> 報表」中，選擇客戶報表或財務報表，點選「匯出 PDF 報表」即可調起 iOS 原生分享面板（Share Sheet），支援 AirDrop 傳送、AirPrint 一鍵列印紙本或 LINE 傳送財務主管。")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.top, 4)
                        .lineSpacing(4)
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("系統使用指南")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func guideSectionItem(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(content)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(3)
        }
        .padding(.vertical, 2)
    }
    
    private func aiQueryRow(query: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("• \(query)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.Colors.accent)
            Text("  \(desc)")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        UserGuideView()
    }
}
