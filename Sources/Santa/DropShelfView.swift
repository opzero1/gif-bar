import AppKit
import SwiftUI

struct DropShelfView: View {
    @EnvironmentObject private var library: GifLibrary
    @State private var dropIsTargeted = false
    @State private var isResolving = false
    @State private var statusMessage = "Drop GIF link here"

    let onAccepted: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isResolving ? "sparkles" : "play.rectangle.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(dropIsTargeted ? .green : .primary)
                .frame(width: 52, height: 52)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(isResolving ? "Resolving GIF" : "Drop to GifBar")
                    .font(.headline)

                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .frame(width: 360, height: 92)
        .background(dropIsTargeted ? Color.green.opacity(0.10) : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(dropIsTargeted ? Color.green : Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 24, y: 12)
        .onDrop(of: DropReader.supportedTypes, isTargeted: $dropIsTargeted) { providers in
            DropReader.readFirstValue(from: providers) { value in
                Task { @MainActor in
                    await resolveDrop(value)
                }
            }
        }
    }

    private func resolveDrop(_ value: String?) async {
        isResolving = true
        statusMessage = "Resolving direct GIF URL..."

        guard let item = await library.resolveAndAdd(value) else {
            isResolving = false
            statusMessage = "Could not read that drop."
            return
        }

        isResolving = false

        if let cdnURL = item.cdnURL {
            Clipboard.copy(cdnURL)
            statusMessage = "Copied CDN URL"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                onAccepted()
            }
        } else {
            statusMessage = item.note ?? "Could not resolve GIF."
        }
    }
}
