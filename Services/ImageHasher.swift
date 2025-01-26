#if os(iOS)
import UIKit
#else
import AppKit
#endif
import CoreImage

class ImageHasher {
    static let shared = ImageHasher()
    private let size = 16  // Size to resize images to before hashing
    
    private init() {}
    
    #if os(iOS)
    func calculatePerceptualHash(from image: UIImage) -> String? {
        print("\n🔨 Generating Perceptual Hash")
        
        // Convert UIImage to CGImage
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage from UIImage")
            return nil
        }
        print("✅ Got CGImage")
        
        // Create CIImage
        let ciImage = CIImage(cgImage: cgImage)
        print("✅ Created CIImage")
        
        // Resize to 8x8
        let resizeFilter = CIFilter(name: "CILanczosScaleTransform")
        resizeFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        let scale = 8.0 / max(ciImage.extent.width, ciImage.extent.height)
        resizeFilter?.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter?.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let resizedImage = resizeFilter?.outputImage else {
            print("❌ Failed to resize image")
            return nil
        }
        print("✅ Resized image to 8x8")
        
        // Convert to grayscale
        let grayFilter = CIFilter(name: "CIPhotoEffectNoir")
        grayFilter?.setValue(resizedImage, forKey: kCIInputImageKey)
        
        guard let grayscaleImage = grayFilter?.outputImage else {
            print("❌ Failed to convert to grayscale")
            return nil
        }
        print("✅ Converted to grayscale")
        
        // Create context and render
        let context = CIContext(options: nil)
        guard let renderedImage = context.createCGImage(grayscaleImage, from: grayscaleImage.extent) else {
            print("❌ Failed to render image")
            return nil
        }
        print("✅ Rendered image")
        
        // Calculate average brightness
        var total: Int = 0
        var pixels: [Int] = []
        
        let width = renderedImage.width
        let height = renderedImage.height
        let bytesPerRow = width * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: bitmapInfo) else {
            print("❌ Failed to create context for pixel data")
            return nil
        }
        print("✅ Created context for pixel data")
        
        context.draw(renderedImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelData = context.data else {
            print("❌ Failed to get pixel data")
            return nil
        }
        print("✅ Got pixel data")
        
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        for row in 0..<height {
            for col in 0..<width {
                let offset = row * bytesPerRow + col * 4
                let brightness = Int(data[offset])
                total += brightness
                pixels.append(brightness)
            }
        }
        
        let average = total / (width * height)
        print("✅ Calculated average brightness: \(average)")
        
        // Generate hash
        var hash = ""
        for pixel in pixels {
            hash += pixel > average ? "1" : "0"
        }
        
        print("✅ Generated hash: \(hash)")
        return hash
    }
    #else
    func calculatePerceptualHash(from image: NSImage) -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        return calculateHash(from: ciImage)
    }
    #endif
    
    private func calculateHash(from ciImage: CIImage) -> String? {
        // Basic implementation - you can enhance this later
        return String(ciImage.hashValue)
    }
    
    private func getGrayscalePixels(from image: UIImage) -> [Double]? {
        guard let cgImage = image.cgImage else { return nil }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply grayscale filter
        guard let grayscale = CIFilter(name: "CIPhotoEffectNoir")?.apply(to: ciImage, context: context),
              let resized = grayscale.resize(to: CGSize(width: size, height: size), context: context) else {
            return nil
        }
        
        var bitmap = [Double](repeating: 0, count: size * size)
        
        guard let cgImage = context.createCGImage(resized, from: resized.extent) else {
            return nil
        }
        
        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return nil
        }
        
        let bytesPerRow = cgImage.bytesPerRow
        let bitsPerPixel = cgImage.bitsPerPixel
        
        for y in 0..<size {
            for x in 0..<size {
                let offset = (y * bytesPerRow) + (x * bitsPerPixel / 8)
                bitmap[y * size + x] = Double(bytes[offset])
            }
        }
        
        return bitmap
    }
    
    func hammingDistance(_ hash1: String, _ hash2: String) -> Int? {
        guard hash1.count == hash2.count else {
            print("❌ Hash lengths don't match: \(hash1.count) vs \(hash2.count)")
            return nil
        }
        
        let distance = zip(hash1, hash2).filter { $0 != $1 }.count
        print("✅ Calculated Hamming distance: \(distance)")
        return distance
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    private func convertToGrayScale(_ image: UIImage) -> UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir"),
              let beginImage = CIImage(image: image),
              let output = currentFilter.outputImage else {
            return nil
        }
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        if let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
}

// Extension to help with image processing
extension CIImage {
    func resize(to size: CGSize, context: CIContext) -> CIImage? {
        let scale = min(size.width / extent.width, size.height / extent.height)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let resized = transformed(by: transform)
        
        return resized
    }
}

extension CIFilter {
    func apply(to input: CIImage, context: CIContext) -> CIImage? {
        setValue(input, forKey: kCIInputImageKey)
        return outputImage
    }
} 