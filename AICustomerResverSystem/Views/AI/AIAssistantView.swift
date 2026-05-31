//  AIAssistantView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIAssistantViewModel()
    @Query(sort: \ChatMessage.timestamp, order: .forward) private var chatHistory: [ChatMessage]
    
    init() {}
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Gradient header details
                VStack(spacing: AppTheme.Spacing.xs) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("醫美智能語義小助手")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.accent)
                            
                            Text("AI 智能助理")
                                .font(AppTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.clearChat(context: modelContext)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.primaryGradient)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                
                // Chat bubbles or suggested chips
                if chatHistory.isEmpty {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        Spacer()
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 64))
                            .foregroundStyle(AppTheme.Colors.accent)
                            .symbolEffect(.pulse, options: .repeating)
                        
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("歡迎使用 AI 智能客服小幫手")
                                .font(AppTheme.Typography.title3)
                                .fontWeight(.bold)
                            Text("我是您的診所營運助理。我可以幫您速查客戶資料、預約排程動態、到期堂數警示與月度業績。您可以試著點選下方快捷提問：")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 300)
                        }
                        
                        // Suggestion query chips grid
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(viewModel.suggestedQueries, id: \.self) { query in
                                Button {
                                    viewModel.inputText = query
                                } label: {
                                    HStack {
                                        Text(query)
                                            .font(AppTheme.Typography.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppTheme.Colors.accent)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.accent)
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.Colors.accent.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                            .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .frame(maxWidth: 280)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .frame(maxHeight: .infinity)
                } else {
                    // Chat Scroll View
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.md) {
                                ForEach(chatHistory) { message in
                                    ChatBubbleView(message: message)
                                        .id(message.persistentModelID)
                                }
                                
                                // Typing Indicator
                                if viewModel.isTyping {
                                    HStack {
                                        typingDotsView
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray6))
                                            .clipShape(BubbleShape(isFromUser: false))
                                            .overlay(BubbleShape(isFromUser: false).stroke(Color(.systemGray5), lineWidth: 0.5))
                                        
                                        Spacer()
                                    }
                                    .padding(.leading, 42)
                                    .id("typing")
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.md)
                        }
                        .onChange(of: chatHistory.count) { _, _ in
                            if let last = chatHistory.last {
                                withAnimation(AppTheme.Animations.smooth) {
                                    proxy.scrollTo(last.persistentModelID, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isTyping) { _, isTyping in
                            if isTyping {
                                withAnimation(AppTheme.Animations.smooth) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            if let last = chatHistory.last {
                                proxy.scrollTo(last.persistentModelID, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Bottom input bar
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("向 AI 提問...", text: $viewModel.inputText)
                            .font(AppTheme.Typography.body)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                            .onSubmit {
                                Task {
                                    await viewModel.sendMessage(context: modelContext)
                                }
                            }
                        
                        Button {
                            Task {
                                await viewModel.sendMessage(context: modelContext)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(viewModel.inputText.isEmpty ? AppTheme.Colors.textTertiary : AppTheme.Colors.accent)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.inputText.isEmpty)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                }
            }
            .background(AppTheme.Colors.background)
        }
    }
    
    // MARK: - Typing Dots view
    private var typingDotsView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppTheme.Colors.textTertiary)
                .frame(width: 6, height: 6)
                .offset(y: typingOffset(delay: 0))
            Circle()
                .fill(AppTheme.Colors.textTertiary)
                .frame(width: 6, height: 6)
                .offset(y: typingOffset(delay: 0.2))
            Circle()
                .fill(AppTheme.Colors.textTertiary)
                .frame(width: 6, height: 6)
                .offset(y: typingOffset(delay: 0.4))
        }
        .frame(height: 12)
    }
    
    @State private var bounce = false
    
    private func typingOffset(delay: Double) -> CGFloat {
        bounce ? -4 : 0
    }
}

#Preview {
    AIAssistantView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
