//  AIAssistantViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
public class AIAssistantViewModel {
    public var inputText: String = ""
    public var isTyping: Bool = false
    
    public var suggestedQueries: [String] = [
        "林雅琪",
        "預約排程摘要",
        "剩餘堂數警示",
        "本月營收業績"
    ]
    
    private let aiService = AIService()
    
    public init() {}
    
    @MainActor
    public func sendMessage(context: ModelContext) async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        // 1. Save user message
        let userMessage = ChatMessage(content: query, isFromUser: true)
        context.insert(userMessage)
        inputText = ""
        
        // 2. Start thinking/typing animation
        isTyping = true
        
        // 3. Process with AI Service
        let response = await aiService.processQuery(query, context: context)
        
        // 4. Save AI message
        let aiMessage = ChatMessage(content: response, isFromUser: false)
        context.insert(aiMessage)
        
        isTyping = false
        
        // Save database context
        try? context.save()
    }
    
    @MainActor
    public func clearChat(context: ModelContext) {
        do {
            let desc = FetchDescriptor<ChatMessage>()
            let msgs = (try? context.fetch(desc)) ?? []
            for msg in msgs {
                context.delete(msg)
            }
            try context.save()
        } catch {
            print("Error clearing AI chat history: \(error)")
        }
    }
}
