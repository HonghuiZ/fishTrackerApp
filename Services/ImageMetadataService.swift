import Foundation
import CoreImage
import ImageIO

class ImageMetadataService {
    static let shared = ImageMetadataService()
    
    private init() {}
    
    func extractMetadata(from imageData: Data) -> (date: Date?, latitude: Double?, longitude: Double?) {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("❌ Failed to extract metadata from image")
            return (nil, nil, nil)
        }
        
        print("\n=== 📝 Image Metadata ===")
        print("Available metadata keys: \(metadata.keys.joined(separator: ", "))")
        
        var photoDate: Date?
        var lat: Double?
        var lon: Double?
        
        // Try EXIF date first
        if let exif = metadata["{Exif}"] as? [String: Any] {
            print("\nEXIF Data:")
            for (key, value) in exif {
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
        }
        
        // Try TIFF date if no EXIF date
        if photoDate == nil {
            if let tiff = metadata["{TIFF}"] as? [String: Any] {
                print("\nTIFF Data:")
                for (key, value) in tiff {
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
            }
        }
        
        if photoDate == nil {
            print("⚠️ No date found in metadata")
        }
        
        // Extract GPS data
        if let gps = metadata["{GPS}"] as? [String: Any] {
            print("\nGPS Data:")
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
        }
        
        print("=== End Metadata ===\n")
        return (photoDate, lat, lon)
    }
} 