import SwiftUI
import UIKit

struct PhotoCard: View {
    let photo: PhotoMetadata
    
    var body: some View {
        AsyncImage(url: getDocumentsDirectory().appendingPathComponent(photo.fileName)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 