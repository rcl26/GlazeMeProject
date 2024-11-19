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
                // Directly pass structured data to GPTService
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
                        ["type": "FACE_DETECTION"],
                        ["type": "LABEL_DETECTION"],
                        ["type": "LANDMARK_DETECTION"],
                        ["type": "LOGO_DETECTION"],
                        ["type": "TEXT_DETECTION"],
                        ["type": "OBJECT_LOCALIZATION"],
                        ["type": "SAFE_SEARCH_DETECTION"]
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

        // Extract individual components
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

    private static func parseLabels(from responses: [[String: Any]]) -> [String] {
        guard let labelAnnotations = responses.first?["labelAnnotations"] as? [[String: Any]] else { return [] }
        return labelAnnotations.compactMap { $0["description"] as? String }
    }

    private static func parseWebDetection(from responses: [[String: Any]]) -> [String] {
        guard let webDetection = responses.first?["webDetection"] as? [String: Any],
              let bestGuessLabels = webDetection["bestGuessLabels"] as? [[String: Any]],
              let webEntities = webDetection["webEntities"] as? [[String: Any]] else { return [] }
        
        let bestGuesses = bestGuessLabels.compactMap { $0["label"] as? String }
        let entityDescriptions = webEntities.compactMap { $0["description"] as? String }
        return bestGuesses + entityDescriptions
    }

    private static func parseFaces(from responses: [[String: Any]]) -> [String: String] {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]],
              let faceAttributes = faceAnnotations.first else { return [:] }
        
        var expressions: [String: String] = [:]
        if let joyLikelihood = faceAttributes["joyLikelihood"] as? String {
            expressions["joy"] = joyLikelihood
        }
        if let angerLikelihood = faceAttributes["angerLikelihood"] as? String {
            expressions["anger"] = angerLikelihood
        }
        if let sorrowLikelihood = faceAttributes["sorrowLikelihood"] as? String {
            expressions["sorrow"] = sorrowLikelihood
        }
        if let surpriseLikelihood = faceAttributes["surpriseLikelihood"] as? String {
            expressions["surprise"] = surpriseLikelihood
        }
        return expressions
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

    private static func parseObjects(from responses: [[String: Any]]) -> [String] {
        guard let localizedObjectAnnotations = responses.first?["localizedObjectAnnotations"] as? [[String: Any]] else { return [] }
        return localizedObjectAnnotations.compactMap { $0["name"] as? String }
    }

    private static func parseText(from responses: [[String: Any]]) -> String {
        guard let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]],
              let detectedText = textAnnotations.first?["description"] as? String else { return "" }
        return detectedText
    }
}

