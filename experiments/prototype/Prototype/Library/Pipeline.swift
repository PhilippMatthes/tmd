import Foundation

final class Pipeline: ObservableObject {
    private let config: Config
    private let source: SensorSource
    private let sensorPreprocessors: [Sensor: [Preprocessor]]

    private var classifier: Classifier?
    private var inferenceTimer: Timer?

    @Published var sensorWindows: [Sensor: Window]
    @Published var predictions: [Classifier.Prediction]?

    struct Config {
        let inferenceInterval: TimeInterval = 0.5
        let sampleInterval: TimeInterval = 0.01
        let windowLength: Int = 500

        static let standard: Self = .init()
    }

    init(config: Config = .standard) throws {
        self.config = config

        source = SensorSource(sampleInterval: config.sampleInterval)
        sensorWindows = Dictionary(uniqueKeysWithValues: Sensor.order.map { sensor in
            let window = Window(maxLength: config.windowLength)
            return (sensor, window)
        })
        sensorPreprocessors = Dictionary(uniqueKeysWithValues: try Sensor.order.map { sensor in
            let preprocessors: [Preprocessor] = [
                try PowerTransformer(configFileName: sensor.configFileName),
                try StandardScaler(configFileName: sensor.configFileName),
            ]
            return (sensor, preprocessors)
        })
    }

    private func infer() {
        DispatchQueue.main.async {
            guard let classifier = self.classifier else { return }

            var preprocessedWindows = [[Parameter]]() // (n_features x n_timesteps)
            for sensor in Sensor.order {
                guard
                    var values = self.sensorWindows[sensor]?.values,
                    values.count == self.config.windowLength,
                    let preprocessors = self.sensorPreprocessors[sensor]
                else { return }
                for preprocessor in preprocessors {
                    values = preprocessor.transform(values)
                }
                preprocessedWindows.append(values)
            }

            var input = [[Parameter]]() // Reshape to (n_timesteps x n_features)
            for i in 0 ..< self.config.windowLength {
                input.append(preprocessedWindows.map { w in w[i] })
            }

            guard
                let predictions = try? classifier.classify(input: input)
            else { return }

            self.predictions = predictions
        }
    }

    func load(
        classifierWith modelFileName: String = "model",
        andAccelerator accelerator: Classifier.Accelerator
    ) throws {
        classifier = try Classifier(
            modelFileName: modelFileName,
            accelerator: accelerator
        )
    }

    func run() {
        source.startListening { samples in
            for (sensor, sample) in samples {
                self.sensorWindows[sensor]?.push(sample)
            }
        }

        inferenceTimer = Timer(
            fire: Date(), interval: config.inferenceInterval, repeats: true
        ) { _ in self.infer() }

        RunLoop.current.add(inferenceTimer!, forMode: .default)
    }

    func stop() {
        inferenceTimer?.invalidate()

        source.stopListening()
    }
}
