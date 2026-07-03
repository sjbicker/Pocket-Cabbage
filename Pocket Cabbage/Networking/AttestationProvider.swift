//
//  AttestationProvider.swift
//  Pocket Cabbage
//
//  Abstracts how the app proves its identity to the backend before receiving a
//  JWT session token. In dev we send a stable device-scoped id as the App
//  Attest "key id" (the backend accepts this when APP_ATTEST_REQUIRED=false).
//  For production, AppAttestProvider wraps DCAppAttestService.
//
//  Swap implementations via APIConfig.appAttestEnabled.
//

import Foundation
#if canImport(DeviceCheck)
import DeviceCheck
#endif

protocol AttestationProvider {
    /// Returns the App Attest key id used as the `key_id` in the attest payload.
    func keyID() async throws -> String
    /// Returns a base64 assertion/attestation for the given challenge, or nil
    /// (dev mode sends no assertion; the backend derives a dev device id).
    func assertion(challenge: String) async throws -> String?
}

/// Dev attestation: a stable, per-install UUID stands in for the App Attest key
/// id. No cryptographic assertion is produced. Works on every platform and in
/// the simulator so the whole stack is testable without attestation hardware.
struct DevAttestationProvider: AttestationProvider {
    private static let key = "pocketcabbage.dev.attest.keyid"

    func keyID() async throws -> String {
        if let existing = UserDefaults.standard.string(forKey: Self.key) {
            return existing
        }
        let generated = "dev-" + UUID().uuidString
        UserDefaults.standard.set(generated, forKey: Self.key)
        return generated
    }

    func assertion(challenge: String) async throws -> String? { nil }
}

/// Production attestation via Apple App Attest.
///
/// TODO: Implement before enabling APIConfig.appAttestEnabled. The flow is:
///  1. Generate (or reuse) a key with DCAppAttestService.generateKey().
///  2. On first use, attestKey(_:clientDataHash:) with SHA256(challenge) and
///     send the base64 attestation object as `attestation`.
///  3. On subsequent calls, generateAssertion(_:clientDataHash:) and send the
///     base64 assertion as `assertion`.
/// The backend (verify_app_attest) must also be implemented to verify these.
struct AppAttestProvider: AttestationProvider {
    private static let key = "pocketcabbage.appattest.keyid"

    func keyID() async throws -> String {
        #if canImport(DeviceCheck)
        guard DCAppAttestService.shared.isSupported else {
            throw APIError.attestationUnsupported
        }
        if let existing = UserDefaults.standard.string(forKey: Self.key) {
            return existing
        }
        let generated = try await DCAppAttestService.shared.generateKey()
        UserDefaults.standard.set(generated, forKey: Self.key)
        return generated
        #else
        throw APIError.attestationUnsupported
        #endif
    }

    func assertion(challenge: String) async throws -> String? {
        // TODO: produce a real attestation (first use) / assertion (subsequent).
        throw APIError.attestationUnsupported
    }
}

/// Returns the attestation provider selected by APIConfig.
func makeAttestationProvider() -> AttestationProvider {
    APIConfig.appAttestEnabled ? AppAttestProvider() : DevAttestationProvider()
}
