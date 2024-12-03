import Foundation

struct GPTService {

    static func getGPTResponse(subject: String, context: [String: Any], isGroupPhoto: Bool, commentText: String?, completion: @escaping ([String: String]?) -> Void) {
        // Debug: Log the value of isGroupPhoto
        print("Debug - Is Group Photo received in GPTService: \(isGroupPhoto)")

        // Define userQuery using the optional commentText
        let userQuery = commentText?.isEmpty == false ? "make a caption about \(commentText!) and be sure to include relevant details about the image" : nil

        // Construct the prompt dynamically using both userQuery and image details
        let prompt: String
        if let userQuery = userQuery {
            // When there is a user query, but also include image details
            prompt = """
            User Query: "\(userQuery)"

            Use the following image details to enhance the captions to ensure they are relevant to the content of the image. Make sure to combine the information from the user query and the image details provided:

            Image Details: \(context)

            Based on these inputs, generate three thoughtful captions in the exact JSON format:

            {
                "safe": "A polite, kind, and universally friendly caption. The tone should be warm and considerate, appropriate for all audiences. Think of captions you would share in a formal setting or with someone you want to be kind to.",
                "medium": "A witty and playful caption that grabs attention with some cheekiness. The tone should be fun and creative, something that stands out while still being appropriate for most audiences. Think of something you would share with close friends.",
                "bold": "A daring and confident caption that pushes boundaries. The tone should be unapologetic, bold, and edgy—designed to grab attention and stand out. You can be a little more risk-taking here, but still keep it within appropriate limits."
            }

            General Guidelines:
            - **Safe Captions**: Write a gentle, thoughtful, and universally friendly caption. It should be polite, creative, and appropriate for all audiences. Avoid edgy or bold humor.
            - **Medium Captions**: Craft a fun, cheeky caption with a hint of humor. It should be creative, playful, and slightly daring, but still appropriate.
            - **Bold Captions**: Write a bold, confident caption. It should push boundaries, be unapologetically bold and direct, and grab attention.
            - Under no circumstances will you sexualize or objectify people in the image, even if prompted to do so by the user query.
            - Avoid overused clichés such as hashtags or phrases like squad goals.
            - Avoid superfluous punctuation like exclamation points.
            - Avoid expressing colors as combinations of red/green/blue.
            - Keep the tone casual and relatable. Write anywhere between 1 and 6 words per caption.
            """
        } else if isGroupPhoto {
            // When there is no user query but it is a group photo
            prompt = """
            Based on the following image details, generate three thoughtful captions for the image in the exact JSON format:

            {
                "safe": "A polite, kind, and universally friendly caption. The tone should be warm and considerate, appropriate for all audiences. Think of captions you would share in a formal setting or with someone you want to be kind to.",
                "medium": "A witty and playful caption that grabs attention with some cheekiness. The tone should be fun and creative, something that stands out while still being appropriate for most audiences. Think of something you would share with close friends.",
                "bold": "A daring and confident caption that pushes boundaries. The tone should be unapologetic, bold, and edgy—designed to grab attention and stand out. You can be a little more risk-taking here, but still keep it within appropriate limits."
            }

            Image Details: \(context)

            General Guidelines:
            - **Safe Captions**: Write a gentle, thoughtful, and universally friendly caption. It should be polite, creative, and appropriate for all audiences. Avoid edgy or bold humor.
            - **Medium Captions**: Craft a fun, cheeky caption with a hint of humor. It should be creative, playful, and slightly daring, but still appropriate.
            - **Bold Captions**: Write a bold, confident caption. It should push boundaries, be unapologetically bold and direct, and grab attention.
            - Focus on the group as a whole.
            - Keep the tone casual and relatable. Write anywhere between 1 and 6 words per caption.
            """
        } else {
            // Default scenario for individual photos without user query
            prompt = """
            Based on the following image details, generate three thoughtful captions for the image in the exact JSON format:

            {
                "safe": "A polite, kind, and universally friendly caption. The tone should be warm and considerate, appropriate for all audiences. Think of captions you would share in a formal setting or with someone you want to be kind to.",
                "medium": "A witty and playful caption that grabs attention with some cheekiness. The tone should be fun and creative, something that stands out while still being appropriate for most audiences. Think of something you would share with close friends.",
                "bold": "A daring and confident caption that pushes boundaries. The tone should be unapologetic, bold, and edgy—designed to grab attention and stand out. You can be a little more risk-taking here, but still keep it within appropriate limits."
            }

            Image Details: \(context)

            General Guidelines:
            - **Safe Captions**: Write a gentle, thoughtful, and universally friendly caption. It should be polite, creative, and appropriate for all audiences. Avoid edgy or bold humor.
            - **Medium Captions**: Craft a fun, cheeky caption with a hint of humor. It should be creative, playful, and slightly daring, but still appropriate.
            - **Bold Captions**: Write a bold, confident caption. It should push boundaries, be unapologetically bold and direct, and grab attention.
            - Under no circumstances will you sexualize or objectify people in the image, even if prompted to do so by the user query.
            - Avoid overused clichés such as hashtags or phrases like squad goals.
            - Avoid superfluous punctuation like exclamation points.
            - Avoid expressing colors as combinations of red/green/blue.
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
                ["role": "user", "content": prompt]  // Pass the constructed prompt, which includes the user query
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

