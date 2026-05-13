import AppKit
import SwiftUI

struct GifThumbnail: View {
    let urlString: String?
    let isPlaying: Bool

    @State private var image: NSImage?
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            if let image {
                AnimatedImageView(image: image, isPlaying: isPlaying)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if loadFailed {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(cornerRadius: 10, padding: 0, isActive: isPlaying)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: urlString) {
            await loadImage()
        }
    }

    private func loadImage() async {
        let requestedURLString = urlString
        image = nil
        loadFailed = false

        guard let requestedURLString, let url = URL(string: requestedURLString) else {
            loadFailed = true
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, requestedURLString == urlString else { return }
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

    func makeNSView(context: Context) -> NSView {
        let wrapper = NSView()
        wrapper.wantsLayer = true
        wrapper.layer?.masksToBounds = true

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleAxesIndependently
        imageView.imageAlignment = .alignCenter
        imageView.imageFrameStyle = .none
        imageView.canDrawSubviewsIntoLayer = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)

        wrapper.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: wrapper.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

        return wrapper
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let imageView = view.subviews.first as? NSImageView else { return }
        imageView.image = image
        imageView.animates = isPlaying
    }
}
