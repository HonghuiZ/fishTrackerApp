import SwiftUI
import CoreLocation
import ImageIO

@MainActor
class PhotoProcessor {
    static let shared = PhotoProcessor()
    private let deduplicationService = PhotoDeduplicationService.shared
    
    private init() {}
    
    struct ProcessedPhoto {
        let fileName: String
        let location: String
        let timestamp: Date
        let hash: String
        let pHash: String
        let species: String
        let latitude: Double?
        let longitude: Double?
    }
    
    func processPhoto(imageData: Data, location: String? = nil, species: String? = nil, timestamp: Date? = nil, photoStore: PhotoStore) async -> ProcessedPhoto? {
        print("\n=== Processing Photo ===")
        
        // Check for duplicates
        let deduplicationResult = deduplicationService.checkForDuplicates(
            imageData: imageData,
            against: photoStore.loadMetadata()
        )
        
        if deduplicationResult.isDuplicate {
            print("❌ Duplicate photo detected")
            return nil
        }
        
        // Extract metadata
        let (extractedDate, lat, lon) = extractMetadata(from: imageData)
        let photoDate = timestamp ?? extractedDate ?? Date()
        
        // Try to get coordinates from location string if GPS metadata failed
        let (finalLat, finalLon) = await resolveCoordinates(
            lat: lat,
            lon: lon,
            locationString: location ?? ""
        )
        
        // Generate unique filename
        let fileName = UUID().uuidString + ".jpg"
        
        // Save the file
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try imageData.write(to: fileURL)
            print("✅ Saved file: \(fileName)")
        } catch {
            print("❌ Failed to save file: \(error)")
            return nil
        }
        
        return ProcessedPhoto(
            fileName: fileName,
            location: location ?? "Unknown Location",
            timestamp: photoDate,
            hash: deduplicationResult.exactHash,
            pHash: deduplicationResult.pHash,
            species: species ?? "Unknown Fish Species",
            latitude: finalLat,
            longitude: finalLon
        )
    }
    
    private func extractMetadata(from imageData: Data) -> (date: Date?, latitude: Double?, longitude: Double?) {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("❌ Failed to extract metadata from image")
            return (nil, nil, nil)
        }
        
        print("\n=== 📝 Image Metadata ===")
        print("Available metadata keys: \(metadata.keys.joined(separator: ", "))")
        
        var photoDate: Date?
        
        // Try EXIF date first
        if let exif = metadata["{Exif}"] as? [String: Any] {
            print("\nEXIF Data:")
            exif.forEach { key, value in
                print("  \(key): \(value)")
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            
            // Try all possible EXIF date fields
            let dateFields = [
                "DateTimeOriginal",
                "DateTimeDigitized",
                "DateTime",
                "CreationDate",
                "ModificationDate"
            ]
            
            for dateField in dateFields {
                if let dateString = exif[dateField] as? String {
                    print("\nTrying EXIF \(dateField): \(dateString)")
                    if let date = formatter.date(from: dateString) {
                        photoDate = date
                        print("✅ Successfully parsed EXIF date from \(dateField): \(date)")
                        break
                    } else {
                        print("❌ Failed to parse EXIF date from \(dateField)")
                    }
                }
            }
        } else {
            print("❌ No EXIF data found")
        }
        
        // Try TIFF date if no EXIF date
        if photoDate == nil {
            if let tiff = metadata["{TIFF}"] as? [String: Any] {
                print("\nTIFF Data:")
                tiff.forEach { key, value in
                    print("  \(key): \(value)")
                }
                
                if let dateString = tiff["DateTime"] as? String {
                    print("\nTrying TIFF DateTime: \(dateString)")
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                    if let date = formatter.date(from: dateString) {
                        photoDate = date
                        print("✅ Successfully parsed TIFF date: \(date)")
                    } else {
                        print("❌ Failed to parse TIFF DateTime")
                    }
                }
            } else {
                print("❌ No TIFF data found")
            }
        }
        
        if photoDate == nil {
            print("⚠️ No date found in metadata")
        }
        
        // Extract GPS data
        let (lat, lon) = extractGPSData(from: metadata)
        
        print("=== End Metadata ===\n")
        return (photoDate, lat, lon)
    }
    
    private func extractGPSData(from metadata: [String: Any]) -> (latitude: Double?, longitude: Double?) {
        guard let gps = metadata["{GPS}"] as? [String: Any] else {
            return (nil, nil)
        }
        
        var lat: Double?
        var lon: Double?
        
        // Try first GPS format
        if let latitude = gps["Latitude"] as? Double,
           let longitude = gps["Longitude"] as? Double,
           let latRef = gps["LatitudeRef"] as? String,
           let longRef = gps["LongitudeRef"] as? String {
            
            lat = latRef == "N" ? latitude : -latitude
            lon = longRef == "E" ? longitude : -longitude
        }
        // Try alternative format (DMS)
        else if let latitudeArray = gps["Latitude"] as? [Double],
                let longitudeArray = gps["Longitude"] as? [Double],
                let latRef = gps["LatitudeRef"] as? String,
                let longRef = gps["LongitudeRef"] as? String {
            
            let latitude = latitudeArray[0] + (latitudeArray[1] / 60.0) + (latitudeArray[2] / 3600.0)
            let longitude = longitudeArray[0] + (longitudeArray[1] / 60.0) + (longitudeArray[2] / 3600.0)
            
            lat = latRef == "N" ? latitude : -latitude
            lon = longRef == "E" ? longitude : -longitude
        }
        
        return (lat, lon)
    }
    
    private func resolveCoordinates(lat: Double?, lon: Double?, locationString: String) async -> (Double?, Double?) {
        // If we already have coordinates, return them
        if let lat = lat, let lon = lon {
            return (lat, lon)
        }
        
        // Try to get coordinates from location string
        if !locationString.isEmpty {
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.geocodeAddressString(locationString).first {
                return (
                    placemark.location?.coordinate.latitude,
                    placemark.location?.coordinate.longitude
                )
            }
        }
        
        return (nil, nil)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 