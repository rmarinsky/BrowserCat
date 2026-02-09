import SwiftUI

struct HotkeyRecorder: View {
    var onRecord: ((key: Character, keyCode: UInt16)?) -> Void

    @State private var displayText = "Press a key..."
    @State private var eventMonitor: Any?

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
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Delete key clears the hotkey
                if event.keyCode == 51 {
                    onRecord(nil)
                    return nil
                }

                if let chars = event.charactersIgnoringModifiers?.lowercased(),
                   let char = chars.first,
                   char.isLetter || char.isNumber
                {
                    onRecord((key: char, keyCode: event.keyCode))
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
}
