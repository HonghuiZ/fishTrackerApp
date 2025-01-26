import Foundation

struct PhotoMetadata: Codable, Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let location: String
    let timestamp: Date
    let hash: String
    let pHash: String
    let species: String
    let latitude: Double?
    let longitude: Double?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoMetadata, rhs: PhotoMetadata) -> Bool {
        lhs.id == rhs.id
    }
} 