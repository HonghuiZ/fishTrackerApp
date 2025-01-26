import SwiftUI
import MapKit
import UIKit

/// A view that serves as the main interface for browsing and filtering photos.
/// This view provides:
/// - Monthly grouping of photos in a grid layout
/// - Toggle between grid and map view
/// - Species-based filtering
/// - Navigation to photo details
///
/// This is the primary browsing interface where users can:
/// - View photos organized by month
/// - Filter photos by species
/// - Switch between grid and map views
struct MainPageView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var searchText = ""
    @State private var showingMap = false
    @State private var selectedSpecies: String? = nil
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Get unique species from photos
    private var availableSpecies: [String] {
        let species = Set(photoStore.photos.map { $0.species })
        return species.sorted()
    }
    
    // Filter photos based on selected species
    private var filteredPhotos: [PhotoMetadata] {
        guard let selectedSpecies = selectedSpecies else {
            return photoStore.photos
        }
        return photoStore.photos.filter { $0.species == selectedSpecies }
    }
    
    // Computed property to group photos by month
    private var groupedPhotos: [(String, [PhotoMetadata])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: filteredPhotos) { photo in
            formatter.string(from: photo.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("View", selection: $showingMap) {
                    Image(systemName: "square.grid.3x3").tag(false)
                    Image(systemName: "map").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Menu {
                    Button("All Species") {
                        selectedSpecies = nil
                    }
                    
                    Divider()
                    
                    ForEach(availableSpecies, id: \.self) { species in
                        Button(species) {
                            selectedSpecies = species
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSpecies ?? "All Species")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            if showingMap {
                MapView(photos: filteredPhotos)
            } else {
                if filteredPhotos.isEmpty {
                    ContentUnavailableView(
                        "No Photos Found",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text(selectedSpecies != nil ? "No photos found for \(selectedSpecies!)" : "No photos available")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(groupedPhotos, id: \.0) { month, photos in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(month)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(photos) { metadata in
                                            NavigationLink(destination: PhotoDetailView(photo: metadata)) {
                                                PhotoThumbnail(metadata: metadata)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            _ = photoStore.loadMetadata()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func debugStorage() {
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
}

/// A reusable component for displaying photo thumbnails in the grid
/// Extracts thumbnail rendering logic to keep the main view clean
private struct PhotoThumbnail: View {
    let metadata: PhotoMetadata
    
    var body: some View {
        Group {
            if let imageData = try? Data(contentsOf: getDocumentsDirectory().appendingPathComponent(metadata.fileName)),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: UIScreen.main.bounds.width / 3)
                    .clipped()
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    NavigationView {
        MainPageView()
    }
} 