import SwiftUI

struct HotkeyRecorder: View {
    var onRecord: (Character?) -> Void

    @State private var displayText = "Press a key..."

    var body: some View {
        VStack(spacing: 12) {
            Text(displayText)
                .font(.system(size: 14, design: .rounded))
                .frame(width: 160)
                .padding()

            HStack {
                Button("Clear") {
                    onRecord(nil)
                }
                .buttonStyle(.bordered)

                Button("Cancel") {
                    onRecord(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onKeyPress(characters: .alphanumerics) { keyPress in
            if let char = keyPress.characters.first {
                onRecord(char)
            }
            return .handled
        }
        .onKeyPress(.delete) {
            onRecord(nil)
            return .handled
        }
    }
}
