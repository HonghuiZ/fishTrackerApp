import Foundation
import CoreImage

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage
#endif

/// Service responsible for compressing images while maintaining acceptable quality
class ImageCompressor {
    /// Shared singleton instance
    static let shared = ImageCompressor()
    
    /// Maximum dimension (width or height) for compressed images
    private let maxDimension: CGFloat = 2048
    
    /// JPEG compression quality (0.0 to 1.0)
    private let compressionQuality: CGFloat = 0.7
    
    private init() {}
    
    /// Compresses an image by:
    /// 1. Resizing to a maximum dimension while maintaining aspect ratio
    /// 2. Applying JPEG compression
    /// - Parameter imageData: Original image data
    /// - Returns: Compressed image data, or original data if compression fails
    func compressImage(data: Data) -> Data {
        #if os(iOS)
        guard let image = PlatformImage(data: data) else { return data }
        
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return data
        }
        UIGraphicsEndImageContext()
        
        // Compress to JPEG
        guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return data
        }
        
        print("\n=== 📦 Image Compression ===")
        print("Original size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
        print("Original dimensions: \(Int(size.width))×\(Int(size.height))")
        print("New dimensions: \(Int(newSize.width))×\(Int(newSize.height))")
        print("Compressed size: \(ByteCountFormatter.string(fromByteCount: Int64(compressedData.count), countStyle: .file))")
        print("Compression ratio: \(String(format: "%.1f", Double(data.count) / Double(compressedData.count)))x")
        print("==================\n")
        
        return compressedData
        #else
        guard let image = PlatformImage(data: data) else { return data }
        
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let resizedImage = PlatformImage(size: newSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: CGRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        // Convert to JPEG data
        guard let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bitmapRep = NSBitmapImageRep(cgImage: cgImage),
              let compressedData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            return data
        }
        
        print("\n=== 📦 Image Compression ===")
        print("Original size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
        print("Original dimensions: \(Int(size.width))×\(Int(size.height))")
        print("New dimensions: \(Int(newSize.width))×\(Int(newSize.height))")
        print("Compressed size: \(ByteCountFormatter.string(fromByteCount: Int64(compressedData.count), countStyle: .file))")
        print("Compression ratio: \(String(format: "%.1f", Double(data.count) / Double(compressedData.count)))x")
        print("==================\n")
        
        return compressedData
        #endif
    }
} 