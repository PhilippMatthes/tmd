import SwiftUI

fileprivate extension Classifier.Class {
    var iconName: String {
        switch self {
        case .null: return "nothing"
        case .still: return "person"
        case .walking: return "walk"
        case .run: return "runner"
        case .bike: return "bicycle"
        case .car: return "vehicle"
        case .bus: return "bus"
        case .train: return "train"
        case .subway: return "underground"
        }
    }
}

struct LabelsView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var confidences = [Classifier.Class: Parameter]()

    init(predictions: [Classifier.Prediction]) {
        for prediction in predictions {
            confidences[prediction.label] = prediction.confidence
        }
    }

    private func fmt(_ parameter: Parameter) -> String {
        String(format: "%.2f", parameter)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(Classifier.Class.order, id: \.rawValue) { label -> CardView in
                CardView {
                    ZStack(alignment: .bottom) {
                        GeometryReader { geometry in
                            Rectangle()
                                .foregroundColor(Color.blue.opacity(Double(self.confidences[label] ?? 0)))
                        }
                        VStack {
                            Text(label.description)
                                .font(.caption)
                                .padding(.top)
                            Image(label.iconName)
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal)
                            Text("\(fmt((self.confidences[label] ?? 0) * 100))%")
                                .font(.caption)
                                .padding(.bottom)
                        }
                    }
                }
            }
        }
    }
}

struct LabelsView_Previews: PreviewProvider {
    static var previews: some View {
        LabelsView(predictions: [
            .init(confidence: 0.9, label: .bike),
            .init(confidence: 0.1, label: .bus),
        ])
        .padding()
    }
}
