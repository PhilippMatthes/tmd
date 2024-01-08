import XCTest

@testable import SHLModelEvaluation

class InferenceTests: XCTestCase {
    /// Test the inference time of the TFLite model.
    private func runInference(classifier: Classifier, runs: Int = 100) throws {
        for _ in (0..<runs) {
            let randomInputs = Array((0..<500)).map { i -> [Parameter] in
                Array((0..<3)).map { _ -> Parameter in
                    Parameter.random(in: -1.0 ... 1.0)
                }
            }
            _ = try classifier.classify(input: randomInputs)
        }
    }

    private func profile(_ block: () throws -> Void) rethrows -> TimeInterval {
        let start = DispatchTime.now()
        try block()
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        return timeInterval
    }

    func testCPU() throws {
        for modelId in Models.all {
            let classifier = try Classifier(
                modelFileName: modelId,
                accelerator: .cpu,
                threads: 1
            )
            // Cold run
            try runInference(classifier: classifier, runs: 10)

            // Warm run
            let seconds = try profile {
                try runInference(classifier: classifier, runs: 100)
            }

            print("CPU Time for \(modelId) in ms: \((seconds / 100) * 1000)")
        }
    }

    func testGPU() throws {
        for modelId in Models.all {
            let classifier = try Classifier(
                modelFileName: modelId,
                accelerator: .gpu,
                threads: 1
            )
            // Cold run
            try runInference(classifier: classifier, runs: 10)

            // Warm run
            let seconds = try profile {
                try runInference(classifier: classifier, runs: 100)
            }

            print("GPU Time for \(modelId) in ms: \((seconds / 100) * 1000)")
        }
    }

    func testANE() throws {
        for modelId in Models.all {
            guard let classifier = try? Classifier(
                modelFileName: modelId,
                accelerator: .ane,
                threads: 1
            ) else { return }
            // Cold run
            try runInference(classifier: classifier, runs: 10)

            // Warm run
            let seconds = try profile {
                try runInference(classifier: classifier, runs: 100)
            }

            print("ANE Time for \(modelId) in ms: \((seconds / 100) * 1000)")
        }
    }
}
