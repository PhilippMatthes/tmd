import XCTest

@testable import SHLModelEvaluation

class ModelTests: DataTest {
    /// Test that the model predictions.
    func testModel() throws {
        guard let datasets = datasets else { XCTFail(); return }

        let model = try Classifier(modelFileName: "model")

        var correctPredictions = 0
        var incorrectPredictions = 0
        for sample in datasets.values.flatMap({ s in s }) {
            let yPreds = try model.classify(input: sample.xFeature)
            let yPred = yPreds.first!.label
            let yTrue = sample.y
            let isCorrect = yTrue == yPred
            if isCorrect {
                correctPredictions += 1
            } else {
                incorrectPredictions += 1
            }
        }
        let allPredictions = correctPredictions + incorrectPredictions
        let accuracy = Float(correctPredictions) / Float(allPredictions)
        XCTAssert(accuracy > 0.80)
    }
}
