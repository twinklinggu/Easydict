//
//  ActionManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/29.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Defaults
import Foundation
import SelectedTextKit

// MARK: - ActionManager

/// Singleton class responsible for handling various application actions
@objc(EZActionManager)
class ActionManager: NSObject {
    // MARK: Internal

    // MARK: - Singleton

    @objc static let shared = ActionManager()

    // MARK: - Text Field Detection and Access

    // MARK: - Public Methods

    /// Translate selected text and replace it with the translation result
    func translateAndReplace() async {
        logInfo("Translate and Replace")
        await executeTextReplacementAction(.translate)
    }

    /// Polish selected text and replace it with the polished result
    func polishAndReplace() async {
        logInfo("Polish and Replace")
        await executeTextReplacementAction(.polish)
    }

    // MARK: Private

    /// Type of text processing action
    private enum ProcessingType {
        case translate
        case polish
    }

    private let systemUtility = SystemUtility.shared

    // MARK: - Core Action Methods

    /// Common method to execute text replacement actions
    private func executeTextReplacementAction(_ type: ProcessingType) async {
        let enableSelectAll = Defaults[.autoSelectAllTextFieldText]
        let elementInfo = await systemUtility.focusedElementInfo(enableSelectAll: enableSelectAll)

        // Prepare translation request
        var queryText = elementInfo.focusedText
        if queryText?.isEmpty ?? true {
            queryText = await systemUtility.getSelectedText()
        }

        guard let queryText, !queryText.isEmpty else {
            logInfo("No text selected or focused for \(type), skipping action")
            return
        }

        // Prepare translation request
        let engine = resolveEngine()
        guard let request = await prepareTranslationRequest(
            queryText: queryText,
            type: type,
            engine: engine
        ) else {
            return
        }

        // Execute the streaming service
        await performStreamingService(engine: engine, request: request, elementInfo: elementInfo)
    }

    // MARK: - Helper Methods

    /// Prepare translation request from text field information
    /// - Parameters:
    ///   - queryText: The text to process.
    ///   - type: The type of processing (translate or polish)
    /// - Returns: A configured TranslationRequest or nil if preparation fails
    private func prepareTranslationRequest(
        queryText: String,
        type: ProcessingType,
        engine: QueryService
    ) async
        -> TranslationRequest? {
        // Detect language and target
        let queryModel = try? await DetectManager().detectText(queryText)
        guard let detectedLanguage = queryModel?.detectedLanguage,
              let targetLanguage = queryModel?.queryTargetLanguage
        else {
            logError("Failed to detect target language, skipping \(type) and replace")
            return nil
        }

        // The engine (not the task) runs the request: translate uses the
        // engine's default prompt path; polish injects the polishing prompt
        // so any streaming engine runs it. See
        // docs/adr/0001-decouple-polish-task-from-service.md.
        var request = TranslationRequest(
            text: queryText,
            sourceLanguage: detectedLanguage.code,
            targetLanguage: targetLanguage.code,
            serviceType: engine.serviceTypeWithUniqueIdentifier(),
            queryType: .translation
        )

        if type == .polish {
            // Polish refines text in its source language; the target
            // language is ignored.
            request.chatMessages = PolishingPromptBuilder.messages(
                text: queryText,
                sourceLanguage: detectedLanguage
            )
        }

        return request
    }

    /// Resolves the streaming engine for the replace actions from the
    /// main window's configured services, falling back to `BuiltInAI`
    /// when the persisted selection is stale.
    private func resolveEngine() -> QueryService {
        let eligible = ReplaceActionEngineResolver.eligibleEngines(
            services: LocalStorage.shared().allServices(.main)
        )
        return ReplaceActionEngineResolver.resolve(
            selection: Defaults[.replaceActionEngineServiceTypeId],
            eligible: eligible
        )
    }

    // MARK: - Streaming Service Methods

    /// Perform translation or polishing using a streaming service
    private func performStreamingService(
        engine: QueryService,
        request: TranslationRequest,
        elementInfo: FocusedElementInfo
    ) async {
        guard let streamService = engine as? StreamService else {
            logError("\(engine.name()) does not support streaming")
            await surfaceFailure(serviceName: engine.name(), error: nil)
            return
        }

        logInfo("Using model: \(streamService.model)")

        do {
            try Task.checkCancellation()
            let contentStream = try await streamService.contentStreamTranslate(request: request)
            try Task.checkCancellation()
            await replaceTextWithStream(contentStream, elementInfo: elementInfo)
        } catch {
            if Task.isCancelled {
                logInfo("Streaming task cancelled")
            } else {
                logError("stream failed: \(error.localizedDescription)")
                await surfaceFailure(serviceName: streamService.name(), error: error)
            }
        }
    }

    /// Surfaces a replace-action failure as a visible toast (missing API
    /// key, missing CLI binary, streaming error, etc.). Cancellation is
    /// intentionally not surfaced.
    @MainActor
    private func surfaceFailure(serviceName: String, error: Error?) async {
        let detail = error?.localizedDescription ?? String(localized: "replace_action.error.no_engine")
        let message = String(
            localized: "replace_action.error.failed \(serviceName) \(detail)"
        )
        EZToast.showText(message)
    }

    /// Replace text with streaming data
    @MainActor
    private func replaceTextWithStream(
        _ contentStream: AsyncThrowingStream<String, Error>,
        elementInfo: FocusedElementInfo
    ) async {
        logInfo("Replacing text with streaming content")

        // For avoding polluting user pasteboard content, we need to save and restore it when AX is not supported.
        let pasteboard = NSPasteboard.general
        var snapshotItems: [NSPasteboardItem]?

        let isSupportedAX = elementInfo.isSupportedAXElement
        if !isSupportedAX {
            snapshotItems = pasteboard.backupItems()
        }

        do {
            let textStrategy = systemUtility.textStrategies(for: elementInfo)

            /**
             - Note:
             For GitHub web text area, if select all and insert empty string,
             it will clear the text area and lose focus.
             So we do not insert empty string.
             */

            var reuslt = ""
            for try await content in contentStream where !content.isEmpty {
                //                logInfo("Received streaming content chunk: \(content.prettyJSONString)")

                reuslt += content
                await systemUtility.insertText(content, using: textStrategy)
            }
            logInfo("Final replacement result: \(reuslt.prettyJSONString)")
        } catch {
            logError("Streaming replacement failed: \(error)")
        }

        if let snapshotItems, !isSupportedAX {
            pasteboard.restoreItems(snapshotItems)
        }
    }
}
