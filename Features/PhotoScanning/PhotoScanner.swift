import Photos
import Vision
import SwiftUI
import CoreImage
import CryptoKit
import CoreLocation

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
            requestOptions.version = .original
            requestOptions.deliveryMode = .highQualityFormat
            
            // Request original image data to preserve metadata
            var imageData: Data?
            manager.requestImageDataAndOrientation(for: asset, options: requestOptions) { data, _, _, _ in
                imageData = data
            }
            
            guard let finalImageData = imageData else {
                print("❌ Failed to get original image data")
                continue
            }
            
            // Extract metadata using shared service
            let extractedMetadata = ImageMetadataService.shared.extractMetadata(from: finalImageData)
            let finalDate = extractedMetadata.date ?? asset.creationDate ?? asset.modificationDate ?? Date()
            
            // Create UIImage for fish detection
            if let image = UIImage(data: finalImageData) {
                let (isFish, species) = await FishDetectionService.shared.detectFish(in: image)
                if isFish {
                    let exactHash = self.generateHash(from: finalImageData)
                    
                    if !self.photoHashes.contains(exactHash) {
                        if let pHash = ImageHasher.shared.calculatePerceptualHash(from: image) {
                            let isTooSimilar = self.perceptualHashes.contains { existing in
                                if let distance = ImageHasher.shared.hammingDistance(pHash, existing.hash) {
                                    return distance <= self.similarityThreshold
                                }
                                return false
                            }
                            
                            if !isTooSimilar {
                                self.photoHashes.insert(exactHash)
                                
                                let location = await self.getPhotoLocation(from: asset)
                                let newPhoto = Photo(
                                    imageData: finalImageData,
                                    timestamp: finalDate,
                                    location: location,
                                    species: species
                                )
                                
                                self.foundFishPhotos.append(newPhoto)
                                self.perceptualHashes.append((hash: pHash, photoId: newPhoto.id))
                                
                                print("\n=== 📸 Processed Photo ===")
                                print("- Original Date: \(String(describing: extractedMetadata.date))")
                                print("- Asset Creation Date: \(String(describing: asset.creationDate))")
                                print("- Final Date Used: \(finalDate)")
                                print("- Location: \(location)")
                                print("- Species: \(species)")
                                print("==================\n")
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
