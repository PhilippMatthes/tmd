import Foundation
import CoreMotion

enum Sensor: Int, CustomStringConvertible, Hashable {
    /// Magnitude of `TYPE_ACCELEROMETER` from Android (with included gravity component)
    case accMag = 0
    /// Magnitude of `TYPE_MAGNETIC_FIELD` from Android (calibrated magnetic field)
    case magMag = 1
    /// Magnitude of `TYPE_GYROSCOPE` from Android (in rad/s)
    case gyrMag = 2

    /// The feature index in each sample.
    var sampleIndex: Int { rawValue }

    var description: String {
        switch self {
        case .accMag: return "Acceleration Magnitude"
        case .magMag: return "Magnetometer Magnitude"
        case .gyrMag: return "Gyrosensor Magnitude"
        }
    }

    static let order: [Self] = [.accMag, .magMag, .gyrMag]
}

extension Sensor {
    var configFileName: String {
        switch self {
        case .accMag: return "acc_mag.scaler"
        case .magMag: return "mag_mag.scaler"
        case .gyrMag: return "gyr_mag.scaler"
        }
    }
}

final class SensorSource: ObservableObject {
    private var sampleTimer: Timer?
    private let sampleInterval: TimeInterval

    init(sampleInterval: TimeInterval) {
        self.sampleInterval = sampleInterval
    }

    private lazy var manager: CMMotionManager = {
        manager = CMMotionManager()
        manager.accelerometerUpdateInterval = sampleInterval
        manager.deviceMotionUpdateInterval = sampleInterval
        manager.gyroUpdateInterval = sampleInterval
        return manager
    }()

    /// Load data synchronously from the CMMotionManager.
    /// This includes a mapping of the data gathering from the SHL Android app.
    /// For the original SHL Code, see: https://github.com/STRCWearlab/DataLogger
    /// For information about the Android Sensors, see: https://developer.android.com/reference/android/hardware/SensorEvent#values
    /// For information about the iOS Sensors, see: https://developer.apple.com/documentation/coremotion/cmmotionmanager
    func startListening(callback: @escaping ([Sensor: Parameter]) -> Void) {
        manager.startAccelerometerUpdates()
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
        manager.startGyroUpdates()

        sampleTimer = Timer(
            fire: Date(), interval: sampleInterval, repeats: true
        ) { _ in
            guard
                let accData = self.manager.accelerometerData,
                let motionData = self.manager.deviceMotion,
                let gyrData = self.manager.gyroData
            else { return }

            callback([
                .accMag: accData.acceleration
                    .toAndroidFormat()
                    .magnitude(),
                .magMag: motionData.magneticField.field
                    .toAndroidFormat()
                    .magnitude(),
                .gyrMag: gyrData.rotationRate
                    .toAndroidFormat()
                    .magnitude(),
            ])
        }

        RunLoop.current.add(sampleTimer!, forMode: .default)
    }

    func stopListening() {
        sampleTimer?.invalidate()

        manager.stopDeviceMotionUpdates()
        manager.stopAccelerometerUpdates()
        manager.stopMagnetometerUpdates()
    }
}

