import Foundation

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
                let prompt = "Based on the image analysis: \(description). Can you provide a creative compliment or description of the person based on these details?"
                completion(prompt)
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
                        ["type": "LABEL_DETECTION", "maxResults": 5],
                        ["type": "FACE_DETECTION"],
                        ["type": "IMAGE_PROPERTIES"],
                        ["type": "OBJECT_LOCALIZATION", "maxResults": 5],
                        ["type": "TEXT_DETECTION"]
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
        let faceDescription = parseFaces(from: responses)
        let colorDescription = parseColors(from: responses)
        let objectDescription = parseObjects(from: responses)
        let textDescription = parseText(from: responses)

        return [labelsDescription, faceDescription, colorDescription, objectDescription, textDescription]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }
    
    private static func parseLabels(from responses: [[String: Any]]) -> String {
        guard let labelAnnotations = responses.first?["labelAnnotations"] as? [[String: Any]] else { return "" }
        let labels = labelAnnotations.compactMap { $0["description"] as? String }
        return "Identified objects: " + labels.joined(separator: ", ")
    }
    
    private static func parseFaces(from responses: [[String: Any]]) -> String {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]],
              let faceAttributes = faceAnnotations.first else { return "" }
        
        let joyLikelihood = faceAttributes["joyLikelihood"] as? String ?? "unknown"
        let angerLikelihood = faceAttributes["angerLikelihood"] as? String ?? "unknown"
        let sorrowLikelihood = faceAttributes["sorrowLikelihood"] as? String ?? "unknown"
        let surpriseLikelihood = faceAttributes["surpriseLikelihood"] as? String ?? "unknown"
        
        return "Facial expression - Joy: \(joyLikelihood), Anger: \(angerLikelihood), Sorrow: \(sorrowLikelihood), Surprise: \(surpriseLikelihood)"
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

