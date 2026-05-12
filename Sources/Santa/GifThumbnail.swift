import AppKit
import SwiftUI

struct GifThumbnail: View {
    let urlString: String?
    let isPlaying: Bool

    @State private var image: NSImage?
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)

            if let image {
                AnimatedImageView(image: image, isPlaying: isPlaying)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if loadFailed {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .task(id: urlString) {
            await loadImage()
        }
    }

    private func loadImage() async {
        image = nil
        loadFailed = false

        guard let urlString, let url = URL(string: urlString) else {
            loadFailed = true
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let loadedImage = NSImage(data: data) else {
                loadFailed = true
                return
            }
            image = loadedImage
        } catch {
            loadFailed = true
        }
    }
}

private struct AnimatedImageView: NSViewRepresentable {
    let image: NSImage
    let isPlaying: Bool

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.canDrawSubviewsIntoLayer = true
        return imageView
    }

    func updateNSView(_ imageView: NSImageView, context: Context) {
        imageView.image = image
        imageView.animates = isPlaying
    }
}
