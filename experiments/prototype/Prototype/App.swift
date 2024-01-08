import SwiftUI
import CoreLocation

/// A manager to test GNSS energy usage.
private class GNSSService: NSObject, ObservableObject, CLLocationManagerDelegate {
    var manager: CLLocationManager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
    }

    func run() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) { /* Just for GNSS energy usage testing */}
}

@main
struct SHLModelEvaluationApp: App {
    @StateObject private var pipeline = try! Pipeline()
    @StateObject private var gnss = GNSSService()

    @State private var gnssIsActive = false
    @State private var selectedAccelerator: Classifier.Accelerator = .cpu
    @State private var selectedModelFileName: String = Models.standard
    @State private var visualizationIsActive = false

    private func loadClassifier() {
        try! pipeline.load(
            classifierWith: selectedModelFileName,
            andAccelerator: selectedAccelerator
        )
    }

    private var visualizationView: some View {
        VStack {
            if let predictions = pipeline.predictions {
                LabelsView(predictions: predictions)
                    .frame(height: 512)
            }
            ForEach(Sensor.order, id: \.rawValue) { sensor in
                if let values = pipeline.sensorWindows[sensor]?.values {
                    WindowView(sensor: sensor, window: values)
                        .frame(height: 128)
                } else {
                    EmptyView()
                }
            }
        }
        .padding()
    }

    private var profilingView: some View {
        VStack {
            if let predictions = pipeline.predictions {
                ForEach(predictions, id: \.label.rawValue) { p -> Text in
                    Text("\(p.label.description): \(p.confidence * 100)")
                }
            }
        }
        .padding()
    }

    private var content: some View {
        ScrollView {
            VStack {
                Picker("Model File Name", selection: $selectedModelFileName) {
                    ForEach(Models.all, id: \.self) { modelFileName in
                        Text(modelFileName)
                    }
                }
                .frame(height: 164)
                .padding(.horizontal)
                Picker("Accelerator", selection: $selectedAccelerator) {
                    ForEach(Classifier.Accelerator.all, id: \.rawValue) { accelerator in
                        Text(accelerator.description).tag(accelerator)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                Toggle("Visualization is active", isOn: $visualizationIsActive)
                    .padding(.horizontal)
                Toggle("GNSS is active", isOn: $gnssIsActive)
                    .padding(.horizontal)

                if visualizationIsActive {
                    visualizationView
                } else {
                    profilingView
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            content
                .onChange(of: gnssIsActive) { isActive in
                    if isActive {
                        gnss.run()
                    } else {
                        gnss.stop()
                    }
                }
                .onChange(of: selectedAccelerator) { _ in
                    loadClassifier()
                }
                .onChange(of: selectedModelFileName) { _ in
                    loadClassifier()
                }
                .onAppear(perform: {
                    loadClassifier()
                    pipeline.run()

                    UIScreen.main.brightness = CGFloat(0.75)
                })
                .onDisappear(perform: pipeline.stop)
        }
    }
}
