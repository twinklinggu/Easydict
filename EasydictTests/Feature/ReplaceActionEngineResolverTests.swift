//
//  ReplaceActionEngineResolverTests.swift
//  EasydictTests
//
//  Created by twinkling on 2026/7/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Verifies the replace-action engine picker: which configured services are eligible to run an
/// injected task prompt, and how a persisted `type#uuid` selection resolves (with `BuiltInAI` as
/// the stale/empty fallback). Pure unit tests; no network.
@Suite("Replace Action Engine Resolver", .tags(.unit))
struct ReplaceActionEngineResolverTests {
    // MARK: Internal

    /// Eligibility keeps only streaming engines that honor an injected task prompt, excluding
    /// non-streaming (`Google`) and task/specialized services (`Polishing`, `Summary`, `Doubao`).
    @Test("Eligible engines are BuiltInAI and OpenAI only", .tags(.unit))
    func eligibleEnginesFiltersToStreamingGeneralChat() {
        let services = Self.makeMixedServices()
        #expect(services.count == 6)

        let eligible = ReplaceActionEngineResolver.eligibleEngines(services: services)
        let eligibleTypeIDs = Set(eligible.map { $0.serviceType().rawValue })

        #expect(eligibleTypeIDs == ["BuiltInAI", "OpenAI"])
    }

    /// A selection matching an eligible service returns that service.
    @Test("Resolves selection to the matching eligible service", .tags(.unit))
    func resolvesMatchingSelection() {
        let resolved = ReplaceActionEngineResolver.resolve(
            selection: ServiceType.builtInAI.rawValue,
            eligible: Self.makeEligibleServices()
        )
        #expect(resolved.serviceTypeWithUniqueIdentifier() == "BuiltInAI")
    }

    /// A stale selection that matches no eligible service falls back to a fresh `BuiltInAIService`.
    @Test("Falls back to BuiltInAI for stale selection", .tags(.unit))
    func fallsBackToBuiltInAIForStaleSelection() {
        let resolved = ReplaceActionEngineResolver.resolve(
            selection: "StaleType#deadbeef",
            eligible: Self.makeEligibleServices()
        )
        #expect(resolved is BuiltInAIService)
    }

    /// A nil selection falls back to a fresh `BuiltInAIService`.
    @Test("Falls back to BuiltInAI for nil selection", .tags(.unit))
    func fallsBackToBuiltInAIForNilSelection() {
        let resolved = ReplaceActionEngineResolver.resolve(
            selection: nil,
            eligible: Self.makeEligibleServices()
        )
        #expect(resolved is BuiltInAIService)
    }

    // MARK: Private

    /// Builds a mixed list of streaming, non-streaming, and task services straight from the factory.
    private static func makeMixedServices() -> [QueryService] {
        [
            ServiceType.builtInAI.rawValue,
            ServiceType.openAI.rawValue,
            ServiceType.google.rawValue,
            ServiceType.polishing.rawValue,
            ServiceType.summary.rawValue,
            ServiceType.doubao.rawValue,
        ].map { QueryServiceFactory.shared.service(withTypeId: $0)! }
    }

    /// Builds the eligible engine list (BuiltInAI + OpenAI) used as resolve input.
    private static func makeEligibleServices() -> [QueryService] {
        [
            ServiceType.builtInAI.rawValue,
            ServiceType.openAI.rawValue,
        ].map { QueryServiceFactory.shared.service(withTypeId: $0)! }
    }
}
