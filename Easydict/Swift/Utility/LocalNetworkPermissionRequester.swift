//
//  LocalNetworkPermissionRequester.swift
//  Easydict
//
//  Created by twinklinggu on 2026/07/24.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Network

/// Surfaces the macOS Local Network privacy permission prompt.
///
/// On macOS, a direct `URLSession` connection to a private/local IP (for example a local
/// Ollama or OpenAI-compatible endpoint such as `http://192.168.9.11:11434`) is gated by
/// Local Network privacy, but the permission prompt is only surfaced by local-network
/// discovery operations such as Bonjour browsing - not by the connection itself. Without
/// an explicit browse the connection is blocked with `NSURLErrorNotConnectedToInternet`
/// (-1009, "Local network prohibited") and no prompt ever appears, so the user can never
/// grant access.
///
/// This starts a short-lived `NWBrowser` for a Bonjour service type declared in
/// `NSBonjourServices` to surface the prompt. Browse results are ignored; the only purpose
/// is to trigger the prompt. Once granted, the permission persists (keyed to the app's code
/// identity) and direct local-IP `URLSession` connections succeed. Calling this again after
/// the user grants is a harmless no-op: the browse runs briefly and no further prompt shows.
enum LocalNetworkPermissionRequester {
    // MARK: Internal

    /// Starts a brief Bonjour browse to surface the Local Network permission prompt.
    static func requestIfNeeded() {
        guard browser == nil else { return }

        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        let activeBrowser = NWBrowser(
            for: .bonjour(type: bonjourServiceType, domain: nil),
            using: parameters
        )
        browser = activeBrowser
        activeBrowser.start(queue: .main)

        // A few seconds is enough to surface the prompt; stop browsing afterwards to
        // avoid ongoing mDNS traffic.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            activeBrowser.cancel()
            browser = nil
        }
    }

    // MARK: Private

    /// Bonjour service type used solely to trigger the Local Network permission prompt.
    /// Must be declared in `NSBonjourServices` in Info.plist.
    private static let bonjourServiceType = "_easydict._tcp"

    /// Retains the active browser so it is not deallocated before the prompt surfaces.
    private static var browser: NWBrowser?
}
