import Foundation

struct DataStorage {
    static let datasetFileName = "gpt_dataset.jsonl"

    static func saveResponseToDataset(imageDetails: String, commentText: String, completion: String, quality: String) {
        // Only save responses with quality "good"
        guard quality == "good" else {
            print("Skipping bad response.")
            return
        }

        // Create the dataset entry in JSON format
        let prompt = "\(imageDetails)\(commentText.isEmpty ? "" : " Comment: \(commentText)")"
        let datasetEntry = [
            "prompt": prompt,
            "completion": completion,
            "quality": quality
        ]

        // Convert the entry to a JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: datasetEntry, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to convert dataset entry to JSON")
            return
        }

        // Get the file URL for the dataset
        let fileURL = getDatasetFileURL()

        // Append the JSON string as a new line to the dataset file
        do {
            let jsonlEntry = jsonString + "\n" // Add a newline for JSONL format
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Append to existing file
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = jsonlEntry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                // Create a new file
                try jsonlEntry.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            print("Saved to dataset: \(datasetEntry)")
        } catch {
            print("Error saving dataset: \(error)")
        }
    }


    // Get the file URL for the dataset
    private static func getDatasetFileURL() -> URL {
        // Save the file in the app's Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(datasetFileName)
        print("Dataset file location: \(fileURL.path)")
        return fileURL
    }
}

