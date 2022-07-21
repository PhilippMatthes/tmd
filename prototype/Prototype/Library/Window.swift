import Foundation

class Window {
    fileprivate let maxLength: Int
    fileprivate(set) var values: [Parameter]

    init(maxLength: Int, values: [Parameter] = []) {
        self.maxLength = maxLength
        self.values = values
    }

    func push(_ value: Parameter) {
        values.append(value)
        if values.count > maxLength {
            values.removeFirst(values.count - maxLength)
        }
    }
}
