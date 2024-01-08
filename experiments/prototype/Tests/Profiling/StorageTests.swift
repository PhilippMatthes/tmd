import XCTest

@testable import SHLModelEvaluation

fileprivate extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
}

class StorageTests: XCTestCase {
    func testModelSizes() throws {
        for modelId in Models.all {
            guard
                let url = Bundle.main.url(forResource: modelId, withExtension: "tflite")
            else { XCTFail(); return }
            print("Size for model \(modelId) in MB: \(Double(url.fileSize) / 1_000_000)")
        }
    }
}
