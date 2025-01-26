import Foundation

class DebugService {
    static let shared = DebugService()
    
    private init() {}
    
    func debugStorage() {
        // Check UserDefaults
        print("\n=== Checking UserDefaults ===")
        if let data = UserDefaults.standard.data(forKey: "savedPhotosMetadata") {
            if let metadata = try? JSONDecoder().decode([PhotoMetadata].self, from: data) {
                print("Found \(metadata.count) photos in metadata")
                for meta in metadata {
                    print("- Photo: \(meta.fileName), Date: \(meta.timestamp)")
                }
            }
        } else {
            print("No metadata found in UserDefaults")
        }
        
        // Check Documents Directory
        print("\n=== Checking Documents Directory ===")
        let documentsPath = getDocumentsDirectory()
        print("Documents path: \(documentsPath)")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            print("Found \(files.count) files:")
            for file in files {
                print("- \(file.lastPathComponent)")
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        print("===========================\n")
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 