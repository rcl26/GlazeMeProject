import Foundation

    // Broad categories for initial filtering
    let broadSubjectLabels = [
        // Human-related terms
        "person", "man", "woman", "child", "adult", "teenager", "baby",
        "face", "smile", "pose", "portrait", "selfie", "group",

        // Animal-related terms for pets and common animals
        "dog", "cat", "pet", "animal",

        // Common objects and elements that could appear in the background
        "tree", "car", "bicycle", "clothing", "building"
    ]

    // Broad categories for context filtering
    let broadContextLabels = [
        "outdoor", "nature", "city", "indoor", "scenic", "party", "event",
        "sports", "vacation", "celebration", "travel", "work", "meeting"
    ]

    // More specific details for deeper analysis of subjects
    let specificSubjectLabels = [
        // Expanded Animals and Breeds
        "black lab", "golden retriever", "labrador", "poodle", "beagle", "pug",
        "siamese cat", "tabby cat", "parrot", "fish", "hamster", "horse", "pony",
        "sheep", "cow", "rabbit", "hamster", "bird", "turtle", "snake",

        // Human Characteristics and Body Language
        "smile", "eyes", "nose", "mouth", "teeth", "glasses", "hair", "beard",
        "mustache", "expression", "gesture", "pose", "lean", "hug", "handshake",
        "laugh", "frown", "high five", "focus", "admiration", "surprise", "anger",
        "sadness", "joy", "confidence", "determination", "playfulness", "shyness",
        "affection", "eye contact", "interaction", "celebration", "group", "couple",

        // Clothing, Accessories, and Personal Items
        "t-shirt", "dress shirt", "blouse", "suit", "tie", "gown", "jacket", "coat",
        "scarf", "sweater", "jeans", "shorts", "skirt", "sneakers", "shoes", "boots",
        "sandals", "gloves", "sunglasses", "watch", "earrings", "necklace", "bracelet",
        "ring", "hat", "beanie", "cap", "backpack", "bag", "purse", "belt", "jewelry"
    ]

    // More specific context details
    let specificContextLabels = [
        "beach", "mountain", "river", "lake", "forest", "cityscape", "park", "road",
        "street", "building", "office", "living room", "kitchen", "restaurant",
        "cafe", "mall", "gym", "library", "classroom", "hotel", "resort", "airport",
        
        // Events and Activities
        "hiking", "running", "cycling", "swimming", "camping", "skiing", "surfing",
        "climbing", "fishing", "tennis", "golf", "basketball", "soccer", "football",
        "concert", "wedding", "festival", "celebration", "parade", "ceremony"
    ]



struct VisionService {
    
    static func analyzeImage(with imageData: Data, apiKey: String, completion: @escaping (_ result: String?) -> Void) {
        let request = createURLRequest(with: imageData, apiKey: apiKey)
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Vision API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Vision API Error: No data returned")
                completion(nil)
                return
            }
            
            if let description = parseResponse(data: data) {
                // Separate `subject` and `context` from the parsed description
                let subjectDescription = "person" // Placeholder; dynamically set based on analysis
                let contextDescription = description

                // Pass structured data to GPTService, without creating the prompt here
                GPTService.getGPTResponse(subject: subjectDescription, context: contextDescription) { response in
                    completion(response)
                }
            } else {
                completion("Failed to analyze the image.")
            }

        }
        
        dataTask.resume()
    }
    
    private static func createURLRequest(with imageData: Data, apiKey: String) -> URLRequest {
        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = imageData.base64EncodedString()
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "LABEL_DETECTION", "maxResults": 20],  // Capture more potential scene labels
                        ["type": "FACE_DETECTION"],
                        ["type": "IMAGE_PROPERTIES"],
                        ["type": "OBJECT_LOCALIZATION", "maxResults": 10],
                        ["type": "TEXT_DETECTION"],
                        ["type": "LANDMARK_DETECTION"],
                        ["type": "WEB_DETECTION"]
                    ]


                ]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        return request
    }
    
    private static func parseResponse(data: Data) -> String? {
        guard let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let responses = responseData["responses"] as? [[String: Any]] else {
            print("Failed to parse response data.")
            return nil
        }

        // Use helper functions to parse individual parts
        let labelsDescription = parseLabels(from: responses)
        let webContext = parseWebDetection(from: responses) // New addition for web detection context
        let faceDescription = parseFaces(from: responses)
        let colorDescription = parseColors(from: responses)
        let objectDescription = parseObjects(from: responses)
        let textDescription = parseText(from: responses)

        return [labelsDescription, webContext, faceDescription, colorDescription, objectDescription, textDescription]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }
    
    private static func parseLabels(from responses: [[String: Any]]) -> String {
        guard let labelAnnotations = responses.first?["labelAnnotations"] as? [[String: Any]] else { return "" }
        
        // Step 1: Extract labels from the response
        let labels = labelAnnotations.compactMap { $0["description"] as? String }
        
        // Step 2: Look for broad categories first
        let broadMatches = labels.filter { broadSubjectLabels.contains($0.lowercased()) }
        
        // Step 3: If a broad match is found, dive into specific matches
        var specificMatches: [String] = []
        if !broadMatches.isEmpty {
            specificMatches = labels.filter { specificSubjectLabels.contains($0.lowercased()) }
        }
        
        // Combine both broad and specific context labels for filtering
        let combinedContextLabels = broadContextLabels + specificContextLabels

        // Use combinedContextLabels in the filter
        let contextMatches = labels.filter { combinedContextLabels.contains($0.lowercased()) }

        
        // Step 5: Construct the final description, prioritizing specific matches if available
        let subjectDetails = !specificMatches.isEmpty ? specificMatches : broadMatches
        let allDetails = (subjectDetails + contextMatches).joined(separator: ", ")
        
        return allDetails.isEmpty ? "" : "Identified labels: " + allDetails
    }



    private static func parseWebDetection(from responses: [[String: Any]]) -> String {
        guard let webDetection = responses.first?["webDetection"] as? [String: Any],
              let bestGuessLabels = webDetection["bestGuessLabels"] as? [[String: Any]],
              let webEntities = webDetection["webEntities"] as? [[String: Any]] else { return "" }
        
        // Capture best guess labels for context
        let bestGuesses = bestGuessLabels.compactMap { $0["label"] as? String }
        
        // Capture descriptive labels from web entities, filtering for relevance
        let entityDescriptions = webEntities
            .compactMap { $0["description"] as? String }
            .filter { $0.count > 3 } // Filters out any very short or irrelevant labels
        
        // Combine best guesses and web entity descriptions for comprehensive context
        let combinedContext = (bestGuesses + entityDescriptions).joined(separator: ", ")
        
        return combinedContext.isEmpty ? "" : "Possible scene context: " + combinedContext
    }

    
    private static func parseFaces(from responses: [[String: Any]]) -> String {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]],
              let faceAttributes = faceAnnotations.first else { return "" }
        
        let joyLikelihood = faceAttributes["joyLikelihood"] as? String ?? "UNKNOWN"
        let angerLikelihood = faceAttributes["angerLikelihood"] as? String ?? "UNKNOWN"
        let sorrowLikelihood = faceAttributes["sorrowLikelihood"] as? String ?? "UNKNOWN"
        let surpriseLikelihood = faceAttributes["surpriseLikelihood"] as? String ?? "UNKNOWN"
        
        // Only include expressions that are "VERY_LIKELY" or "LIKELY"
        var faceDescription = ""
        if joyLikelihood == "VERY_LIKELY" || joyLikelihood == "LIKELY" {
            faceDescription += "The person appears to possibly express joy. "
        }
        if angerLikelihood == "VERY_LIKELY" || angerLikelihood == "LIKELY" {
            faceDescription += "There is a possible expression of anger. "
        }
        if sorrowLikelihood == "VERY_LIKELY" || sorrowLikelihood == "LIKELY" {
            faceDescription += "The person might be expressing sorrow. "
        }
        if surpriseLikelihood == "VERY_LIKELY" || surpriseLikelihood == "LIKELY" {
            faceDescription += "The person may appear surprised. "
        }
        
        // Return the filtered face description or a default message if empty
        return faceDescription.isEmpty ? "No strong facial expressions detected." : faceDescription
    }

    
    private static func parseColors(from responses: [[String: Any]]) -> String {
        guard let imagePropertiesAnnotation = responses.first?["imagePropertiesAnnotation"] as? [String: Any],
              let dominantColors = imagePropertiesAnnotation["dominantColors"] as? [String: Any],
              let colors = dominantColors["colors"] as? [[String: Any]],
              let mainColor = colors.first?["color"] as? [String: Any] else { return "" }
        
        let red = mainColor["red"] as? Int ?? 0
        let green = mainColor["green"] as? Int ?? 0
        let blue = mainColor["blue"] as? Int ?? 0
        return "Dominant color RGB: (\(red), \(green), \(blue))"
    }
    
    private static func parseObjects(from responses: [[String: Any]]) -> String {
        guard let localizedObjectAnnotations = responses.first?["localizedObjectAnnotations"] as? [[String: Any]] else { return "" }
        let objects = localizedObjectAnnotations.compactMap { $0["name"] as? String }
        return "Located objects: " + objects.joined(separator: ", ")
    }
    
    private static func parseText(from responses: [[String: Any]]) -> String {
        guard let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]],
              let detectedText = textAnnotations.first?["description"] as? String else { return "" }
        return "Detected text: \(detectedText)"
    }
}

