import Foundation

protocol Preprocessor {
    func transform(_ input: [Parameter]) -> [Parameter]
}

final class MovingAverage: Preprocessor {
    let period: Int

    init(period: Int) {
        self.period = period
    }

    /// Compute the moving average.
    func transform(_ input: [Parameter]) -> [Parameter] {
        (0 ..< input.count).map { i in
            guard i != 0 else { return input[i] }
            let range = max(0, i - period) ..< i
            let sum = input[range].reduce(0, +)
            return sum / Parameter(period)
        }
    }
}

enum ConfigError: Error {
    case configNotFound
}

protocol ConfigPreprocessor: Preprocessor {
    associatedtype Config: Codable

    var config: Config { get }

    init(config: Config)
}

extension ConfigPreprocessor {
    init(configFileName: String) throws {
        guard
            let path = Bundle.main.path(forResource: configFileName, ofType: "json")
        else { throw ConfigError.configNotFound }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let config = try JSONDecoder().decode(Config.self, from: data)
        self.init(config: config)
    }
}

final class PowerTransformer: ConfigPreprocessor {
    struct Config: Codable {
        let lambdas: [Parameter]
    }

    let config: Config

    init(config: Config) {
        self.config = config
    }

    /// Compute the Yeo-Johnson Power Transformation, as in Scikit-Learn. See: https://scikit-learn.org/stable/modules/preprocessing.html#preprocessing-transformer
    func transform(_ input: [Parameter]) -> [Parameter] {
        input
            .enumerated()
            // Yeo-Johnson Transformation
            .map { (i, x) -> Parameter in
                let λ = config.lambdas[i]

                if λ != 0, x >= 0 {
                    return (pow(x + 1, λ) - 1) / λ
                } else if λ == 0, x >= 0 {
                    return log(x + 1)
                } else if λ != 2, x < 0 {
                    return -((pow((-x + 1), 2 - λ) - 1)) / (2 - λ)
                } else /* λ == 2, x < 0 */ {
                    return -log(-x + 1)
                }
            }
    }
}

final class StandardScaler: ConfigPreprocessor {
    struct Config: Codable {
        let scales: [Parameter]
        let means: [Parameter]
    }

    let config: Config

    init(config: Config) {
        self.config = config
    }

    /// Standard scale the input.
    func transform(_ input: [Parameter]) -> [Parameter] {
        input
            .enumerated()
            // Standard scaling
            .map { (i, x) -> Parameter in
                let μ = config.means[i]
                let σ = config.scales[i]
                return (x - μ) / σ
            }
    }
}


