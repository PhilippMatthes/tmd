import Foundation
import TensorFlowLite

final class Classifier {
    /// An input of shape `(n_timesteps, n_features)`.
    typealias Input = [[Parameter]]

    private let delegate: Delegate?
    private let interpreter: Interpreter
    private let input: Tensor
    private var output: Tensor

    enum Accelerator: String, CustomStringConvertible {
        /// Use the CPU (no accelerator).
        case cpu = "CPU"
        /// Use the GPU for inference tasks, if available.
        case gpu = "GPU"
        /// Use the Apple Neural Engine for inference tasks, if available.
        case ane = "ANE"

        static let all: [Self] = [ .cpu, .gpu, .ane ]

        var description: String {
            switch self {
            case .cpu: return "CPU"
            case .gpu: return "GPU"
            case .ane: return "Apple Neural Engine"
            }
        }
    }

    enum Class: Int, CustomStringConvertible, Codable {
        case null = 0
        case still = 1
        case walking = 2
        case run = 3
        case bike = 4
        case car = 5
        case bus = 6
        case train = 7
        case subway = 8

        var description: String {
            switch self {
            case .null: return "Null"
            case .still: return "Still"
            case .walking: return "Walking"
            case .run: return "Run"
            case .bike: return "Bike"
            case .car: return "Car"
            case .bus: return "Bus"
            case .train: return "Train"
            case .subway: return "Subway"
            }
        }

        static let order: [Self] = [
            .null, .still, .walking, .run, .bike, .car, .bus, .train, .subway
        ]
    }

    struct Prediction {
        let confidence: Parameter
        let label: Class
    }

    enum ClassifierError: Error {
        case acceleratorUnvailable
        case modelNotFound
        case erroneousInputShape
    }

    init(modelFileName: String, accelerator: Accelerator = .gpu, threads: Int = 1) throws {
        guard let modelPath = Bundle.main.path(
            forResource: modelFileName, ofType: "tflite"
        ) else { throw ClassifierError.modelNotFound }

        switch accelerator {
        case .cpu:
            delegate = nil
        case .gpu:
            delegate = MetalDelegate()
            guard delegate != nil else { throw ClassifierError.acceleratorUnvailable }
        case .ane:
            delegate = CoreMLDelegate()
            guard delegate != nil else { throw ClassifierError.acceleratorUnvailable }
        }
        let delegates = delegate == nil ? nil : [delegate!]

        var opts = Interpreter.Options()
        opts.threadCount = threads

        interpreter = try Interpreter(
            modelPath: modelPath,
            options: opts,
            delegates: delegates
        )
        try interpreter.allocateTensors()
        input = try interpreter.input(at: 0)
        output = try interpreter.output(at: 0)
    }

    private func shape(input: Input) -> [Int]? {
        guard let firstElement = input.first else { return nil }
        return [input.count, firstElement.count]
    }

    func classify(input: Input) throws -> [Prediction] {
        guard
            shape(input: input) == [500, 3]
        else { throw ClassifierError.erroneousInputShape }

        let inputData = input
            .flatMap { arr in arr }
            .withUnsafeBufferPointer { ptr in Data(buffer: ptr) }

        try interpreter.copy(inputData, toInputAt: 0)
        try interpreter.invoke()
        output = try interpreter.output(at: 0)

        let encodedResults = output.data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Parameter>(
                start: $0, count: output.data.count/MemoryLayout<Parameter>.stride
            ))
        }

        return encodedResults.enumerated()
            .map { i, p in .init(confidence: p, label: Class.order[i]) }
            .sorted { r1, r2 in r1.confidence > r2.confidence }
    }
}
