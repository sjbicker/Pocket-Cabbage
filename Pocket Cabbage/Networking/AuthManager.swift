//
//  AuthManager.swift
//  Pocket Cabbage
//
//  Owns the backend session lifecycle: runs the App Attest → JWT handshake
//  (GET /v1/auth/challenge → POST /v1/auth/attest), caches the short-lived
//  token, and single-flights concurrent refreshes.
//

import Foundation

enum APIError: LocalizedError {
    case badURL
    case http(status: Int, body: String)
    case decoding(Error)
    case transport(Error)
    case attestationUnsupported
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .badURL: "Bad request URL."
        case .http(let status, let body): "Server error \(status): \(body)"
        case .decoding(let error): "Couldn't read the server response. \(error.localizedDescription)"
        case .transport(let error): "Network error. \(error.localizedDescription)"
        case .attestationUnsupported: "App Attest isn't available on this device."
        case .notAuthenticated: "Not signed in."
        }
    }
}

/// Serializes token acquisition so many concurrent requests share one handshake.
actor AuthManager {
    private let session: URLSession
    private let attestation: AttestationProvider

    private var token: String?
    private var expiry: Date = .distantPast
    private var inFlight: Task<String, Error>?

    init(session: URLSession, attestation: AttestationProvider = makeAttestationProvider()) {
        self.session = session
        self.attestation = attestation
    }

    /// Returns a valid bearer token, refreshing if missing/expired or forced.
    func validToken(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let token, expiry > Date.now.addingTimeInterval(60) {
            return token
        }
        if let inFlight { return try await inFlight.value }

        let task = Task<String, Error> { try await handshake() }
        inFlight = task
        defer { inFlight = nil }
        let fresh = try await task.value
        return fresh
    }

    private func handshake() async throws -> String {
        let challenge = try await fetchChallenge()
        let keyID = try await attestation.keyID()
        let assertion = try await attestation.assertion(challenge: challenge)

        let payload = AttestPayload(keyId: keyID, attestation: nil,
                                    assertion: assertion, challenge: challenge,
                                    clientDataHash: nil)
        let tokenResponse = try await postAttest(payload)
        self.token = tokenResponse.accessToken
        self.expiry = Date.now.addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        return tokenResponse.accessToken
    }

    private func fetchChallenge() async throws -> String {
        let url = APIConfig.baseURL.appending(path: "/v1/auth/challenge")
        var request = URLRequest(url: url)
        request.timeoutInterval = APIConfig.requestTimeout
        let (data, response) = try await transport(request)
        try Self.validate(response, data)
        return try Self.decoder.decode(ChallengeResponse.self, from: data).challenge
    }

    private func postAttest(_ payload: AttestPayload) async throws -> TokenResponse {
        let url = APIConfig.baseURL.appending(path: "/v1/auth/attest")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.requestTimeout
        request.httpBody = try Self.encoder.encode(payload)
        let (data, response) = try await transport(request)
        try Self.validate(response, data)
        return try Self.decoder.decode(TokenResponse.self, from: data)
    }

    private func transport(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do { return try await session.data(for: request) }
        catch { throw APIError.transport(error) }
    }

    private static func validate(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(status: http.statusCode,
                                body: String(data: data, encoding: .utf8) ?? "")
        }
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.keyEncodingStrategy = .convertToSnakeCase; return e
    }()
    static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d
    }()
}
