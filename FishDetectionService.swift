import Vision
import UIKit

class FishDetectionService {
    static let shared = FishDetectionService()
    
    // First layer: Generic fish detection
    private let genericFishKeywords = [
        "fish", "aquatic", "marine", "freshwater", "seafood",
        "swimmer", "scales", "fins", "gills", "underwater"
    ]
    
    // Second layer: Specific species classification
    private let fishSpecies = [
        // Bass family
        "largemouth bass": ["largemouth bass", "black bass", "large mouth", "large-mouth"],
        "smallmouth bass": ["smallmouth bass", "small mouth", "small-mouth"],
        "striped bass": ["striped bass", "striper", "rockfish"],
        
        // Panfish
        "crappie": ["crappie", "black crappie", "white crappie", "papermouth"],
        "yellow perch": ["yellow perch", "perch", "lake perch"],
        
        // Other freshwater
        "walleye": ["walleye", "pike perch", "pike-perch"],
        "carp": ["carp", "common carp"],
        
        // Salmon and Trout
        "rainbow trout": ["rainbow trout", "steelhead"],
        "brown trout": ["brown trout", "german brown"],
        "brook trout": ["brook trout", "speckled trout", "brookie"],
        "lake trout": ["lake trout", "mackinaw", "laker"],
        "salmon": ["salmon", "king salmon", "chinook", "coho", "silver salmon", 
                  "sockeye", "red salmon", "pink salmon", "chum", "atlantic salmon"]
    ]
    
    func detectFish(in image: UIImage) async -> (isFish: Bool, species: String) {
        guard let ciImage = CIImage(image: image) else { return (false, "") }
        
        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: Resnet50(configuration: MLModelConfiguration()).model)) { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: (false, ""))
                    return
                }
                
                print("\n--- Detection Results ---")
                for (index, result) in results.prefix(10).enumerated() {
                    print("\(index + 1). \(result.identifier): \(Int(result.confidence * 100))%")
                }
                print("----------------------")
                
                // First layer: Generic fish detection
                let topPredictions = results.prefix(5)
                let isFish = topPredictions.contains { result in
                    let prediction = result.identifier.lowercased()
                    return self.genericFishKeywords.contains { prediction.contains($0) }
                }
                
                guard isFish else {
                    print("❌ No fish detected in image")
                    continuation.resume(returning: (false, ""))
                    return
                }
                
                print("✅ Fish detected, analyzing species...")
                
                // Second layer: Specific species identification
                for result in topPredictions {
                    let prediction = result.identifier.lowercased()
                    for (species, keywords) in self.fishSpecies {
                        if keywords.contains(where: { prediction.contains($0) }) {
                            print("🎯 Species identified: \(species)")
                            continuation.resume(returning: (true, species.capitalized))
                            return
                        }
                    }
                }
                
                // Fish detected but species not identified
                print("⚠️ Fish detected but species not identified")
                continuation.resume(returning: (true, "Unknown Fish Species"))
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try? handler.perform([request])
        }
    }
} 