import SwiftUI
import UIKit

/// A reusable component for displaying photo thumbnails in the grid
struct PhotoThumbnail: View {
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