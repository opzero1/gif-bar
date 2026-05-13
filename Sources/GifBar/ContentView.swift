import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var library: GifLibrary
    @EnvironmentObject private var appState: GifBarState
    @AppStorage("gifbar.giphy-api-key") private var storedAPIKey = ""

    @State private var query = ""
    @State private var results: [GiphyGIF] = []
    @State private var hoveredResultID: String?
    @State private var hoveredRecentID: GifItem.ID?
    @State private var copiedID: String?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: FocusedField?

    private let client = GiphyClient()

    private enum FocusedField {
        case apiKey
        case search
    }

    private var effectiveAPIKey: String {
        let saved = storedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !saved.isEmpty { return saved }
        return ProcessInfo.processInfo.environment["GIPHY_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var recentItems: [GifItem] {
        library.items.filter { $0.cdnURL != nil }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                searchBar

                if appState.showsAPIKeySettings || effectiveAPIKey.isEmpty {
                    apiKeyPanel
                }

                searchResultsSection
                recentSection
            }
            .padding(14)
        }
        .liquidGlassBackground()
        .task(id: normalizedQuery) {
            await debouncedSearch()
        }
        .onChange(of: storedAPIKey) { _, _ in
            if !effectiveAPIKey.isEmpty {
                focusedField = .search
            }
            Task { await search() }
        }
        .onChange(of: appState.showsAPIKeySettings) { _, isShowing in
            focusedField = isShowing ? .apiKey : .search
        }
        .onAppear {
            focusedField = effectiveAPIKey.isEmpty ? .apiKey : .search
        }
    }

    private var apiKeyPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Giphy API Key", systemImage: "key.fill")
                    .font(.caption.weight(.semibold))

                Spacer()

                if !effectiveAPIKey.isEmpty {
                    Button {
                        appState.showsAPIKeySettings = false
                        focusedField = .search
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                    .help("Hide API key settings")
                }

                Button {
                    NSWorkspace.shared.open(URL(string: "https://developers.giphy.com/dashboard/")!)
                } label: {
                    Label("Get Key", systemImage: "safari")
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
            }

            SecureField("Paste API key", text: $storedAPIKey)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .apiKey)
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                }

            if storedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               ProcessInfo.processInfo.environment["GIPHY_API_KEY"]?.isEmpty == false {
                Text("Using GIPHY_API_KEY from the environment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Required by Giphy search. Saved locally in macOS user defaults.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .liquidGlass(cornerRadius: 16, isActive: effectiveAPIKey.isEmpty)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search Giphy", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .semibold))
                .focused($focusedField, equals: .search)
                .onSubmit {
                    Task { await search() }
                }

            if isSearching {
                ProgressView()
                    .controlSize(.small)
            } else if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }

            if effectiveAPIKey.isEmpty {
                Button {
                    appState.showsAPIKeySettings.toggle()
                    focusedField = .apiKey
                } label: {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Giphy API key")
            }
        }
        .frame(height: 26)
        .liquidGlass(cornerRadius: 16, padding: 8, isActive: focusedField == .search)
        .overlay(alignment: .bottomLeading) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 20)
                    .padding(.bottom, -22)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, errorMessage == nil ? 0 : 20)
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if normalizedQuery.isEmpty {
            EmptyView()
        } else if isSearching && results.isEmpty {
            InlineStateView(icon: "sparkles", message: "Searching")
        } else if !results.isEmpty {
            SectionHeader(title: "Results", count: results.count)

            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(results) { result in
                    Button {
                        copy(result)
                    } label: {
                        GiphyResultTile(
                            result: result,
                            isPlaying: hoveredResultID == result.id,
                            isCopied: copiedID == result.id
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        hoveredResultID = hovering ? result.id : nil
                    }
                    .help(result.cdnURL.map { "Copy \($0)" } ?? "No GIF URL")
                }
            }
        } else if !isSearching {
            InlineStateView(icon: "magnifyingglass", message: "No GIFs found")
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Recent",
                count: recentItems.count,
                actionSystemImage: recentItems.isEmpty ? nil : "trash",
                action: {
                    library.removeAll()
                }
            )

            if recentItems.isEmpty {
                InlineStateView(icon: "clock", message: "Recent GIFs appear here")
            } else {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(recentItems) { item in
                        Button {
                            copy(item)
                        } label: {
                            RecentTile(
                                item: item,
                                isPlaying: hoveredRecentID == item.id,
                                isCopied: copiedID == item.giphyID || copiedID == item.id.uuidString,
                                onDelete: { library.remove(item) }
                            )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredRecentID = hovering ? item.id : nil
                        }
                        .help(item.cdnURL.map { "Copy \($0)" } ?? "GIF is not ready")
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 140, maximum: 156), spacing: 10)
        ]
    }

    private func debouncedSearch() async {
        try? await Task.sleep(for: .milliseconds(320))
        if Task.isCancelled { return }
        await search()
    }

    private func search() async {
        guard !normalizedQuery.isEmpty else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        guard !effectiveAPIKey.isEmpty else {
            results = []
            errorMessage = GiphyClientError.missingAPIKey.errorDescription
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            results = try await client.search(query: normalizedQuery, apiKey: effectiveAPIKey)
        } catch {
            results = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isSearching = false
    }

    private func copy(_ result: GiphyGIF) {
        guard let item = result.makeLibraryItem(), let cdnURL = item.cdnURL else { return }
        let savedItem = library.add(item)
        Clipboard.copy(cdnURL)
        copiedID = savedItem.giphyID ?? savedItem.id.uuidString
        clearCopiedStateLater()
    }

    private func copy(_ item: GifItem) {
        guard let cdnURL = item.cdnURL else { return }
        let savedItem = library.add(item)
        Clipboard.copy(cdnURL)
        copiedID = savedItem.giphyID ?? savedItem.id.uuidString
        clearCopiedStateLater()
    }

    private func clearCopiedStateLater() {
        let copiedValue = copiedID
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if copiedID == copiedValue {
                copiedID = nil
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let count: Int
    var actionSystemImage: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                    }
            }

            if let actionSystemImage, let action {
                Button(action: action) {
                    Image(systemName: actionSystemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .help("Clear recent GIFs")
            }
        }
    }
}

private struct InlineStateView: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 14, padding: 0)
    }
}

private struct GiphyResultTile: View {
    let result: GiphyGIF
    let isPlaying: Bool
    let isCopied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GifThumbnail(urlString: thumbnailURL, isPlaying: isPlaying)
                .frame(maxWidth: .infinity)
                .frame(height: 92)
                .overlay(alignment: .topTrailing) {
                    statusBadge
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title.isEmpty ? "Giphy GIF" : result.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(result.displayCreator ?? metadataText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 144, maxHeight: 144, alignment: .topLeading)
        .liquidGlass(cornerRadius: 15, padding: 0, isActive: isPlaying || isCopied)
    }

    private var thumbnailURL: String? {
        isPlaying ? result.previewURL : (result.stillURL ?? result.previewURL)
    }

    private var metadataText: String {
        [result.rating?.uppercased(), result.sourceTLD]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " • ")
    }

    private var statusBadge: some View {
        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .font(.caption.weight(.bold))
            .foregroundStyle(isCopied ? .green : .primary)
            .frame(width: 24, height: 24)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
            .padding(6)
    }
}

private struct RecentTile: View {
    let item: GifItem
    let isPlaying: Bool
    let isCopied: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GifThumbnail(urlString: thumbnailURL, isPlaying: isPlaying)
                .frame(maxWidth: .infinity)
                .frame(height: 92)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isCopied ? .green : .primary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        }
                        .padding(6)
                }
                .overlay(alignment: .topLeading) {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 22, height: 22)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .help("Remove from Recent")
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(metadataText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let tags = item.tags, !tags.isEmpty {
                    Text(tags.prefix(3).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 166, maxHeight: 166, alignment: .topLeading)
        .liquidGlass(cornerRadius: 15, padding: 0, isActive: isPlaying || isCopied)
    }

    private var thumbnailURL: String? {
        isPlaying ? (item.previewURL ?? item.cdnURL) : (item.stillURL ?? item.previewURL ?? item.cdnURL)
    }

    private var metadataText: String {
        let creator: String?
        if let displayName = item.displayName, !displayName.isEmpty {
            creator = displayName
        } else if let username = item.username, !username.isEmpty {
            creator = "@\(username)"
        } else {
            creator = nil
        }

        let metadata: [String] = [creator, item.rating?.uppercased(), item.sourceTLD]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
        return metadata.isEmpty ? "Giphy" : metadata.joined(separator: " • ")
    }
}
