import Foundation
import CoreMotion

protocol Triaxial {
    var xParam: Parameter { get }
    var yParam: Parameter { get }
    var zParam: Parameter { get }

    /// Convert the iOS format to a compatible android format.
    func toAndroidFormat() -> ProcessedTriaxial
}

struct ProcessedTriaxial: Triaxial {
    let xParam: Parameter
    let yParam: Parameter
    let zParam: Parameter
}

extension Triaxial {
    func identity() -> ProcessedTriaxial {
        .init(xParam: xParam, yParam: yParam, zParam: zParam)
    }

    func scale(_ f: Parameter) -> ProcessedTriaxial {
        .init(xParam: xParam * f, yParam: yParam * f, zParam: zParam * f)
    }

    func magnitude() -> Parameter {
        sqrt(pow(xParam, 2) + pow(yParam, 2) + pow(zParam, 2))
    }

    func toAndroidFormat() -> ProcessedTriaxial { identity() }
}

extension CMAcceleration: Triaxial {
    var xParam: Parameter { .init(x) }
    var yParam: Parameter { .init(y) }
    var zParam: Parameter { .init(z) }

    func toAndroidFormat() -> ProcessedTriaxial { scale(9.81) }
}

extension CMRotationRate: Triaxial {
    var xParam: Parameter { .init(x) }
    var yParam: Parameter { .init(y) }
    var zParam: Parameter { .init(z) }
}

extension CMMagneticField: Triaxial {
    var xParam: Parameter { .init(x) }
    var yParam: Parameter { .init(y) }
    var zParam: Parameter { .init(z) }
}

