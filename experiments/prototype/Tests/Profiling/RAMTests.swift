import XCTest

@testable import SHLModelEvaluation

fileprivate func ramUsage() -> Double {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
    let _: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    let usedMb = Double(taskInfo.phys_footprint) / 1000000.0
    return usedMb
}

class RAMTests: XCTestCase {
    private func run(classifier: Classifier, runs: Int) throws {
        for _ in (0..<runs) {
            let randomInputs = Array((0..<500)).map { i -> [Parameter] in
                Array((0..<3)).map { _ -> Parameter in
                    Parameter.random(in: -1.0 ... 1.0)
                }
            }
            _ = try classifier.classify(input: randomInputs)
        }
    }

    func testCPU() throws {
        for modelId in Models.all {
            let classifier = try Classifier(
                modelFileName: modelId,
                accelerator: .cpu,
                threads: 1
            )
            // Run
            try run(classifier: classifier, runs: 3)
            let mb = ramUsage()

            print("CPU - RAM Usage for \(modelId): \(mb)")
        }
    }

    func testGPU() throws {
        for modelId in Models.all {
            let classifier = try Classifier(
                modelFileName: modelId,
                accelerator: .gpu,
                threads: 1
            )
            // Run
            try run(classifier: classifier, runs: 3)
            let mb = ramUsage()

            print("GPU - RAM Usage for \(modelId): \(mb)")
        }
    }

    func testANE() throws {
        for modelId in Models.all {
            guard let classifier = try? Classifier(
                modelFileName: modelId,
                accelerator: .ane,
                threads: 1
            ) else { return }
            // Run
            try run(classifier: classifier, runs: 3)
            let mb = ramUsage()

            print("ANE - RAM Usage for \(modelId): \(mb)")
        }
    }
}

