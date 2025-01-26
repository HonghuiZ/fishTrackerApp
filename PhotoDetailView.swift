import SwiftUI
import MapKit
import UIKit

struct PhotoDetailView: View {
    let photo: PhotoMetadata
    @State private var region: MKCoordinateRegion
    @State private var imageSize: CGSize = .zero
    
    init(photo: PhotoMetadata) {
        self.photo = photo
        // Initialize map region with photo coordinates or default to a fallback location
        let coordinate = CLLocationCoordinate2D(
            latitude: photo.latitude ?? 0,
            longitude: photo.longitude ?? 0
        )
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Photo
                if let image = loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.onAppear {
                                    imageSize = geometry.size
                                }
                            }
                        )
                }
                
                // Location and Map
                if photo.latitude != nil && photo.longitude != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📍 Location")
                            .font(.headline)
                        
                        if !photo.location.isEmpty {
                            Text(photo.location)
                                .font(.subheadline)
                        }
                        
                        Map(coordinateRegion: $region, annotationItems: [photo]) { photo in
                            MapMarker(
                                coordinate: CLLocationCoordinate2D(
                                    latitude: photo.latitude ?? 0,
                                    longitude: photo.longitude ?? 0
                                ),
                                tint: .red
                            )
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("📝 Details")
                        .font(.headline)
                    
                    if !photo.species.isEmpty {
                        Text("Species: \(photo.species)")
                    }
                    
                    Text("Date: \(photo.timestamp.formatted(date: .long, time: .shortened))")
                    
                    if let dimensions = getImageDimensions() {
                        Text("Dimensions: \(dimensions.width) × \(dimensions.height)")
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadImage() -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(photo.fileName)
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    
    private func getImageDimensions() -> CGSize? {
        if let image = loadImage() {
            return CGSize(width: image.size.width, height: image.size.height)
        }
        return nil
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
