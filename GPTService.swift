import Foundation

struct GPTService {
    static func getGPTResponse(subject: String, context: [String: Any], completion: @escaping (String?) -> Void) {
        // Convert context (structured data) to JSON string
        let jsonData = try? JSONSerialization.data(withJSONObject: context, options: [])
        let jsonString = String(data: jsonData ?? Data(), encoding: .utf8) ?? ""

        // Construct the prompt using the subject and the structured context
        let prompt = """
        The image depicts a \(subject) with the following details: \(jsonString). Provide two sentences of an energetic and relatable compliment for the subject based on these details. Your tone should sound like you are talking to an idol who you admire greatly. 
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 60
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("GPT API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("GPT API Error: No valid HTTP response or data.")
                completion(nil)
                return
            }

            let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let choices = responseData?["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                print("Failed to parse GPT response")
                completion(nil)
            }
        }.resume()
    }
}

