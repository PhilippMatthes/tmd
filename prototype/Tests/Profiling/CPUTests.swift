import XCTest

@testable import SHLModelEvaluation

class CPUTests: XCTestCase {
    struct RunResult: CustomStringConvertible {
        let mean: Float
        let std: Float

        var description: String {
            "Mean: \(mean), Std: \(std)"
        }
    }

    @discardableResult private func run(classifier: Classifier, runs: Int) throws -> RunResult {
        var usages = [Float]()
        for _ in (0..<runs) {
            let randomInputs = Array((0..<500)).map { i -> [Parameter] in
                Array((0..<3)).map { _ -> Parameter in
                    Parameter.random(in: -1.0 ... 1.0)
                }
            }
            _ = try classifier.classify(input: randomInputs)
            usages.append(cpu_usage())
            let hz: UInt32 = 2
            usleep(1_000_000 / hz)
        }
        let mean = usages.reduce(0, +) / Float(usages.count)
        let v = usages.reduce(0, { $0 + ($1-mean)*($1-mean) })
        let std = sqrt(v / (Float(usages.count) - 1))

        return .init(mean: mean, std: std)
    }

    func testCPU() throws {
        for modelId in Models.all {
            let classifier = try Classifier(
                modelFileName: modelId,
                accelerator: .cpu,
                threads: 1
            )
            // Cold run
            try run(classifier: classifier, runs: 3)

            // Warm run
            let usage = try run(classifier: classifier, runs: 10)

            print("CPU - CPU Usage for \(modelId): \(usage)")
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
            try run(classifier: classifier, runs: 3)

            // Warm run
            let usage = try run(classifier: classifier, runs: 10)

            print("GPU - CPU Usage for \(modelId): \(usage)")
        }
    }

    /// Test the ANE.
    func testANE() throws {
        for modelId in Models.all {
            let classifier = try Classifier(
                modelFileName: modelId,
                accelerator: .ane,
                threads: 1
            )
            // Cold run
            try run(classifier: classifier, runs: 3)

            // Warm run
            let usage = try run(classifier: classifier, runs: 10)

            print("ANE - CPU Usage for \(modelId): \(usage)")
        }
    }
}

