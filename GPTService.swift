import Foundation

struct GPTService {
    static func getGPTResponse(prompt: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(Config.openAIGPTAPIKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "gpt-4",  // or you can use "gpt-3.5-turbo" if that’s what you have access to
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

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GPT API Error: No valid HTTP response")
                completion(nil)
                return
            }

            if httpResponse.statusCode != 200 {
                print("GPT API Error: HTTP status code \(httpResponse.statusCode)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("GPT API Error: No data returned")
                completion(nil)
                return
            }

            let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            print("GPT API Response: \(String(describing: responseData))")

            if let choices = responseData?["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                print("Failed to parse GPT response")
                print("Full response data: \(String(describing: responseData))")
                completion(nil)
            }

        }.resume()
    }
}

