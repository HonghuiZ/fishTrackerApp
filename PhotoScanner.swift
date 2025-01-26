import Photos
import Vision
import SwiftUI
import CoreImage
import CryptoKit

@MainActor
class PhotoScanner: ObservableObject {
    @Published var scanningProgress: Double = 0
    @Published var isScanning = false
    @Published var foundFishPhotos: [Photo] = []
    
    // Cache for photo hashes to prevent exact duplicates
    private var photoHashes: Set<String> = []
    // Cache for perceptual hashes to detect similar images
    private var perceptualHashes: [(hash: String, photoId: UUID)] = []
    
    // Threshold for considering images similar (0-256, lower means more strict)
    private let similarityThreshold = 10
    
    func requestPhotoPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .notDetermined {
            let granted = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return granted == .authorized
        }
        
        return status == .authorized
    }
    
    func scanAllPhotos() async {
        guard await requestPhotoPermission() else {
            print("Photo permission denied")
            return
        }
        
        isScanning = true
        photoHashes.removeAll()
        perceptualHashes.removeAll()
        
        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let totalPhotos = allPhotos.count
        var processedCount = 0
        
        let config = MLModelConfiguration()
        guard (try? VNCoreMLModel(for: Resnet50(configuration: config).model)) != nil else { return }
        
        for i in 0..<totalPhotos {
            let asset = allPhotos.object(at: i)
            
            let manager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: asset,
                               targetSize: PHImageManagerMaximumSize,
                               contentMode: .aspectFit,
                               options: requestOptions) { image, info in
                if let image = image {
                    Task { @MainActor in
                        let (isFish, species) = await FishDetectionService.shared.detectFish(in: image)
                        if isFish {
                            if let imageData = image.jpegData(compressionQuality: 1.0) {
                                let exactHash = self.generateHash(from: imageData)
                                
                                if !self.photoHashes.contains(exactHash) {
                                    if let pHash = ImageHasher.shared.calculatePerceptualHash(from: image) {
                                        let isTooSimilar = self.perceptualHashes.contains { existing in
                                            let distance = ImageHasher.shared.hammingDistance(pHash, existing.hash)
                                            return distance <= self.similarityThreshold
                                        }
                                        
                                        if !isTooSimilar {
                                            self.photoHashes.insert(exactHash)
                                            
                                            let location = await self.getPhotoLocation(from: asset)
                                            let newPhoto = Photo(
                                                imageData: imageData,
                                                timestamp: asset.creationDate ?? Date(),
                                                location: location,
                                                species: species
                                            )
                                            
                                            self.foundFishPhotos.append(newPhoto)
                                            self.perceptualHashes.append((hash: pHash, photoId: newPhoto.id))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            processedCount += 1
            scanningProgress = Double(processedCount) / Double(totalPhotos)
        }
        
        isScanning = false
    }
    
    private func generateHash(from data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func getPhotoLocation(from asset: PHAsset) async -> String {
        if let location = asset.location {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    let locationParts = [
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }
                    
                    return locationParts.joined(separator: ", ")
                }
            } catch {
                print("Geocoding error: \(error)")
            }
        }
        return "Unknown Location"
    }
}

struct ScanningView: View {
    @ObservedObject var scanner: PhotoScanner
    @Binding var isFirstLaunch: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if scanner.isScanning {
                ProgressView("Scanning Photos", value: scanner.scanningProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .padding()
                
                Text("\(Int(scanner.scanningProgress * 100))%")
                    .font(.headline)
                
                Text("Found \(scanner.foundFishPhotos.count) fish photos")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Initial scan complete!")
                    .font(.headline)
                
                Text("Found \(scanner.foundFishPhotos.count) fish photos")
                    .font(.subheadline)
                
                Button("Continue") {
                    isFirstLaunch = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            Task {
                await scanner.scanAllPhotos()
            }
        }
    }
} 
