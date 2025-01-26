import SwiftUI
import UIKit

struct PhotoCard: View {
    let photo: Photo
    
    var body: some View {
        VStack {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            }
            
            VStack(alignment: .leading) {
                Text(photo.species ?? "Unknown Species")
                    .font(.headline)
                if let location = photo.location {
                    Text(location)
                        .font(.subheadline)
                }
                Text(photo.timestamp.formatted())
                    .font(.caption)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
} 