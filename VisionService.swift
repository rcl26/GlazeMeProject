import Foundation

struct VisionService {
    static func analyzeImage(with imageData: Data, apiKey: String, completion: @escaping (String?) -> Void) {
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
                        ["type": "LABEL_DETECTION", "maxResults": 5]
                    ]
                ]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
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
            
            let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            print("Vision API Response: \(String(describing: responseData))")
            
            if let labels = responseData?["responses"] as? [[String: Any]],
               let labelAnnotations = labels.first?["labelAnnotations"] as? [[String: Any]] {
                let labels = labelAnnotations.compactMap { $0["description"] as? String }
                let prompt = "The following parts are identified in the image: " + labels.joined(separator: ", ") + ". Can you provide a creative compliment or description of the person based on these details?"
                completion(prompt)

            } else {
                completion(nil)
            }
        }.resume()
    }
}

