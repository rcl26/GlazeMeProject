import Foundation

struct VisionService {
    static func analyzeImage(with imageData: Data, apiKey: String, completion: @escaping (_ structuredData: [String: Any]?) -> Void) {
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
            
            if let structuredData = parseResponse(data: data) {
                // Pass structured data to the completion handler
                completion(structuredData)
            } else {
                print("Failed to parse response data.")
                completion(nil)
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
                        ["type": "FACE_DETECTION"],       // Facial expressions, tilt, landmarks
                        ["type": "LANDMARK_DETECTION"],   // Facial and body landmarks
                        ["type": "OBJECT_LOCALIZATION"],  // Detection of people, objects
                        ["type": "LABEL_DETECTION"],      // General labels
                        ["type": "TEXT_DETECTION"],       // Extract text if any
                        ["type": "SAFE_SEARCH_DETECTION"],// Filter out unsafe content
                        ["type": "IMAGE_PROPERTIES"]      // Dominant color analysis
                    ]
                ]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        return request
    }


    private static func parseResponse(data: Data) -> [String: Any]? {
        guard let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let responses = responseData["responses"] as? [[String: Any]] else {
            print("Failed to parse response data.")
            return nil
        }

        // **Log the full raw response** to check what is being returned
        print("Full Vision API Response: \(responses)") // Add this line to log the full response

        // Extract individual components from the response
        let labels = parseLabels(from: responses)
        let webEntities = parseWebDetection(from: responses)
        let facialExpressions = parseFaces(from: responses)
        let dominantColors = parseColors(from: responses)
        let objects = parseObjects(from: responses)
        let detectedText = parseText(from: responses)

        // Construct the structured data for GPT input
        return [
            "labels": labels,
            "webEntities": webEntities,
            "facialExpressions": facialExpressions,
            "dominantColors": dominantColors,
            "objects": objects,
            "text": detectedText
        ]
    }


    // Parse face expressions like joy, anger, etc.
    private static func parseFaces(from responses: [[String: Any]]) -> [String: Any] {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]],
              let faceAttributes = faceAnnotations.first else {
            print("No face annotations found")
            return [:]
        }

        var facialData: [String: Any] = [:]

        if let joy = faceAttributes["joyLikelihood"] as? String {
            facialData["joy"] = joy
        }
        if let anger = faceAttributes["angerLikelihood"] as? String {
            facialData["anger"] = anger
        }
        if let surprise = faceAttributes["surpriseLikelihood"] as? String {
            facialData["surprise"] = surprise
        }
        if let sadness = faceAttributes["sorrowLikelihood"] as? String {
            facialData["sadness"] = sadness
        }
        
        // Facial landmark details
        if let landmarks = faceAttributes["landmarks"] as? [[String: Any]] {
            for landmark in landmarks {
                if let type = landmark["type"] as? String, let position = landmark["position"] as? [String: Any] {
                    facialData["landmark_\(type)"] = position
                }
            }
        }

        return facialData
    }

    private static func parseLabels(from responses: [[String: Any]]) -> [String] {
        guard let labelAnnotations = responses.first?["labelAnnotations"] as? [[String: Any]] else { return [] }
        return labelAnnotations.compactMap { $0["description"] as? String }
    }

    private static func parseObjects(from responses: [[String: Any]]) -> [String] {
        guard let localizedObjectAnnotations = responses.first?["localizedObjectAnnotations"] as? [[String: Any]] else { return [] }
        return localizedObjectAnnotations.compactMap { $0["name"] as? String }
    }

    private static func parseColors(from responses: [[String: Any]]) -> [String: Int] {
        guard let imagePropertiesAnnotation = responses.first?["imagePropertiesAnnotation"] as? [String: Any],
              let dominantColors = imagePropertiesAnnotation["dominantColors"] as? [String: Any],
              let colors = dominantColors["colors"] as? [[String: Any]],
              let mainColor = colors.first?["color"] as? [String: Any] else { return [:] }

        let red = mainColor["red"] as? Int ?? 0
        let green = mainColor["green"] as? Int ?? 0
        let blue = mainColor["blue"] as? Int ?? 0
        return ["red": red, "green": green, "blue": blue]
    }

    private static func parseText(from responses: [[String: Any]]) -> String {
        guard let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]],
              let detectedText = textAnnotations.first?["description"] as? String else { return "" }
        return detectedText
    }

    // Add the parseWebDetection function here
    private static func parseWebDetection(from responses: [[String: Any]]) -> [String] {
        guard let webDetection = responses.first?["webDetection"] as? [String: Any] else { return [] }
        
        // Parse relevant web detection fields (e.g., best guesses and entities)
        let bestGuessLabels = webDetection["bestGuessLabels"] as? [[String: Any]]
        let webEntities = webDetection["webEntities"] as? [[String: Any]]
        
        var result: [String] = []
        
        // Add best guess labels to result
        if let bestGuesses = bestGuessLabels {
            result.append(contentsOf: bestGuesses.compactMap { $0["label"] as? String })
        }
        
        // Add descriptions of web entities to result
        if let entities = webEntities {
            result.append(contentsOf: entities.compactMap { $0["description"] as? String })
        }
        
        return result
    }
}

