//
//  ChatMessage.swift
//  Easydict
//
//  Created by tisfeng on 2024/11/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

func systemMessage(queryType: EZQueryTextType) -> ChatMessage {
    switch queryType {
    case .dictionary:
        .init(role: .system, content: StreamService.dictSystemPrompt)
    default:
        .init(role: .system, content: StreamService.translationSystemPrompt)
    }
}

func chatMessagePair(userContent: String, assistantContent: String) -> [ChatMessage] {
    [
        .init(role: .user, content: userContent),
        .init(role: .assistant, content: assistantContent),
    ]
}

// MARK: - ChatMessage

struct ChatMessage {
    // MARK: - ChatRole

    enum ChatRole: String, Codable, Equatable, CaseIterable {
        case system
        case user
        case assistant
        case tool
        case model // Gemini role, equal to OpenAI assistant role.
    }

    let role: ChatRole
    let content: String
}

// MARK: - AIToolType

enum AIToolType {
    case polishing
    case summary
}

// MARK: - ChatQueryParam

struct ChatQueryParam {
    // MARK: Lifecycle

    init(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        queryType: EZQueryTextType,
        enableSystemPrompt: Bool,
        chatMessages: [ChatMessage]? = nil
    ) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.queryType = queryType
        self.enableSystemPrompt = enableSystemPrompt
        self.chatMessages = chatMessages
    }

    // MARK: Internal

    let text: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let queryType: EZQueryTextType
    let enableSystemPrompt: Bool

    /// Pre-built task messages to run instead of the engine's default
    /// prompt path.
    ///
    /// When non-empty, `chatMessageDicts` returns these as-is so any
    /// streaming engine runs the task (e.g. polish) on its own backend.
    /// See `docs/adr/0001-decouple-polish-task-from-service.md`.
    let chatMessages: [ChatMessage]?

    func unpack() -> (String, Language, Language, EZQueryTextType, Bool) {
        (text, sourceLanguage, targetLanguage, queryType, enableSystemPrompt)
    }
}
