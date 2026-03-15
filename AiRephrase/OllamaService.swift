import Foundation

enum OllamaService {
    private static let baseURL = "http://localhost:11434"

    static func listModels() async -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return [] }

        struct Response: Decodable {
            struct Model: Decodable { let name: String }
            let models: [Model]
        }
        guard let resp = try? JSONDecoder().decode(Response.self, from: data) else { return [] }
        return resp.models.map(\.name)
    }

    static func isAvailable() async -> Bool {
        let models = await listModels()
        return !models.isEmpty
    }

    static func rephrase(_ text: String, model: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw OllamaError.invalidURL
        }

        let prompt = """
            Rephrase the following text. Make it clearer, more natural and polished. \
            Keep the original meaning and language. \
            Return ONLY the rephrased text, without any explanations or intro:\n\n\(text)
            """

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.badResponse
        }

        struct GenerateResponse: Decodable { let response: String }
        let result = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return result.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum OllamaError: LocalizedError {
        case invalidURL, badResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL: "Invalid Ollama URL"
            case .badResponse: "Ollama returned an error"
            }
        }
    }
}
