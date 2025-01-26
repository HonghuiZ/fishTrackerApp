import SwiftUI
import MapKit

struct PhotoViewPage: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var searchText = ""
    @State private var showingMap = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            Picker("View", selection: $showingMap) {
                Image(systemName: "square.grid.3x3").tag(false)
                Image(systemName: "map").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if showingMap {
                MapView(photos: photoStore.photos)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(photoStore.photos) { metadata in
                            NavigationLink(destination: PhotoDetailView(metadata: metadata)) {
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

#Preview {
    NavigationView {
        PhotoViewPage()
    }
} 