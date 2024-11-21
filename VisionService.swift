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
                // Check for human-related labels or objects
                if let labels = structuredData["labels"] as? [String],
                   let objects = structuredData["objects"] as? [String],
                   !containsHuman(labels: labels, objects: objects) {
                    print("No human detected in the image.")
                    completion(["noHuman": true])
                } else {
                    // Pass structured data to the completion handler
                    completion(structuredData)
                }
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
                        ["type": "OBJECT_LOCALIZATION"],
                        ["type": "LABEL_DETECTION"],
                        ["type": "TEXT_DETECTION"],
                        ["type": "SAFE_SEARCH_DETECTION"],
                        ["type": "IMAGE_PROPERTIES"]
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

        print("Full Vision API Response: \(responses)")

        let labels = parseLabels(from: responses)
        let objects = parseObjects(from: responses)
        let facialExpressions = parseFaces(from: responses)
        let colors = parseColors(from: responses)
        let detectedText = parseText(from: responses)

        return [
            "labels": labels,
            "objects": objects,
            "facialExpressions": facialExpressions,
            "colors": colors,
            "text": detectedText
        ]
    }

    private static func containsHuman(labels: [String], objects: [String]) -> Bool {
        // Check if "person" or "face" is in labels or objects
        let humanKeywords = ["person", "face"]
        return labels.contains(where: { humanKeywords.contains($0.lowercased()) }) ||
               objects.contains(where: { humanKeywords.contains($0.lowercased()) })
    }

    private static func parseFaces(from responses: [[String: Any]]) -> [String: Any] {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]] else {
            print("No face annotations found")
            return [:]
        }

        // Extract bounding boxes and identify the largest/central face
        var mainSubjectFace: [String: Any]?
        var largestArea: Double = 0

        for annotation in faceAnnotations {
            if let boundingPoly = annotation["boundingPoly"] as? [String: Any],
               let vertices = boundingPoly["vertices"] as? [[String: Any]],
               let x1 = vertices.first?["x"] as? Double,
               let y1 = vertices.first?["y"] as? Double,
               let x2 = vertices.last?["x"] as? Double,
               let y2 = vertices.last?["y"] as? Double {
                let area = abs(x2 - x1) * abs(y2 - y1)
                if area > largestArea {
                    largestArea = area
                    mainSubjectFace = annotation
                }
            }
        }

        var facialData: [String: Any] = [:]
        facialData["count"] = faceAnnotations.count
        facialData["mainSubject"] = mainSubjectFace // Include main subject's face attributes if available

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

    private static func parseColors(from responses: [[String: Any]]) -> [String] {
        guard let imagePropertiesAnnotation = responses.first?["imagePropertiesAnnotation"] as? [String: Any],
              let dominantColors = imagePropertiesAnnotation["dominantColors"] as? [String: Any],
              let colors = dominantColors["colors"] as? [[String: Any]] else { return [] }

        // Convert colors to human-readable names
        return colors.compactMap { colorInfo in
            guard let color = colorInfo["color"] as? [String: Any],
                  let red = color["red"] as? Double,
                  let green = color["green"] as? Double,
                  let blue = color["blue"] as? Double else { return nil }

            return describeColor(red: red, green: green, blue: blue)
        }
    }

    private static func describeColor(red: Double, green: Double, blue: Double) -> String {
        // Normalize RGB values to a 0–1 range
        let r = red / 255.0
        let g = green / 255.0
        let b = blue / 255.0

        // Simple thresholds for categorizing colors
        if r > 0.8 && g > 0.8 && b > 0.8 { return "white" }
        if r < 0.2 && g < 0.2 && b < 0.2 { return "black" }
        if r > 0.8 && g < 0.2 && b < 0.2 { return "red" }
        if r < 0.2 && g > 0.8 && b < 0.2 { return "green" }
        if r < 0.2 && g < 0.2 && b > 0.8 { return "blue" }
        if r > 0.8 && g > 0.8 && b < 0.2 { return "yellow" }
        if r > 0.8 && g < 0.2 && b > 0.8 { return "magenta" }
        if r < 0.2 && g > 0.8 && b > 0.8 { return "cyan" }
        if r > 0.6 && g > 0.4 && b < 0.2 { return "orange" }
        if r > 0.4 && g > 0.2 && b > 0.6 { return "violet" }
        if r > 0.6 && g < 0.4 && b > 0.2 { return "pink" }

        // Fallback to general description
        return "grayish"
    }

    private static func parseText(from responses: [[String: Any]]) -> String {
        guard let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]],
              let detectedText = textAnnotations.first?["description"] as? String else { return "" }
        return detectedText
    }
}
