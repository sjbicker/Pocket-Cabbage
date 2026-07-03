//
//  APIConfig.swift
//  Pocket Cabbage
//
//  The single source of truth for talking to the PocketCabbage backend gateway.
//  Every network request in the app is routed through `baseURL` — no third-party
//  API keys ever live in the app binary (the FastAPI middleware brokers them).
//

import Foundation

/// Global, compile-time configuration for the backend gateway.
///
/// ⚠️ Before going live, change `baseURL` to the production host
/// (e.g. `https://pocketcabbage.fly.dev`) and flip `appAttestEnabled` to `true`.
enum APIConfig {

    /// Base URL of the Python middleware (`Backend for ShelfPlan/main.py`).
    ///
    /// Defaults to the local `uvicorn` dev server. This is the ONE constant to
    /// update before shipping.
    static let baseURL = URL(string: "http://localhost:8080")!

    /// When `false`, the app authenticates with a dev attestation (device id as
    /// the App Attest key id) so the whole stack is testable without attestation
    /// hardware. The backend must run with `APP_ATTEST_REQUIRED=false`.
    ///
    /// Flip to `true` once real `DCAppAttestService` verification is wired on
    /// both the app (`AppAttestProvider`) and the backend.
    static let appAttestEnabled = false

    /// Default ZIP used for pricing until the onboarding profile supplies one.
    static let defaultZip = "45201"

    /// Shared request timeout (seconds) — AI/vision calls can be slow.
    static let requestTimeout: TimeInterval = 45
}
