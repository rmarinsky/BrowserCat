import SwiftUI

struct FaviconView: View {
    let domain: String
    var size: CGFloat = 16

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: size * 0.75))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .task(id: domain) {
            image = await FaviconManager.shared.favicon(for: domain)
        }
    }
}
