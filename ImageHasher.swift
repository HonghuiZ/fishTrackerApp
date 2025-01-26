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
        guard let resizedImage = resizeImage(image, to: CGSize(width: 8, height: 8)),
              let grayScale = convertToGrayScale(resizedImage),
              let pixelData = grayScale.cgImage?.dataProvider?.data,
              let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        
        var pixels: [UInt8] = []
        for i in 0..<64 {
            pixels.append(data[i])
        }
        
        let average = pixels.reduce(0, +) / 64
        
        var hash = ""
        for pixel in pixels {
            hash += pixel > average ? "1" : "0"
        }
        
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
    
    func hammingDistance(_ hash1: String, _ hash2: String) -> Int {
        guard hash1.count == hash2.count else { return Int.max }
        
        return zip(hash1, hash2).filter { $0 != $1 }.count
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