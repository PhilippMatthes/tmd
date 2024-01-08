import XCTest

@testable import SHLModelEvaluation

struct TestSample: Codable {
    let xFeature: [[Parameter]]
    let xRaw: [[Parameter]]
    let y: Classifier.Class

    private enum CodingKeys: String, CodingKey {
        case xFeature = "X_feature"
        case xRaw = "X_raw"
        case y = "y"
    }
}

class DataTest: XCTestCase {
    var datasets: [String: [TestSample]]?

    override func setUp() {
        super.setUp()
        guard
            let testSampleUrl = Bundle.main.url(
                forResource: "testdata", withExtension: "json"
            ),
            let data = try? Data(
                contentsOf: testSampleUrl, options: .mappedIfSafe
            ),
            let datasets = try? JSONDecoder().decode(
                [String: [TestSample]].self, from: data
            )
        else { XCTFail(); return }
        XCTAssert(!datasets.isEmpty)
        self.datasets = datasets
    }
}
