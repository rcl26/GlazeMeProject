import Foundation
import UIKit

struct VisionService {
    static func analyzeImage(with imageData: Data, apiKey: String, completion: @escaping (_ structuredData: [String: Any]?) -> Void) {
        // Extract image dimensions
        guard let image = UIImage(data: imageData) else {
            print("Failed to decode image data")
            completion(nil)
            return
        }
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        if imageWidth <= 0 || imageHeight <= 0 {
            print("Invalid image dimensions: Width: \(imageWidth), Height: \(imageHeight)")
            completion(nil)
            return
        }

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

                // Ensure isGroupPhoto is always calculated
                if let facialData = structuredData["facialExpressions"] as? [String: Any],
                   let faceCount = facialData["count"] as? Int {
                    structuredData["isGroupPhoto"] = (faceCount > 1) // True if multiple faces detected
                } else {
                    structuredData["isGroupPhoto"] = false // Default to false if no facial data exists
                }

                // Debug: Log group photo detection
                print("Debug - Group Photo Detection: \(structuredData["isGroupPhoto"] ?? "N/A")")

                // Safe Search handling
                if let safeSearch = structuredData["safeSearch"] as? [String: String],
                   safeSearch["adult"] == "LIKELY" || safeSearch["adult"] == "VERY_LIKELY" ||
                   safeSearch["violence"] == "LIKELY" || safeSearch["violence"] == "VERY_LIKELY" ||
                   safeSearch["racy"] == "LIKELY" || safeSearch["racy"] == "VERY_LIKELY" {
                    print("Inappropriate content detected: \(safeSearch)")
                    structuredData["error"] = "Inappropriate content detected. Please upload a different image."
                    completion(structuredData)
                    return
                }

                // Check for human-related labels or objects
                if let labels = structuredData["labels"] as? [String],
                   let objects = structuredData["objects"] as? [String],
                   !containsHuman(labels: labels, objects: objects) {
                    print("No human detected in the image, but proceeding with analysis.")
                    structuredData["subject"] = labels.first ?? "image" // Use first label as the subject
                }

                // Debug: Print the structured data
                print("Debug - Final Structured Data Before Completion: \(structuredData)")

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
                        ["type": "FACE_DETECTION"],
                        ["type": "OBJECT_LOCALIZATION"],
                        ["type": "LABEL_DETECTION"],
                        ["type": "TEXT_DETECTION"],
                        ["type": "SAFE_SEARCH_DETECTION"], // Add Safe Search Detection
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
        let facialData = parseFaces(from: responses, imageWidth: imageWidth, imageHeight: imageHeight)
        let colors = parseColors(from: responses)
        let detectedText = parseText(from: responses)
        let safeSearch = parseSafeSearch(from: responses)

        return [
            "labels": labels,
            "objects": objects,
            "facialExpressions": facialData,
            "colors": colors,
            "text": detectedText,
            "safeSearch": safeSearch // Include Safe Search in structured data
        ]
    }

    private static func parseSafeSearch(from responses: [[String: Any]]) -> [String: String] {
        guard let safeSearchAnnotation = responses.first?["safeSearchAnnotation"] as? [String: Any] else {
            return [:]
        }

        return [
            "adult": safeSearchAnnotation["adult"] as? String ?? "UNKNOWN",
            "violence": safeSearchAnnotation["violence"] as? String ?? "UNKNOWN",
            "racy": safeSearchAnnotation["racy"] as? String ?? "UNKNOWN"
        ]
    }

    private static func containsHuman(labels: [String], objects: [String]) -> Bool {
        // Check if there are human-related keywords in labels or objects
        let humanKeywords = ["person", "face"]
        return labels.contains(where: { humanKeywords.contains($0.lowercased()) }) ||
               objects.contains(where: { humanKeywords.contains($0.lowercased()) })
    }

    private static func parseFaces(from responses: [[String: Any]], imageWidth: Double, imageHeight: Double) -> [String: Any] {
        guard let faceAnnotations = responses.first?["faceAnnotations"] as? [[String: Any]] else {
            print("No face annotations found")
            return [:]
        }

        var filteredSubjects: [[String: Any]] = []
        var largestArea: Double = 0
        var mainSubjectFace: [String: Any]?

        for annotation in faceAnnotations {
            if let boundingPoly = annotation["boundingPoly"] as? [String: Any],
               let vertices = boundingPoly["vertices"] as? [[String: Any]] {
                let area = calculateBoundingBoxArea(vertices, imageWidth, imageHeight)

                if area > 0.002 { // Minimum area threshold
                    filteredSubjects.append(annotation)
                    if area > largestArea {
                        largestArea = area
                        mainSubjectFace = annotation
                    }
                }
            }
        }

        let isGroupPhoto = filteredSubjects.count > 1
        let resolvedMainSubject: [String: Any]? = isGroupPhoto ? nil : mainSubjectFace

        return [
            "count": filteredSubjects.count,
            "mainSubject": resolvedMainSubject ?? [:],
            "groupSubjects": isGroupPhoto ? filteredSubjects : [],
            "isGroupPhoto": isGroupPhoto
        ]
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

        return colors.compactMap { colorInfo in
            guard let color = colorInfo["color"] as? [String: Any],
                  let red = color["red"] as? Double,
                  let green = color["green"] as? Double,
                  let blue = color["blue"] as? Double else { return nil }

            return describeColor(red: red, green: green, blue: blue)
        }
    }

    private static func parseText(from responses: [[String: Any]]) -> String {
        guard let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]],
              let detectedText = textAnnotations.first?["description"] as? String else { return "" }
        return detectedText
    }

    private static func calculateBoundingBoxArea(_ vertices: [[String: Any]], _ imageWidth: Double, _ imageHeight: Double) -> Double {
        let xCoordinates = vertices.compactMap { $0["x"] as? Double }
        let yCoordinates = vertices.compactMap { $0["y"] as? Double }

        guard xCoordinates.count == 4, yCoordinates.count == 4 else { return 0 }

        let x1 = xCoordinates.min() ?? 0
        let x2 = xCoordinates.max() ?? 0
        let y1 = yCoordinates.min() ?? 0
        let y2 = yCoordinates.max() ?? 0

        return abs((x2 - x1) * (y2 - y1)) / (imageWidth * imageHeight)
    }

    private static func describeColor(red: Double, green: Double, blue: Double) -> String {
        if red > 200, green > 200, blue > 200 { return "white" }
        if red < 50, green < 50, blue < 50 { return "black" }
        if red > green, red > blue { return "red" }
        if green > red, green > blue { return "green" }
        if blue > red, blue > green { return "blue" }
        return "gray"
    }
}

