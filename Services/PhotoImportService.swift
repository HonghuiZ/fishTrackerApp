import SwiftUI
import CryptoKit

@MainActor
class PhotoImportService {
    static let shared = PhotoImportService()
    private let photoProcessor = PhotoProcessor.shared
    
    private init() {}
    
    func importPhotos(from scanner: PhotoScanner, into photoStore: PhotoStore) {
        print("\n=== 📥 Importing Scanned Photos ===")
        let existingPhotos = photoStore.loadMetadata()
        var newPhotos: [PhotoMetadata] = []
        var skippedCount = 0
        
        Task {
            for photo in scanner.foundFishPhotos {
                if let processed = await photoProcessor.processPhoto(
                    imageData: photo.imageData,
                    location: photo.location,
                    species: photo.species,
                    timestamp: photo.timestamp,
                    photoStore: photoStore
                ) {
                    print("\n=== 📸 Creating Photo Metadata ===")
                    print("- Input timestamp: \(photo.timestamp)")
                    print("- Processed timestamp: \(processed.timestamp)")
                    
                    let newPhoto = PhotoMetadata(
                        id: UUID(),
                        fileName: processed.fileName,
                        location: processed.location,
                        timestamp: processed.timestamp,
                        hash: processed.hash,
                        pHash: processed.pHash,
                        species: processed.species,
                        latitude: processed.latitude,
                        longitude: processed.longitude
                    )
                    print("- Final metadata timestamp: \(newPhoto.timestamp)")
                    newPhotos.append(newPhoto)
                    print("✅ Imported: \(processed.fileName)")
                } else {
                    skippedCount += 1
                }
            }
            
            // Update metadata with new photos
            let updatedPhotos = existingPhotos + newPhotos
            photoStore.saveMetadata(updatedPhotos)
            
            print("📊 Import summary:")
            print("- Found fish photos: \(scanner.foundFishPhotos.count)")
            print("- Skipped: \(skippedCount)")
            print("- Successfully imported: \(newPhotos.count)")
            print("- Total photos now: \(updatedPhotos.count)")
            print("==================\n")
        }
    }
} 