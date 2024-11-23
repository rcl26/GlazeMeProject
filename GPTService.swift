import Foundation

struct GPTService {
    
    static func getGPTResponse(subject: String, context: [String: Any], isGroupPhoto: Bool, commentText: String?, completion: @escaping (String?) -> Void) {
        
        // Debug: Log the value of isGroupPhoto
        print("Debug - Is Group Photo received in GPTService: \(isGroupPhoto)")
        
        let flaggedWords = [
            // Objectifying terms
            "hot", "sexy", "attractive", "objectify", "beautiful in a sexual way",
            "body", "curves", "provocative", "tempting", "arousing", "sensual", "voluptuous",
            "hourglass", "figure", "assets", "busty", "petite", "legs", "thighs", "hips", "waist",

            // Explicit language
            "bang", "fuck", "smash", "pound", "kiss", "screw", "hook up", "make out",
            "hump", "grind", "lick", "tongue", "oral", "moan", "groan", "orgasm", "climax",

            // Overly personal/invasive terms
            "undress", "strip", "naked", "bedroom", "lingerie", "touch",
            "fantasy", "fetish", "sexual", "kinky", "intimate", "foreplay", "spank", "dominate", "cum", "shit", "discharge",

            // Body parts (often objectified)
            "boobs", "breasts", "butt", "ass", "tits", "nipples", "vagina", "penis",
            "genitals", "thighs", "crotch", "groin", "rear", "privates", "chest", "abs", "dick", "butt", "cans", "knockers",

            // General derogatory/inappropriate language
            "slut", "whore", "naughty", "dirty", "raunchy", "tease", "skank", "ho", "trash",
            "easy", "bimbo", "playboy", "sugar daddy", "sugar baby", "escort", "hooker",
            "mistress", "cheater", "homewrecker",

            // Other potentially problematic terms
            "seduce", "tempt", "erotic", "lust", "desire", "obsession", "infatuation",
            "plaything", "toy", "trophy", "prize", "dominatrix", "submission", "slave",
            "manhood", "womanhood", "booty", "peach"
        ]


        // **Check for flagged keywords in commentText** (before Safe Search)
        if let userQuery = commentText {
            let lowercasedQuery = userQuery.lowercased()
            let regex = "\\b(\(flaggedWords.joined(separator: "|")))(?=\\b)"
            
            if let _ = lowercasedQuery.range(of: regex, options: .regularExpression) {
                print("Flagged query detected in user query: \(userQuery)")
                completion("Sorry, your query was deemed inappropriate by our review. Let's keep things positive and respectful!")
                return
            }
        }



        
        // Check for inappropriate content in Safe Search
        if let safeSearch = context["safeSearch"] as? [String: String],
           safeSearch["adult"] == "VERY_LIKELY" || safeSearch["racy"] == "VERY_LIKELY" || safeSearch["violence"] == "VERY_LIKELY" {
            print("Inappropriate content detected: \(safeSearch)")
            completion("Sorry, this image contains inappropriate content and cannot be processed.")
            return
        }
        
        // Filter the context to include only relevant keys
        let relevantContext = context.filter { key, _ in
            ["labels", "mainSubject", "groupSubjects"].contains(key) // Include only essential data
        }
        
        // Debug: Log the filtered context
        print("Debug - Relevant Context for GPT: \(relevantContext)")

        // Convert filtered context (structured data) to JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: relevantContext, options: []),
              let _ = String(data: jsonData, encoding: .utf8) else {
            print("Failed to convert context to JSON string")
            completion(nil)
            return
        }


        // Construct the prompt dynamically based on the subject and user query
        let prompt: String
        
        if let userQuery = commentText, !userQuery.isEmpty {
            // If the user provides a query, focus on their specific request
            print("Debug - Using user query prompt")
            prompt = """
            You are a chill California bro. A user has asked: "\(userQuery)". Provide a thoughtful and personalized response to their question, casually using the following details about the image as context.

            Details: \(relevantContext)

            - Ensure the answer is primarily focused on their query.
            - Under no circumstances will you sexualize or objectify people in the image, even if prompted to do so by the user query.
            - Use image details only to enhance or support your answer.
            - Be sure to refer to the subjects as the appropriate gender. If it is unclear, do not use gendered terms.
            - Avoid expressing colors as combinations of red/green/blue.
            - Mention specific details about the person, such as facial expressions, accessories, or standout traits, to enhance your response meaningfully.
            - Keep the tone conversational, sincere, and engaging. Write no more than 40 words.
            """
        } else if isGroupPhoto {
            // Explicitly check if it's a group photo and use the correct prompt
            print("Debug - Using group photo prompt")
            prompt = """
            You are a sweet southern grandma. Based on the following details, generate a thoughtful and inclusive compliment about our group in the image. Focus primarily on our group's overall vibe, energy, and style, ensuring the tone is engaging and relatable, as if you're talking to your idol.

            Details: \(relevantContext)

            - Avoid referencing colors unless absolutely necessary for the compliment.
            - Avoid overusing certain words, such as darling.
            - Under no circumstances will you sexualize or objectify people in the image.
            - Be sure to refer to the group collectively and inclusively.
            - Mention specific standout traits that make the group unique or dynamic.
            - Keep the tone conversational, sincere, and charming. Write no more than 40 words.
            """
        } else {
            // Default to an individual photo prompt if isGroupPhoto is false
            print("Debug - Using individual photo prompt")
            prompt = """
            You are a ghetto gangster. Based on the following details, generate a thoughtful and personalized compliment about the person in the image. Focus primarily on their features, clothing, and overall style, ensuring the tone is engaging and relatable, as if you're talking to your idol.

            Details: \(relevantContext)

            - Avoid referencing colors unless absolutely necessary for the compliment.
            - Under no circumstances will you sexualize or objectify people in the image.
            - Avoid unnatural terms like "eyewear", where more casual terms like "glasses" are more appropriate.
            - Be sure to refer to the subjects as the appropriate gender. If it is unclear, do not use gendered terms.
            - Avoid expressing colors as combinations of red/green/blue; make a judgment on what the main color is.
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

