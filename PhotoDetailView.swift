import SwiftUI
import MapKit

struct PhotoDetailView: View {
    let photo: PhotoMetadata
    
    var body: some View {
        ScrollView {
            PhotoCard(photo: photo)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                if !photo.species.isEmpty {
                    Text("Species: \(photo.species)")
                        .font(.headline)
                }
                if !photo.location.isEmpty {
                    Text("Location: \(photo.location)")
                        .font(.subheadline)
                }
                Text("Date: \(photo.timestamp.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let lat = photo.latitude, let lon = photo.longitude {
                    Text("Coordinates: \(lat), \(lon)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(photo.species.isEmpty ? "Photo Details" : photo.species)
    }
}


struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(photo: PhotoMetadata(
            id: UUID(),
            fileName: "example.jpg",
            location: "Park",
            timestamp: Date(),
            hash: "examplehash",
            pHash: "examplephash",
            species: "Bird",
            latitude: 40.7128,
            longitude: -74.0060
        ))
    }
} 
