import SwiftUI
import Foundation

class PhotoStore: ObservableObject {
    @Published var shouldRefresh = false
    @Published private(set) var photos: [PhotoMetadata] = []
    
    init() {
        // Load photos initially
        photos = loadMetadata()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    public func loadMetadata() -> [PhotoMetadata] {
        let url = getDocumentsDirectory().appendingPathComponent("metadata.json")
        
        do {
            let data = try Data(contentsOf: url)
            let metadata = try JSONDecoder().decode([PhotoMetadata].self, from: data)
            // Update the cached photos
            photos = metadata
            return metadata
        } catch {
            print("Error loading metadata: \(error)")
            photos = []
            return []
        }
    }
    
    public func saveMetadata(_ metadata: [PhotoMetadata]) {
        let url = getDocumentsDirectory().appendingPathComponent("metadata.json")
        
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: url)
            // Update the cached photos
            photos = metadata
            shouldRefresh.toggle() // Trigger UI refresh
        } catch {
            print("Error saving metadata: \(error)")
        }
    }
    
    func deletePhoto(withId id: UUID) {
        print("\n=== 🗑️ Deleting Photo ===")
        // First remove the file
        if let metadata = loadMetadata().first(where: { $0.id == id }) {
            let fileURL = getDocumentsDirectory().appendingPathComponent(metadata.fileName)
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ Deleted file: \(metadata.fileName)")
            } catch {
                print("❌ Error deleting file: \(error)")
            }
        }
        
        // Then remove from metadata
        var metadata = loadMetadata()
        let initialCount = metadata.count
        metadata.removeAll(where: { $0.id == id })
        saveMetadata(metadata)
        
        print("📊 Deletion summary:")
        print("- Initial metadata count: \(initialCount)")
        print("- Final metadata count: \(metadata.count)")
        print("==================\n")
    }
    
    func refreshPhotos() {
        // Actually load the photos from disk when refresh is requested
        _ = loadMetadata()
        shouldRefresh.toggle()
    }
} 
