import SwiftUI
import MapKit

struct PhotoDetailView: View {
    let metadata: PhotoMetadata
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = metadata.latitude,
              let lon = metadata.longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var body: some View {
        ScrollView {
            if let imageData = try? Data(contentsOf: getDocumentsDirectory().appendingPathComponent(metadata.fileName)),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Species: \(metadata.species)")
                Text("Location: \(metadata.location)")
                Text("Date: \(metadata.timestamp.formatted())")
                
                if let coordinate = coordinate {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker(metadata.species, coordinate: coordinate)
                    }
                    .frame(height: 200)
                }
            }
            .padding()
        }
        .navigationTitle("Photo Details")
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 