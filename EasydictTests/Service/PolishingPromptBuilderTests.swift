//
//  PolishingPromptBuilderTests.swift
//  EasydictTests
//
//  Created by twinkling on 2026/7/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Verifies the polishing task prompt structure that `PolishingPromptBuilder` emits for any
/// streaming engine. These are pure unit tests: no network, no service instance.
@Suite("Polishing Prompt Builder", .tags(.unit))
struct PolishingPromptBuilderTests {
    /// The builder always emits one system prompt, three few-shot pairs, and one final user prompt.
    @Test("Returns system, few-shot, and final user messages", .tags(.unit))
    func returnsSystemFewShotAndUserMessages() {
        let messages = PolishingPromptBuilder.messages(
            text: "She don't like the weather today.",
            sourceLanguage: .english
        )

        #expect(messages.count == 8)
        #expect(messages.first?.role == .system)
        #expect(messages.first?.content == PolishingPromptBuilder.polishingSystemPrompt)
        #expect(messages.filter { $0.role == .assistant }.count == 3)
        #expect(messages.last?.role == .user)
    }

    /// The final user prompt wraps the input text and names the source language.
    @Test("Final user message embeds input text and source language", .tags(.unit))
    func finalUserMessageEmbedsTextAndLanguage() {
        let text = "The book was wrote by an unknown author."
        let messages = PolishingPromptBuilder.messages(text: text, sourceLanguage: .english)

        let last = messages.last
        #expect(last?.role == .user)
        #expect(last?.content.contains(text) == true)
        #expect(last?.content.contains("English") == true)
    }
}
