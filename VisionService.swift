import Foundation
import UIKit

struct VisionService {
    static func analyzeImage(with imageData: Data, apiKey: String, completion: @escaping (_ structuredData: [String: Any]?) -> Void) {
        // Extract image dimensions
        let image = UIImage(data: imageData)
        let imageWidth = image?.size.width ?? 1 // Default to 1 to avoid division by zero
        let imageHeight = image?.size.height ?? 1

        // Debug: Log image dimensions
        print("Image Dimensions - Width: \(imageWidth), Height: \(imageHeight)")

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
            
            if var structuredData = parseResponse(data: data, imageWidth: imageWidth, imageHeight: imageHeight) {
                // Add image dimensions to the structured data
                structuredData["imageWidth"] = imageWidth
                structuredData["imageHeight"] = imageHeight

                // Determine if this is a group photo
                if let facialData = structuredData["facialExpressions"] as? [String: Any],
                   let faceCount = facialData["count"] as? Int {
                    structuredData["isGroupPhoto"] = (faceCount > 1) // Set true if multiple faces detected
                }

                // Check for human-related labels or objects
                if let labels = structuredData["labels"] as? [String],
                   let objects = structuredData["objects"] as? [String],
                   !containsHuman(labels: labels, objects: objects) {
                    print("No human detected in the image.")
                    completion(["noHuman": true])
                } else {
                    // Debug: Print the structured data
                    print("Structured Data Before Completion: \(structuredData)")

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

    private static func parseResponse(data: Data, imageWidth: Double, imageHeight: Double) -> [String: Any]? {

        guard let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let responses = responseData["responses"] as? [[String: Any]] else {
            print("Failed to parse response data.")
            return nil
        }

        print("Full Vision API Response: \(responses)")

        let labels = parseLabels(from: responses)
        let objects = parseObjects(from: responses)
        let facialData = parseFaces(from: responses, imageWidth: imageWidth, imageHeight: imageHeight) // Correct name
        let colors = parseColors(from: responses)
        let detectedText = parseText(from: responses)

        // Debug: Log facial data to confirm group photo info is included
        print("Facial Data in parseResponse: \(facialData)") // Use the correct name here

        return [
            "labels": labels,
            "objects": objects,
            "facialExpressions": facialData, // Ensure this matches the corrected name
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

    private static func parseFaces(from responses: [[String: Any]], imageWidth: Double, imageHeight: Double) -> [String: Any] {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]] else {
            print("No face annotations found")
            return [:]
        }

        // Minimum threshold for face size
        let minimumAreaThreshold: Double = 0.002

        let calculateBoundingBoxArea = { (vertices: [[String: Any]], imageWidth: Double, imageHeight: Double) -> Double in
            print("Raw Vertices: \(vertices)")

            // Extract all x and y coordinates
            let xCoordinates = vertices.compactMap { $0["x"] as? Double }
            let yCoordinates = vertices.compactMap { $0["y"] as? Double }

            // Ensure we have enough points
            guard xCoordinates.count == 4, yCoordinates.count == 4 else {
                print("Invalid vertices data: \(vertices)")
                return 0
            }

            // Calculate the bounding box explicitly
            let x1 = xCoordinates.min() ?? 0
            let x2 = xCoordinates.max() ?? 0
            let y1 = yCoordinates.min() ?? 0
            let y2 = yCoordinates.max() ?? 0

            print("Extracted Vertices - x1: \(x1), x2: \(x2), y1: \(y1), y2: \(y2)")

            let boxWidth = abs(x2 - x1)
            let boxHeight = abs(y2 - y1)
            let relativeArea = (boxWidth * boxHeight) / (imageWidth * imageHeight)

            print("Box Width: \(boxWidth), Box Height: \(boxHeight), Relative Area: \(relativeArea)")
            return relativeArea
        }

        let isCentral = { (vertices: [[String: Any]], imageWidth: Double) -> Bool in
            // Use the correct bounding box center calculation
            let xCoordinates = vertices.compactMap { $0["x"] as? Double }
            guard let x1 = xCoordinates.min(), let x2 = xCoordinates.max() else {
                print("Invalid vertices for isCentral check")
                return false
            }

            let centerX = (x1 + x2) / 2.0 / imageWidth // Normalize to image width
            print("Bounding Box CenterX (Relative): \(centerX)")
            return centerX > 0.3 && centerX < 0.7 // Consider central if within 30-70% of the image width
        }

        var filteredSubjects: [[String: Any]] = []
        var largestArea: Double = 0
        var mainSubjectFace: [String: Any]?

        for annotation in faceAnnotations {
            if let boundingPoly = annotation["boundingPoly"] as? [String: Any],
               let vertices = boundingPoly["vertices"] as? [[String: Any]] {

                // Calculate the relative area of the bounding box
                let area = calculateBoundingBoxArea(vertices, imageWidth, imageHeight)

                // Check if the bounding box is central
                if area > minimumAreaThreshold && isCentral(vertices, imageWidth) {
                    filteredSubjects.append(annotation)

                    // Identify the largest face
                    if area > largestArea {
                        largestArea = area
                        mainSubjectFace = annotation
                    }
                }
            }
        }

        // Determine if it's a group photo
        let isGroupPhoto = filteredSubjects.count > 1

        // Debug: Print detection details
        print("Filtered Subjects Count: \(filteredSubjects.count)")
        print("Is Group Photo: \(isGroupPhoto)")
        print("Raw Face Annotations: \(faceAnnotations)")

        var facialData: [String: Any] = [:]
        facialData["count"] = filteredSubjects.count
        facialData["mainSubject"] = isGroupPhoto ? nil : mainSubjectFace
        facialData["groupSubjects"] = isGroupPhoto ? filteredSubjects : nil
        facialData["isGroupPhoto"] = isGroupPhoto // Explicitly add this to ensure it's communicated correctly
        print("Facial Data in parseResponse: \(facialData)")


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
