//
//  PolishingPromptBuilder.swift
//  Easydict
//
//  Created by twinkling on 2026/7/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/// Builds the polishing task prompt as `[ChatMessage]`, decoupling the
/// polish task from the engine service that runs it. `PolishingService`
/// and the replace-action polish both use this as the single source of
/// truth. See `docs/adr/0001-decouple-polish-task-from-service.md`.
enum PolishingPromptBuilder {
    // MARK: Internal

    static let polishingSystemPrompt = """
    You are a text polishing expert skilled in refining and enhancing written content. Your task is to improve the clarity, coherence, grammar, and overall quality of the text while maintaining the original meaning and intent. Focus on correcting grammatical errors, improving sentence structure, and enhancing readability. Ensure the polished text is natural and fluent. Only return the polished text, without including redundant quotes or additional notes.
    """

    /// Polishing refines text in its own (source) language; the target
    /// language is intentionally ignored.
    static func messages(text: String, sourceLanguage: Language) -> [ChatMessage] {
        let prompt = polishingPrompt(text: text, in: sourceLanguage)

        let englishFewShot = [
            chatMessagePair(
                userContent:
                "Polish the following English text to improve its clarity and coherence: \"\"\"The book was wrote by an unknown author but it was very popular among readers.\"\"\"",

                assistantContent:
                "The book was written by an unknown author, but it was very popular among readers."
            ),
            chatMessagePair(
                userContent:
                "Polish the following English text to improve its grammar and readability: \"\"\"She don’t like the weather today, it makes her feel bad.\"\"\"",
                assistantContent: "She doesn't like the weather today; it makes her feel bad."
            ),
            chatMessagePair(
                userContent:
                "Polish the following English text to enhance its overall quality: \"\"\"The project was successful although we faced many problems in the beginning.\"\"\"",
                assistantContent:
                "The project was successful despite facing many problems in the beginning."
            ),
        ].flatMap { $0 }

        var messages: [ChatMessage] = [
            .init(role: .system, content: polishingSystemPrompt),
        ]
        messages.append(contentsOf: englishFewShot)
        messages.append(.init(role: .user, content: prompt))

        return messages
    }

    // MARK: Private

    private static func polishingPrompt(text: String, in sourceLanguage: Language) -> String {
        "Polish the following \(sourceLanguage.queryLanguageName) text to improve its clarity, coherence, grammar, and overall quality while maintaining the original meaning and intent: \"\"\"\(text)\"\"\""
    }
}

// swiftlint:enable line_length
