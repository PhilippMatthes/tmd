import XCTest

@testable import SHLModelEvaluation

class PreprocessingTests: DataTest {
    /// Test that the preprocessors were ported correctly.
    func testPreprocessors() throws {
        guard let datasets = datasets else { XCTFail(); return }

        let sensorPreprocessors = Dictionary(uniqueKeysWithValues: try Sensor.order.map { sensor throws -> (Sensor, [Preprocessor]) in
            let preprocessors: [Preprocessor] = [
                try PowerTransformer(configFileName: sensor.configFileName),
                try StandardScaler(configFileName: sensor.configFileName),
            ]
            return (sensor, preprocessors)
        })

        for sensor in Sensor.order {
            var maxDiff: Parameter = 0
            for sample in datasets.values.flatMap({ s in s }) {
                guard
                    let preprocessors = sensorPreprocessors[sensor]
                else { XCTFail(); return }

                let xFeatureSensor = sample.xFeature
                    .map { features in features[sensor.sampleIndex] }
                let xRawSensor = sample.xRaw
                    .map { features in features[sensor.sampleIndex] }
                var xPreprocessed = xRawSensor
                for preprocessor in preprocessors {
                    xPreprocessed = preprocessor.transform(xPreprocessed)
                }

                let xDiffs = Array((0..<500)).map { i in
                    xFeatureSensor[i] - xPreprocessed[i]
                }
                for diff in xDiffs {
                    maxDiff = max(diff, maxDiff)
                    XCTAssert(diff < 0.00001)
                }
            }
        }
    }
}
