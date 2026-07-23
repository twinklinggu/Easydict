//
//  PolishingService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

@objc(EZPolishingService)
class PolishingService: AIToolService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("polishing_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .polishing
    }

    // MARK: Internal

    override var supportsTaskMessageInjection: Bool { false }

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        let (text, sourceLanguage, _, _, _) = chatQuery.unpack()
        return PolishingPromptBuilder.messages(text: text, sourceLanguage: sourceLanguage)
    }
}

// swiftlint:enable line_length
