import SwiftUI
import PhotosUI
import Photos
import Vision
import CoreImage
import CoreLocation
import UIKit


struct PhotoUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var photoStore: PhotoStore
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedAsset: PHAsset?
    @State private var location = ""
    @State private var isFishDetected = false
    @State private var detectedSpecies = ""
    @State private var manuallyConfirmedFish = false
    @State private var showingDuplicateAlert = false
    @State private var duplicatePhoto: PhotoMetadata?
    
    // Add the similarity threshold constant
    private let similarityThreshold: Int = 10
    
    var body: some View {
        VStack {
            if let imageData = selectedImageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Label("Select Photo", systemImage: "photo.on.rectangle")
                    .font(.headline)
            }
            .padding()
            
            if isFishDetected || manuallyConfirmedFish {
                Text("✅ Fish \(isFishDetected ? "detected" : "confirmed"): \(detectedSpecies)")
                    .foregroundColor(.green)
                    .font(.headline)
                
                if !location.isEmpty {
                    Text("📍 \(location)")
                        .font(.subheadline)
                }
            }
            
            if !isFishDetected {
                Button("Confirm as Fish") {
                    manuallyConfirmedFish = true
                }
                .disabled(selectedImageData == nil)
            }
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    print("Saving photo...")
                    savePhoto()
                    print("Photo saved, dismissing...")
                    dismiss()
                }
                .disabled(!isFishDetected && !manuallyConfirmedFish)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onChange(of: selectedItem) { _ in
            Task {
                do {
                    guard let item = selectedItem else { 
                        print("No item selected")
                        return 
                    }
                    
                    // Load image data
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        print("Failed to load image data")
                        return
                    }
                    
                    // Check for duplicates before processing
                    if let duplicate = checkForDuplicates(imageData: data) {
                        print("\n=== Duplicate Check ===")
                        print("Found similar photo:")
                        print("- Date: \(duplicate.timestamp.formatted())")
                        print("- Location: \(duplicate.location)")
                        print("- Species: \(duplicate.species)")
                        
                        await MainActor.run {
                            duplicatePhoto = duplicate
                            showingDuplicateAlert = true
                            selectedItem = nil
                        }
                        return
                    }
                    
                    // If no duplicate, proceed with normal processing
                    await MainActor.run {
                        selectedImageData = data
                    }
                    
                    // Try to get metadata directly from the image data
                    if let source = CGImageSourceCreateWithData(data as CFData, nil),
                       let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                        print("\n📝 Image Metadata:")
                        
                        // EXIF data
                        if let exif = metadata["{Exif}"] as? [String: Any] {
                            print("\nEXIF Data:")
                            for (key, value) in exif {
                                print("  \(key): \(value)")
                            }
                            
                            // Try to get date
                            if let dateTimeOriginal = exif["DateTimeOriginal"] as? String {
                                print("📅 Original Date: \(dateTimeOriginal)")
                            }
                        }
                        
                        // GPS data
                        if let gps = metadata["{GPS}"] as? [String: Any] {
                            print("\nGPS Data:")
                            for (key, value) in gps {
                                print("  \(key): \(value)")
                            }
                            
                            // Try to get coordinates
                            if let latitude = gps["Latitude"] as? Double,
                               let longitude = gps["Longitude"] as? Double,
                               let latRef = gps["LatitudeRef"] as? String,
                               let longRef = gps["LongitudeRef"] as? String {
                                
                                let lat = latRef == "N" ? latitude : -latitude
                                let lon = longRef == "E" ? longitude : -longitude
                                
                                print("📍 Coordinates: \(lat), \(lon)")
                                
                                // Get location name
                                let location = CLLocation(latitude: lat, longitude: lon)
                                let geocoder = CLGeocoder()
                                if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                                    let locationString = [
                                        placemark.locality,
                                        placemark.administrativeArea,
                                        placemark.country
                                    ].compactMap { $0 }.joined(separator: ", ")
                                    print("📍 Location name: \(locationString)")
                                    self.location = locationString
                                }
                            }
                        }
                    } else {
                        print("❌ No metadata found in image")
                    }
                    
                    // Start fish detection
                    if let image = UIImage(data: data) {
                        print("\n🐟 Starting fish detection...")
                        await detectFish(in: image)
                    }
                } catch {
                    print("Error loading photo: \(error)")
                }
            }
        }
        .alert("Similar Photo Found", isPresented: $showingDuplicateAlert) {
            Button("Continue Anyway") {
                // Re-process the photo if user wants to continue
                if let data = selectedImageData {
                    Task {
                        await MainActor.run {
                            selectedImageData = data
                        }
                        if let image = UIImage(data: data) {
                            await detectFish(in: image)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                selectedItem = nil
                selectedImageData = nil
            }
        } message: {
            if let duplicate = duplicatePhoto {
                Text("A similar photo was taken on \(duplicate.timestamp.formatted())" + 
                     (duplicate.location.isEmpty ? "" : " at \(duplicate.location)") +
                     ". Do you still want to add this photo?")
            }
        }
    }

    private func detectFish(in image: UIImage) async {
        print("\n--- Detection Results ---")
        let result = await FishDetectionService.shared.detectFish(in: image)
        
        print("Detection result:")
        print("- Is Fish: \(result.isFish)")
        print("- Species: \(result.species)")
        print("----------------------")
        
        isFishDetected = result.isFish
        if isFishDetected {
            print("✅ Fish detected, analyzing species...")
            detectedSpecies = result.species
            print("🎯 Species identified: \(detectedSpecies)")
        } else {
            print("❌ No fish detected")
        }
    }

    private func savePhoto() {
        guard let imageData = selectedImageData else {
            print("Missing image data")
            return
        }
        
        print("\n=== Saving Photo ===")
        print("Image data size: \(imageData.count) bytes")
        
        // Get coordinates from metadata
        var lat: Double?
        var lon: Double?
        var photoDate = Date() // Default to current date if we can't find original
        
        if let source = CGImageSourceCreateWithData(imageData as CFData, nil),
           let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
            
            // Try to get original date from EXIF
            if let exif = metadata["{Exif}"] as? [String: Any] {
                if let dateTimeOriginal = exif["DateTimeOriginal"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                    if let originalDate = formatter.date(from: dateTimeOriginal) {
                        photoDate = originalDate
                        print("📅 Using original photo date: \(photoDate)")
                    }
                }
            }
            
            print("\nChecking GPS Data:")
            if let gps = metadata["{GPS}"] as? [String: Any] {
                print("Found GPS metadata:")
                for (key, value) in gps {
                    print("  \(key): \(value)")
                }
                
                // Try different GPS formats
                if let latitude = gps["Latitude"] as? Double,
                   let longitude = gps["Longitude"] as? Double,
                   let latRef = gps["LatitudeRef"] as? String,
                   let longRef = gps["LongitudeRef"] as? String {
                    
                    lat = latRef == "N" ? latitude : -latitude
                    lon = longRef == "E" ? longitude : -longitude
                    print("📍 Format 1 - Coordinates found: \(lat ?? 0), \(lon ?? 0)")
                }
                // Try alternative format
                else if let latitudeArray = gps["Latitude"] as? [Double],
                        let longitudeArray = gps["Longitude"] as? [Double],
                        let latRef = gps["LatitudeRef"] as? String,
                        let longRef = gps["LongitudeRef"] as? String {
                    
                    // Convert DMS (Degrees, Minutes, Seconds) to decimal degrees
                    let latitude = latitudeArray[0] + (latitudeArray[1] / 60.0) + (latitudeArray[2] / 3600.0)
                    let longitude = longitudeArray[0] + (longitudeArray[1] / 60.0) + (longitudeArray[2] / 3600.0)
                    
                    lat = latRef == "N" ? latitude : -latitude
                    lon = longRef == "E" ? longitude : -longitude
                    print("📍 Format 2 - Coordinates found: \(lat ?? 0), \(lon ?? 0)")
                }
            } else {
                print("No GPS data found in metadata")
            }
        }
        
        // Try getting coordinates from location string if GPS metadata failed
        if lat == nil || lon == nil {
            print("\nTrying to get coordinates from location string...")
            let geocoder = CLGeocoder()
            let semaphore = DispatchSemaphore(value: 0)
            
            geocoder.geocodeAddressString(location) { placemarks, error in
                if let location = placemarks?.first?.location {
                    lat = location.coordinate.latitude
                    lon = location.coordinate.longitude
                    print("📍 Got coordinates from location string: \(lat ?? 0), \(lon ?? 0)")
                } else {
                    print("Could not get coordinates from location string")
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 5)
        }
        
        // Save image file
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            print("\nSaving photo metadata:")
            print("- Location string: \(location)")
            print("- Final coordinates: \(String(describing: lat)), \(String(describing: lon))")
            
            let newPhoto = PhotoMetadata(
                id: UUID(),
                fileName: fileName,
                location: location,
                timestamp: photoDate,
                hash: generateHash(from: imageData),
                pHash: ImageHasher.shared.calculatePerceptualHash(from: UIImage(data: imageData) ?? UIImage()) ?? "",
                species: detectedSpecies,
                latitude: lat,
                longitude: lon
            )
            
            // Save metadata
            var savedPhotos = photoStore.loadMetadata()
            savedPhotos.append(newPhoto)
            photoStore.saveMetadata(savedPhotos)
            
            print("\nSave completed:")
            print("- Total photos: \(savedPhotos.count)")
            print("- File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
            print("==================\n")
            
            dismiss()
        } catch {
            print("Error saving photo: \(error)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func generateHash(from data: Data) -> String {
        var hasher = Hasher()
        hasher.combine(data)
        return String(hasher.finalize())
    }

    private func getPhotoLocation(from asset: PHAsset) async -> String {
        return await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            
            if let location = asset.location {
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        var locationParts: [String] = []
                        
                        if let name = placemark.name {
                            locationParts.append(name)
                        }
                        if let locality = placemark.locality {
                            locationParts.append(locality)
                        }
                        if let state = placemark.administrativeArea {
                            locationParts.append(state)
                        }
                        
                        let locationString = locationParts.joined(separator: ", ")
                        continuation.resume(returning: locationString)
                    } else {
                        continuation.resume(returning: "Location Unknown")
                    }
                }
            } else {
                continuation.resume(returning: "")
            }
        }
    }

    private func checkPhotoMetadata(asset: PHAsset) {
        print("\n=== Photo Metadata ===")
        print("Basic Info:")
        print("- Creation Date: \(String(describing: asset.creationDate))")
        print("- Modified Date: \(String(describing: asset.modificationDate))")
        print("- Media Type: \(asset.mediaType.rawValue)")
        print("- Duration: \(asset.duration)")
        print("- Pixel Width: \(asset.pixelWidth)")
        print("- Pixel Height: \(asset.pixelHeight)")
        
        print("\nLocation Info:")
        if let location = asset.location {
            print("- Latitude: \(location.coordinate.latitude)")
            print("- Longitude: \(location.coordinate.longitude)")
            print("- Altitude: \(location.altitude)")
            print("- Speed: \(location.speed)")
            print("- Course: \(location.course)")
            print("- Timestamp: \(location.timestamp)")
        } else {
            print("No location data available")
        }
        
        // Get detailed metadata
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        
        asset.requestContentEditingInput(with: options) { input, info in
            guard let input = input,
                  let url = input.fullSizeImageURL else { return }
            
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                print("\nDetailed Metadata:")
                print("=== EXIF Data ===")
                if let exif = metadata["{Exif}"] as? [String: Any] {
                    for (key, value) in exif {
                        print("- \(key): \(value)")
                    }
                }
                
                print("\n=== GPS Data ===")
                if let gps = metadata["{GPS}"] as? [String: Any] {
                    for (key, value) in gps {
                        print("- \(key): \(value)")
                    }
                }
                
                print("\n=== TIFF Data ===")
                if let tiff = metadata["{TIFF}"] as? [String: Any] {
                    for (key, value) in tiff {
                        print("- \(key): \(value)")
                    }
                }
                
                print("\n=== Other Metadata ===")
                for (key, value) in metadata {
                    if !key.contains("{GPS}") && !key.contains("{Exif}") && !key.contains("{TIFF}") {
                        print("- \(key): \(value)")
                    }
                }
            }
        }
        print("=====================\n")
    }

    private func checkForDuplicates(imageData: Data) -> PhotoMetadata? {
        print("\n=== 🔍 Checking for Duplicates ===")
        
        guard let newImage = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from data")
            print("- Data size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
            return nil
        }
        
        print("✅ Created UIImage:")
        print("- Size: \(newImage.size)")
        print("- Scale: \(newImage.scale)")
        print("- Orientation: \(newImage.imageOrientation.rawValue)")
        
        guard let newHash = ImageHasher.shared.calculatePerceptualHash(from: newImage) else {
            print("❌ Failed to generate perceptual hash")
            print("- Image size: \(newImage.size)")
            print("- Image scale: \(newImage.scale)")
            print("- Image orientation: \(newImage.imageOrientation.rawValue)")
            return nil
        }
        
        print("📊 New image details:")
        print("- 📦 Size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
        print("- 🔑 Perceptual hash: \(newHash)")
        
        let savedPhotos = photoStore.loadMetadata()
        print("📚 Checking against \(savedPhotos.count) existing photos")
        
        // First check exact hash
        let exactHash = generateHash(from: imageData)
        print("\n🔍 Checking for exact matches:")
        print("- 🔑 Exact hash: \(exactHash)")
        
        if let exactMatch = savedPhotos.first(where: { $0.hash == exactHash }) {
            print("‼️ Found exact duplicate:")
            print("- 📅 Date: \(exactMatch.timestamp.formatted())")
            print("- 📍 Location: \(exactMatch.location)")
            print("- 🐟 Species: \(exactMatch.species)")
            return exactMatch
        }
        
        // Then check perceptual hash for similar images
        print("\n🔍 Checking for similar images (threshold: \(similarityThreshold)):")
        
        for photo in savedPhotos {
            let distance = ImageHasher.shared.hammingDistance(newHash, photo.pHash) ?? Int.max
            print("- Comparing with photo from \(photo.timestamp.formatted()):")
            print("  - 🔑 Hash: \(photo.pHash)")
            print("  - 📊 Hamming distance: \(distance)")
            
            if distance <= similarityThreshold {
                print("\n‼️ Found similar photo:")
                print("- 📅 Date: \(photo.timestamp.formatted())")
                print("- 📍 Location: \(photo.location)")
                print("- 🐟 Species: \(photo.species)")
                print("- 📊 Similarity score: \(100 - (distance * 100 / 256))%")
                return photo
            }
        }
        
        print("\n✅ No duplicates found")
        print("==================\n")
        return nil
    }
}
