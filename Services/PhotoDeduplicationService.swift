import SwiftUI
import CryptoKit

class PhotoDeduplicationService {
    static let shared = PhotoDeduplicationService()
    private let similarityThreshold = 10  // Threshold for perceptual hash comparison
    
    private init() {}
    
    struct DeduplicationResult {
        let isDuplicate: Bool
        let duplicatePhoto: PhotoMetadata?
        let exactHash: String
        let pHash: String
        let distance: Int?
    }
    
    func checkForDuplicates(imageData: Data, against existingPhotos: [PhotoMetadata]) -> DeduplicationResult {
        // Generate hashes for deduplication
        let exactHash = generateHash(from: imageData)
        guard let pHash = ImageHasher.shared.calculatePerceptualHash(from: UIImage(data: imageData) ?? UIImage()) else {
            print("❌ Failed to generate perceptual hash")
            return DeduplicationResult(isDuplicate: false, duplicatePhoto: nil, exactHash: exactHash, pHash: "", distance: nil)
        }
        
        // Check for duplicates
        for existingPhoto in existingPhotos {
            // Check exact hash match
            if existingPhoto.hash == exactHash {
                print("🔍 Found exact duplicate: \(existingPhoto.fileName)")
                return DeduplicationResult(
                    isDuplicate: true,
                    duplicatePhoto: existingPhoto,
                    exactHash: exactHash,
                    pHash: pHash,
                    distance: 0
                )
            }
            
            // Check perceptual hash similarity
            if let distance = ImageHasher.shared.hammingDistance(pHash, existingPhoto.pHash),
               distance <= similarityThreshold {
                print("🔍 Found similar photo: \(existingPhoto.fileName) (distance: \(distance))")
                return DeduplicationResult(
                    isDuplicate: true,
                    duplicatePhoto: existingPhoto,
                    exactHash: exactHash,
                    pHash: pHash,
                    distance: distance
                )
            }
        }
        
        return DeduplicationResult(
            isDuplicate: false,
            duplicatePhoto: nil,
            exactHash: exactHash,
            pHash: pHash,
            distance: nil
        )
    }
    
    private func generateHash(from data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
} 