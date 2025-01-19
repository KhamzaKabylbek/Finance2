import Foundation

class GeminiService {
    private let apiKey = "AIzaSyACoYC9FFJMPirwxQV85iKzAyJozjOWXyM"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    func generateResponse(for message: String) async throws -> String {
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": message]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        return response.candidates?.first?.content?.parts?.first?.text ?? "Извините, не удалось получить ответ"
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]?
}

struct Candidate: Codable {
    let content: Content?
}

struct Content: Codable {
    let parts: [Part]?
}

struct Part: Codable {
    let text: String
}
