//  ChatBubbleView.swift
//  AICustomerResverSystem

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    
    private var messageAttributedString: AttributedString {
        do {
            return try AttributedString(markdown: message.content)
        } catch {
            return AttributedString(message.content)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            if !message.isFromUser {
                // AI Avatar Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.Colors.primaryGradient)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.Colors.accent.opacity(0.4), lineWidth: 1))
            } else {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Message bubble container
                Text(messageAttributedString)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(message.isFromUser ? .white : AppTheme.Colors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        BubbleShape(isFromUser: message.isFromUser)
                            .fill(message.isFromUser ? AppTheme.Colors.primary : Color(.systemGray6))
                    )
                    .overlay(
                        BubbleShape(isFromUser: message.isFromUser)
                            .stroke(message.isFromUser ? AppTheme.Colors.accent.opacity(0.2) : Color(.systemGray5), lineWidth: 0.5)
                    )
                
                // Timestamp
                Text(message.timestamp.formattedTime)
                    .font(AppTheme.Typography.caption2)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .padding(.horizontal, 4)
            }
            
            if message.isFromUser {
                // User Avatar Icon
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.Colors.accent.opacity(0.2))
                    .clipShape(Circle())
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xs)
    }
}

// MARK: - Bubble Custom Shape
struct BubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let radius: CGFloat = 14
        
        if isFromUser {
            // Rounded corners on all except bottom right (or standard chat bubble)
            let pathRect = RRect(
                rect: rect,
                topLeft: radius,
                topRight: radius,
                bottomLeft: radius,
                bottomRight: 2
            )
            path.addPath(pathRect)
        } else {
            // Flat bottom left for incoming bubble
            let pathRect = RRect(
                rect: rect,
                topLeft: radius,
                topRight: radius,
                bottomLeft: 2,
                bottomRight: radius
            )
            path.addPath(pathRect)
        }
        
        return path
    }
    
    private func RRect(
        rect: CGRect,
        topLeft: CGFloat,
        topRight: CGFloat,
        bottomLeft: CGFloat,
        bottomRight: CGFloat
    ) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Start top-left
        path.move(to: CGPoint(x: topLeft, y: 0))
        
        // Line to top-right
        path.addLine(to: CGPoint(x: w - topRight, y: 0))
        path.addArc(center: CGPoint(x: w - topRight, y: topRight), radius: topRight, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        
        // Line to bottom-right
        path.addLine(to: CGPoint(x: w, y: h - bottomRight))
        path.addArc(center: CGPoint(x: w - bottomRight, y: h - bottomRight), radius: bottomRight, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        
        // Line to bottom-left
        path.addLine(to: CGPoint(x: bottomLeft, y: h))
        path.addArc(center: CGPoint(x: bottomLeft, y: h - bottomLeft), radius: bottomLeft, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        
        // Line back to top-left
        path.addLine(to: CGPoint(x: 0, y: topLeft))
        path.addArc(center: CGPoint(x: topLeft, y: topLeft), radius: topLeft, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        
        return path
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.md) {
        ChatBubbleView(message: ChatMessage(content: "哈囉，我想查詢客戶林雅琪的手機與方案資訊。", isFromUser: true))
        ChatBubbleView(message: ChatMessage(content: "🔍 **AI 智能客戶速查系統**\n\n找到客戶 **林雅琪 (女)**\n• **VIP 等級**: 白金卡 👑\n• **療程**: 皮秒雷射 (剩餘 **1** 堂)\n\n建議在其今日預約結束後，主動推薦其續購。", isFromUser: false))
    }
    .padding()
    .background(AppTheme.Colors.background)
}
