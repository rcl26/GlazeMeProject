import Foundation

struct GPTService {
    static func getGPTResponse(subject: String, context: [String: Any], commentText: String?, completion: @escaping (String?) -> Void) {

        // Convert context (structured data) to JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: context, options: []),
              let _ = String(data: jsonData, encoding: .utf8) else {
            print("Failed to convert context to JSON string")
            completion(nil)
            return
        }

        // Construct the prompt using the subject and structured context
        let prompt: String

        if let userQuery = commentText, !userQuery.isEmpty {
            prompt = """
            You are a professional stylist and image consultant. A user has asked: "\(userQuery)". Provide a thoughtful and personalized response to their question, using the following details about the image as context.

            Details: \(context)

            - Ensure the answer is primarily focused on their query.
            - Use image details only to enhance or support your answer.
            - Avoid overemphasizing colors unless absolutely necessary for the query.
            - Mention specific details about the person, such as facial expressions, accessories, or standout traits, to enhance your response meaningfully.
            - Keep the tone conversational, sincere, and engaging. Write no more than 40 words.
            """
        } else {
            prompt = """
            You are a wild but lovable friend. Based on the following details, generate a thoughtful and personalized compliment about the person in the image. Focus primarily on their features, clothing, and overall style, ensuring the tone is engaging and relatable.

            Details: \(context)

            - Avoid overemphasizing colors unless absolutely necessary for the compliment.
            - Only mention colors if they contribute meaningfully.
            - Focus on their unique traits, like facial expressions, accessories, or specific standout features.
            - Keep the tone conversational, sincere, and charming. Write no more than 40 words.
            """
        }






        // Construct the request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")

        // Build the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a trendy friend specialized in providing compliments based on image analysis."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 60
        ]

        // Attach the request body
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("GPT API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Check response status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            // Ensure data is not nil
            guard let data = data else {
                print("GPT API Error: No data received")
                completion(nil)
                return
            }

            // Print raw response for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "No readable response"
            print("GPT API Raw Response: \(responseString)")

            // Parse the response JSON
            do {
                let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("Decoded JSON Response: \(responseData ?? [:])")
                if let choices = responseData?["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    print("Failed to parse GPT response")
                    completion(nil)
                }
            } catch {
                print("Error decoding GPT API response: \(error)")
                completion(nil)
            }
        }.resume()
    }

}

