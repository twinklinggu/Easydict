//
//  ReplaceActionEngineResolver.swift
//  Easydict
//
//  Created by twinkling on 2026/7/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Resolves the streaming engine for the replace actions, decoupling the
/// task (a prompt) from the engine. Eligible engines exclude task services
/// and `Doubao`; a stale selection falls back to `BuiltInAI`. See
/// `docs/adr/0001-decouple-polish-task-from-service.md`.
enum ReplaceActionEngineResolver {
    /// Filters the main window's configured services to engines
    /// eligible for the replace actions.
    static func eligibleEngines(services: [QueryService]) -> [QueryService] {
        services.filter { service in
            guard service.enabled,
                  service.enabledQuery,
                  service.isStream(),
                  let streamService = service as? StreamService,
                  streamService.supportsTaskMessageInjection
            else {
                return false
            }
            return true
        }
    }

    /// Resolves the engine for the persisted `type#uuid` selection,
    /// falling back to `BuiltInAI` when stale or empty.
    static func resolve(selection: String?, eligible: [QueryService]) -> QueryService {
        if let selection, !selection.isEmpty {
            for service in eligible where service.serviceTypeWithUniqueIdentifier() == selection {
                return service
            }
        }
        // Stale-selection fallback: a fresh BuiltInAI instance is
        // always usable out of the box.
        return QueryServiceFactory.shared.service(withTypeId: ServiceType.builtInAI.rawValue)
            ?? BuiltInAIService()
    }
}
