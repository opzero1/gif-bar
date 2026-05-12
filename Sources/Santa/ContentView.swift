import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var library: GifLibrary
    @State private var selectedID: GifItem.ID?
    @State private var dropIsTargeted = false
    @State private var copiedMessage: String?
    @State private var hoveredGalleryID: GifItem.ID?
    @State private var isResolving = false
    @State private var statusMessage = "Drop a Giphy link, hosted GIF URL, or GIF file."

    private var selectedItem: GifItem? {
        guard let selectedID else { return library.items.first }
        return library.items.first { $0.id == selectedID } ?? library.items.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    dropZone
                    selectedCard
                    gallerySection
                }
                .padding(14)
            }
        }
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
        }
        .onChange(of: library.items) { _, items in
            if selectedID == nil || !items.contains(where: { $0.id == selectedID }) {
                selectedID = items.first?.id
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text("GifBar")
                .font(.headline)

            Spacer()

            Button {
                library.removeAll()
                selectedID = nil
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear gallery")
            .disabled(library.items.isEmpty)

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit GifBar")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private var selectedCard: some View {
        if let item = selectedItem {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.state == .ready ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(item.state == .ready ? .green : .orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        Text(item.note ?? item.source)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }

                if item.state == .ready {
                    if let cdnURL = item.cdnURL {
                        Text(cdnURL)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }

                    TextField("Slack text", text: slackTextBinding)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        Button {
                            if let cdnURL = item.cdnURL {
                                Clipboard.copy(cdnURL)
                                copiedMessage = "Copied URL"
                            }
                        } label: {
                            Label("URL", systemImage: "doc.on.doc")
                        }

                        Button {
                            if let slackLink = selectedItem?.slackLink {
                                Clipboard.copy(slackLink)
                                copiedMessage = "Copied Slack link"
                            }
                        } label: {
                            Label("Slack", systemImage: "text.badge.checkmark")
                        }
                        .keyboardShortcut("c", modifiers: [.command, .shift])

                        Spacer()

                        Button {
                            if let cdnURL = item.cdnURL, let url = URL(string: cdnURL) {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "safari")
                        }
                        .help("Open GIF")
                    }

                    if let copiedMessage {
                        Text(copiedMessage)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(item.note ?? "This item is not ready.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .glassPanel()
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Gallery")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if !library.items.isEmpty {
                    Text("\(library.items.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                }
            }

            if library.items.isEmpty {
                Text("No saved GIFs yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .glassPanel()
            } else {
                LazyVGrid(columns: galleryColumns, spacing: 10) {
                    ForEach(library.items) { item in
                        Button {
                            selectedID = item.id
                            if let cdnURL = item.cdnURL {
                                Clipboard.copy(cdnURL)
                                copiedMessage = "Copied URL"
                                statusMessage = "Copied CDN URL."
                            }
                        } label: {
                            GalleryTile(
                                item: item,
                                isSelected: selectedID == item.id,
                                isPlaying: hoveredGalleryID == item.id,
                                onDelete: {
                                    library.remove(item)
                                    if selectedID == item.id {
                                        selectedID = library.items.first?.id
                                    }
                                }
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredGalleryID = hovering ? item.id : nil
                        }
                        .help(item.cdnURL.map { "Click to copy \($0)" } ?? "GIF is not ready")
                    }
                }
            }
        }
    }

    private var galleryColumns: [GridItem] {
        [
            GridItem(.fixed(168), spacing: 10),
            GridItem(.fixed(168), spacing: 10)
        ]
    }

    private var slackTextBinding: Binding<String> {
        Binding {
            selectedItem?.slackText ?? "gif"
        } set: { value in
            guard var item = selectedItem else { return }
            item.slackText = value
            library.update(item)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: isResolving ? "sparkles" : "square.and.arrow.down")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(dropIsTargeted ? .green : .secondary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(isResolving ? "Resolving GIF" : "Drop GIF Here")
                .font(.subheadline.weight(.semibold))

            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 126)
        .background(dropIsTargeted ? Color.green.opacity(0.12) : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(dropIsTargeted ? Color.green : Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1.2, dash: [7, 5]))
        }
        .onDrop(of: DropReader.supportedTypes, isTargeted: $dropIsTargeted) { providers in
            DropReader.readFirstValue(from: providers) { value in
                Task { @MainActor in
                    await handleDroppedValue(value)
                }
            }
        }
        .contextMenu {
            Button("Paste From Clipboard") {
                pasteFromClipboard()
            }
        }
    }

    private func handleDroppedValue(_ value: String?) async {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Could not read that drop item."
            return
        }

        isResolving = true
        statusMessage = "Resolving GIF page..."

        guard let item = await library.resolveAndAdd(value) else {
            isResolving = false
            statusMessage = "Could not read that drop item."
            return
        }
        isResolving = false
        selectedID = item.id

        switch item.state {
        case .ready:
            statusMessage = "CDN URL ready."
        case .needsUpload:
            statusMessage = "GIF file added, but CDN upload is not configured yet."
        case .invalid:
            statusMessage = item.note ?? "Unsupported input."
        }
    }

    private func pasteFromClipboard() {
        let value = NSPasteboard.general.string(forType: .string)
        Task {
            await handleDroppedValue(value)
        }
    }
}

private struct GalleryTile: View {
    let item: GifItem
    let isSelected: Bool
    let isPlaying: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            GifThumbnail(urlString: item.cdnURL, isPlaying: isPlaying)
                .frame(width: 152, height: 88)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: iconName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(iconColor)
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(5)
                }
                .overlay(alignment: .topLeading) {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 20, height: 20)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .help("Remove from Gallery")
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(width: 168, height: 132, alignment: .topLeading)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var iconName: String {
        switch item.state {
        case .ready: "checkmark.circle.fill"
        case .needsUpload: "icloud.and.arrow.up"
        case .invalid: "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch item.state {
        case .ready: .green
        case .needsUpload: .orange
        case .invalid: .red
        }
    }

    private var subtitle: String {
        switch item.state {
        case .ready: item.cdnURL ?? "Ready"
        case .needsUpload: "Upload required"
        case .invalid: item.note ?? item.source
        }
    }
}

private extension View {
    func glassPanel(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
    }
}
