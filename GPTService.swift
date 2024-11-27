import Foundation

struct GPTService {
    
    static func moderateUserInput(userInput: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/moderations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = ["input": userInput]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, "Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let flagged = results.first?["flagged"] as? Bool {
                completion(flagged, nil) // Returns true if flagged, false otherwise
            } else {
                completion(false, "Failed to parse Moderation API response")
            }
        }.resume()
    }
    
    static func getGPTResponse(subject: String, context: [String: Any], isGroupPhoto: Bool, commentText: String?, completion: @escaping ([String: String]?) -> Void) {
        // Debug: Log the value of isGroupPhoto
        print("Debug - Is Group Photo received in GPTService: \(isGroupPhoto)")
        
        // Construct the prompt dynamically based on the subject and user query
        let prompt: String

        if let userQuery = commentText, !userQuery.isEmpty {
            // User Query Scenario
            prompt = """
            You are the coolest, most interesting person on earth. A user has asked: "\(userQuery)". Based on the following details, respond with exactly the following JSON format:
            {
                "safe": "A polite and creative caption that's universally friendly. Slightly expressive, with personality but avoids humor or edgy elements.",
                "medium": "A witty, attention-grabbing caption with humor and daring language. Designed to stand out while remaining appropriate.",
                "bold": "An unapologetically daring, edgy, or humorous—crafted caption to grab attention."
            }

            Details: \(context)

            General Guidelines:
            - Ensure the answer is primarily focused on their query.
            - Avoid any preambles, introductions, or extra text. Respond with ONLY valid JSON in the format above.
            - **Safe Captions**: These should be polite, creative, and universally friendly. Slightly expressive, but avoid edgy humor or bold statements. Think of captions that fit for formal settings or broad audiences.
            - **Medium Captions**: Add wit and humor here. These should grab attention with a playful, creative tone but avoid crossing into controversy. Think fun captions you’d share with close friends.
            - **Bold Captions**: Push boundaries with humor, daring phrasing, or edginess. These captions are unapologetic, loud, and crafted to stand out. Designed for a bold or risk-taking audience.
            - Under no circumstances will you sexualize or objectify people in the image, even if prompted to do so by the user query.
            - Avoid overused clichés such as hashtags or phrases like squad goals.
            - Avoid superfluous punctuation like exclamation points.
            - Avoid expressing colors as combinations of red/green/blue.
            - Keep the tone casual and relatable. Write anywhere between 1 and 6 words per caption.
            """
        } else if isGroupPhoto {
            // Group Photo Scenario
            prompt = """
            You are the coolest, most interesting person on earth. Based on the following details, generate three thoughtful captions for the image:
            {
                "safe": "A polite and creative caption that's universally friendly. Slightly expressive, with personality but avoids humor or edgy elements.",
                "medium": "A witty, attention-grabbing caption with humor and daring language. Designed to stand out while remaining appropriate.",
                "bold": "An unapologetically daring, edgy, or humorous—crafted caption to grab attention."
            }

            Details: \(context)

            General Guidelines:
            - Avoid referencing colors unless absolutely necessary for the caption.
            - Respond with ONLY the captions in JSON format (as shown above).
            - **Safe Captions**: These should be polite, creative, and universally friendly. Slightly expressive, but avoid edgy humor or bold statements. Think of captions that fit for formal settings or broad audiences.
            - **Medium Captions**: Add wit and humor here. These should grab attention with a playful, creative tone but avoid crossing into controversy. Think fun captions you’d share with close friends.
            - **Bold Captions**: Push boundaries with humor, daring phrasing, or edginess. These captions are unapologetic, loud, and crafted to stand out. Designed for a bold or risk-taking audience.
            - Avoid superfluous punctuation like exclamation points.
            - Avoid overused clichés such as hashtags or phrases like squad goals.
            - Focus on the group as a whole.
            - Keep the tone casual and relatable. Write anywhere between 1 and 6 words per caption.
            """
        } else {
            // Default Individual Scenario
            prompt = """
            You are the coolest, most interesting person on earth. Based on the following details, generate three thoughtful captions for the image:
            {
                "safe": "A polite and creative caption that's universally friendly. Slightly expressive, with personality but avoids humor or edgy elements.",
                "medium": "A witty, attention-grabbing caption with humor and daring language. Designed to stand out while remaining appropriate.",
                "bold": "An unapologetically daring, edgy, or humorous—crafted caption to grab attention."
            }

            Details: \(context)

            General Guidelines:
            - Avoid referencing colors unless absolutely necessary for the caption.
            - Respond with ONLY the captions in JSON format (as shown above).
            - **Safe Captions**: These should be polite, creative, and universally friendly. Slightly expressive, but avoid edgy humor or bold statements. Think of captions that fit for formal settings or broad audiences.
            - **Medium Captions**: Add wit and humor here. These should grab attention with a playful, creative tone but avoid crossing into controversy. Think fun captions you’d share with close friends.
            - **Bold Captions**: Push boundaries with humor, daring phrasing, or edginess. These captions are unapologetic, loud, and crafted to stand out. Designed for a bold or risk-taking audience.
            - Avoid superfluous punctuation like exclamation points.
            - Avoid overused clichés such as hashtags or phrases like squad goals.
            - Keep the tone casual and relatable. Write anywhere between 1 and 6 words per caption.
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
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a trendy friend specialized in creating unique captions for social media based on image analysis."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 100
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("GPT API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("GPT API Error: No data received")
                completion(nil)
                return
            }

            // Parse the response
            do {
                let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("Decoded JSON Response: \(responseData ?? [:])")
                if let choices = responseData?["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // Remove backticks and "json" label if present
                    let cleanedContent = content
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if let jsonData = cleanedContent.data(using: .utf8),
                       let captions = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                        completion(captions) // Pass the dictionary
                    } else {
                        print("Failed to parse JSON content into captions.")
                        completion(nil)
                    }

                } else {
                    print("Failed to parse GPT response.")
                    completion(nil)
                }
            } catch {
                print("Error decoding GPT API response: \(error)")
                completion(nil)
            }

        }.resume()
    }
}

