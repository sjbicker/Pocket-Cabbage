//
//  APIClient.swift
//  Pocket Cabbage
//
//  The one door to the backend. Every authenticated request adds the bearer
//  token from AuthManager, and transparently re-attests + retries once on 401
//  (tokens are short-lived). All third-party services are brokered server-side.
//

import Foundation

/// Body for POST /v1/shopping-list — the backend reads `plan` and `pantry`.
private struct ShoppingListRequest: Encodable {
    var plan: [String: [RecipeDTO]]
    var pantry: [PantryItemDTO]
}

actor APIClient {
    private let session: URLSession
    private let auth: AuthManager

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        self.session = session
        self.auth = AuthManager(session: session)
    }

    // MARK: - Public endpoints

    func generateMealPlan(_ request: MealPlanRequest) async throws -> MealPlanResponse {
        try await send(path: "/v1/mealplan/generate", method: "POST", body: request)
    }

    func swapMeal(_ request: SwapRequest) async throws -> MealPlanResponse {
        try await send(path: "/v1/mealplan/swap", method: "POST", body: request)
    }

    func shoppingList(plan: MealPlanResponse, pantry: [PantryItemDTO]) async throws -> ShoppingListResponse {
        let body = ShoppingListRequest(plan: plan.plan, pantry: pantry)
        return try await send(path: "/v1/shopping-list", method: "POST", body: body)
    }

    func scanPantry(imageBase64: String, mediaType: String = "image/jpeg") async throws -> PantryScanResult {
        try await send(path: "/v1/scan/pantry", method: "POST",
                       body: ScanRequest(imageBase64: imageBase64, mediaType: mediaType))
    }

    func scanFlyer(imageBase64: String, mediaType: String = "image/jpeg") async throws -> FlyerScanResult {
        try await send(path: "/v1/scan/flyer", method: "POST",
                       body: ScanRequest(imageBase64: imageBase64, mediaType: mediaType))
    }

    func scanReceipt(imageBase64: String, mediaType: String = "image/jpeg") async throws -> ReceiptScanResult {
        try await send(path: "/v1/scan/receipt", method: "POST",
                       body: ScanRequest(imageBase64: imageBase64, mediaType: mediaType))
    }

    func resolvePrice(ingredient: String, zip: String) async throws -> PricingResponse {
        // This endpoint takes query params, not a JSON body.
        let query = [URLQueryItem(name: "ingredient", value: ingredient),
                     URLQueryItem(name: "zip_code", value: zip)]
        return try await send(path: "/v1/pricing/resolve", method: "POST", query: query,
                              body: Optional<String>.none)
    }

    /// Unauthenticated health probe for the Profile diagnostics screen.
    func health() async throws -> HealthResponse {
        let url = APIConfig.baseURL.appending(path: "/health")
        var request = URLRequest(url: url)
        request.timeoutInterval = APIConfig.requestTimeout
        let (data, response) = try await perform(request)
        try Self.validate(response, data)
        return try Self.decoder.decode(HealthResponse.self, from: data)
    }

    // MARK: - Core request pipeline

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        query: [URLQueryItem] = [],
        body: Body?
    ) async throws -> Response {
        let data = try await sendRaw(path: path, method: method, query: query, body: body)
        do { return try Self.decoder.decode(Response.self, from: data) }
        catch { throw APIError.decoding(error) }
    }

    private func sendRaw<Body: Encodable>(
        path: String,
        method: String,
        query: [URLQueryItem],
        body: Body?,
        isRetry: Bool = false
    ) async throws -> Data {
        var components = URLComponents(url: APIConfig.baseURL.appending(path: path),
                                       resolvingAgainstBaseURL: false)
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw APIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = APIConfig.requestTimeout
        let token = try await auth.validToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try Self.encoder.encode(body)
        }

        let (data, response) = try await perform(request)
        if let http = response as? HTTPURLResponse, http.statusCode == 401, !isRetry {
            // Token likely expired — force a fresh handshake and retry once.
            _ = try await auth.validToken(forceRefresh: true)
            return try await sendRaw(path: path, method: method, query: query,
                                     body: body, isRetry: true)
        }
        try Self.validate(response, data)
        return data
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
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

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.keyEncodingStrategy = .convertToSnakeCase; return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d
    }()
}
