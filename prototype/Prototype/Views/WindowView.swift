import SwiftUI

struct WindowGraphView: View {
    let windowLength: Int = 500
    let window: [Parameter]

    private func fmt(_ parameter: Parameter?) -> String {
        if let parameter = parameter {
            return String(format: "%.2f", parameter)
        } else {
            return "n/a"
        }
    }

    private func graph(path: inout Path, size: CGSize) {
        guard
            let pMax = window.max(),
            let pMin = window.min(),
            pMin < pMax
        else { return }
        for (i, p) in window.enumerated() {
            let point = CGPoint(
                x: (CGFloat(i) / CGFloat(windowLength)) * size.width,
                y: (CGFloat((pMax - p) / (pMax - pMin))) * size.height
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(fmt(window.max()))").font(.footnote)
                Spacer()
                Text("\(fmt(window.min()))").font(.footnote)
            }
            .frame(width: 40)
            GeometryReader { reader in
                Path({ p in graph(path: &p, size: reader.size) }).stroke()
            }
        }
    }
}

struct WindowView: View {
    let sensor: Sensor
    let windowLength: Int = 500
    let window: [Parameter]

    var body: some View {
        CardView {
            VStack {
                Text(sensor.description)
                WindowGraphView(window: window)
            }
            .padding()
        }
    }
}

struct WindowView_Previews: PreviewProvider {
    static var previews: some View {
        WindowView(sensor: .accMag, window:
            Array((0..<500)).map { _ -> Parameter in
                Parameter.random(in: -1.0 ... 1.0)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: 128)
        .padding()
    }
}
