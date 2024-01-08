import SwiftUI

/// A reusable card view with a subtle shadow.
struct CardView<Content>: View where Content: View {
    private let content: Content

    /// Initialize the card view with an optional background blur effect.
    ///
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.white)
            .foregroundColor(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView {
            VStack(alignment: .leading) {
                Text("Card Title")
                    .font(.title)
                    .padding()
                Divider()
                Text("Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.")
                    .padding()
            }
        }
        .preferredColorScheme(.dark)
        .padding()
    }
}
