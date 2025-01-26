import SwiftUI
import Foundation

struct Photo: Identifiable, Comparable, Codable {
    let id: UUID
    var imageData: Data
    var timestamp: Date
    var location: String?
    var species: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageData
        case timestamp
        case location
        case species
    }
    
    init(id: UUID = UUID(), imageData: Data, timestamp: Date = Date(), location: String? = nil, species: String? = nil) {
        self.id = id
        self.imageData = imageData
        self.timestamp = timestamp
        self.location = location
        self.species = species
    }
    
    // Debug helper
    func printLocationInfo() {
        print("Photo location info:")
        print("- Location string: \(location ?? "")")
    }
    
    var tags: Set<String> {
        let speciesTags = species?.lowercased().split(separator: " ").map(String.init) ?? []
        return Set(speciesTags + [species?.lowercased() ?? ""])
    }
    
    // Comparable conformance for sorting
    static func < (lhs: Photo, rhs: Photo) -> Bool {
        lhs.timestamp > rhs.timestamp
    }
    
    // Formatted time string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
} 
