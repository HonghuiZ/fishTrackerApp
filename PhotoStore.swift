import SwiftUI

class PhotoStore: ObservableObject {
    @Published var photos: [PhotoMetadata] = []
    
    private let metadataFileName = "photoMetadata.json"
    
    func saveMetadata(_ metadata: [PhotoMetadata]) {
        do {
            let data = try JSONEncoder().encode(metadata)
            let fileURL = getDocumentsDirectory().appendingPathComponent(metadataFileName)
            try data.write(to: fileURL)
            photos = metadata  // Update the published property
            objectWillChange.send()  // Notify observers
            print("Metadata saved successfully")
        } catch {
            print("Error saving metadata: \(error)")
        }
    }
    
    func loadMetadata() -> [PhotoMetadata] {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(metadataFileName)
            let data = try Data(contentsOf: fileURL)
            let metadata = try JSONDecoder().decode([PhotoMetadata].self, from: data)
            photos = metadata  // Update the published property
            return metadata
        } catch {
            print("Error loading metadata: \(error)")
            return []
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 