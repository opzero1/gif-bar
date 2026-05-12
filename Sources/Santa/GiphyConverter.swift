import Foundation

enum GiphyConverter {
    private static let defaultHost = "media0.giphy.com"
    private static let defaultRendition = "200.gif"

    static func resolveItem(from rawValue: String) async -> GifItem {
        let value = normalizedInput(rawValue)
        let immediate = makeItem(from: value)
        if immediate.state != .invalid {
            return immediate
        }

        guard let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased()) else {
            return immediate
        }

        do {
            if let resolved = try await resolveHostedGIFPage(url) {
                return resolved
            }
        } catch {
            return GifItem(
                source: value,
                cdnURL: nil,
                title: url.host(percentEncoded: false) ?? "Unsupported GIF page",
                state: .invalid,
                note: "Could not resolve a direct GIF from this page."
            )
        }

        return GifItem(
            source: value,
            cdnURL: nil,
            title: url.host(percentEncoded: false) ?? "Unsupported GIF page",
            state: .invalid,
            note: "No direct .gif asset was found on this page."
        )
    }

    static func makeItem(from rawValue: String) -> GifItem {
        let value = normalizedInput(rawValue)

        if let url = URL(string: value), url.isFileURL {
            return makeLocalFileItem(url)
        }

        guard let url = URL(string: value), let host = url.host(percentEncoded: false) else {
            return GifItem(
                source: value,
                cdnURL: nil,
                title: "Invalid input",
                state: .invalid,
                note: "Drop a Giphy URL, a direct GIF URL, or a hosted GIF URL."
            )
        }

        if host.contains("giphy.com"), let converted = convertGiphyURL(url) {
            return GifItem(
                source: value,
                cdnURL: converted.url,
                title: converted.id,
                state: .ready,
                note: "Converted to Giphy CDN rendition."
            )
        }

        if url.pathExtension.lowercased() == "gif", ["http", "https"].contains(url.scheme?.lowercased()) {
            return GifItem(
                source: value,
                cdnURL: value,
                title: url.lastPathComponent.isEmpty ? host : url.lastPathComponent,
                state: .ready,
                note: "Direct hosted GIF URL."
            )
        }

        return GifItem(
            source: value,
            cdnURL: nil,
            title: host,
            state: .invalid,
            note: "Looking for a direct GIF asset on this page."
        )
    }

    static func makeItem(fromFileURL url: URL) -> GifItem {
        makeLocalFileItem(url)
    }

    static func unresolvedItem(from rawValue: String?) -> GifItem {
        let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let preview = String(value.prefix(120))
        return GifItem(
            source: value,
            cdnURL: nil,
            title: value.isEmpty ? "Unreadable drop" : "Unsupported drop",
            state: .invalid,
            note: value.isEmpty ? "GifBar could not read a URL from this drop." : "No direct GIF URL found. Received: \(preview)"
        )
    }

    private static func normalizedInput(_ rawValue: String) -> String {
        let trimmed = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&")

        if let match = trimmed.range(of: #"https?:\/\/[^\s<>"']+"#, options: [.regularExpression, .caseInsensitive]) {
            return String(trimmed[match])
                .trimmingCharacters(in: CharacterSet(charactersIn: ".,);]}>\"'"))
        }

        if let match = trimmed.range(of: #"file:\/\/[^\s<>"']+"#, options: [.regularExpression, .caseInsensitive]) {
            return String(trimmed[match])
                .trimmingCharacters(in: CharacterSet(charactersIn: ".,);]}>\"'"))
        }

        return trimmed
    }

    private static func makeLocalFileItem(_ url: URL) -> GifItem {
        let isGIF = url.pathExtension.lowercased() == "gif"
        return GifItem(
            source: url.path,
            cdnURL: nil,
            title: url.lastPathComponent,
            state: isGIF ? .needsUpload : .invalid,
            note: isGIF
                ? "Local GIF files need a CDN uploader before Slack can preview them from a link."
                : "Only GIF files are supported."
        )
    }

    private static func convertGiphyURL(_ url: URL) -> (url: String, id: String)? {
        guard let host = url.host(percentEncoded: false) else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }

        if host.hasPrefix("media"), let mediaIndex = parts.firstIndex(of: "media") {
            var mediaParts = Array(parts.dropFirst(mediaIndex + 1))

            if let first = mediaParts.first, first.hasPrefix("v1.") {
                mediaParts.removeFirst()
            }

            if let id = mediaParts.first, looksLikeGiphyID(id) {
                return (url: "https://\(host)/media/\(id)/\(defaultRendition)", id: id)
            }
        }

        if host.hasPrefix("i."), let firstPart = parts.first {
            let id = strippingKnownImageExtension(from: firstPart)
            if looksLikeGiphyID(id) {
                return (url: "https://\(defaultHost)/media/\(id)/\(defaultRendition)", id: id)
            }
        }

        for part in parts.reversed() {
            let lastDashComponent = part.split(separator: "-").last.map(String.init) ?? part
            let candidate = strippingKnownImageExtension(from: lastDashComponent)
            if looksLikeGiphyID(candidate) {
                return (url: "https://\(defaultHost)/media/\(candidate)/\(defaultRendition)", id: candidate)
            }
        }

        return nil
    }

    private static func looksLikeGiphyID(_ value: String) -> Bool {
        guard value.count >= 8 else { return false }
        return value.range(of: #"^[A-Za-z0-9]+$"#, options: .regularExpression) != nil
    }

    private static func strippingKnownImageExtension(from value: String) -> String {
        let knownExtensions = [".gif", ".webp", ".png", ".jpg", ".jpeg", ".mp4"]
        for suffix in knownExtensions where value.lowercased().hasSuffix(suffix) {
            return String(value.dropLast(suffix.count))
        }
        return value
    }

    private static func resolveHostedGIFPage(_ url: URL) async throws -> GifItem? {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("Mozilla/5.0 GifBar GIF Resolver", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<400).contains(httpResponse.statusCode) else {
            return nil
        }

        if let mimeType = response.mimeType?.lowercased(), mimeType == "image/gif" {
            let finalURL = response.url ?? url
            return directItem(source: url.absoluteString, gifURL: finalURL.absoluteString, note: "Direct hosted GIF URL.")
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return nil
        }

        return resolveHTMLPage(source: url.absoluteString, html: html, finalURL: response.url ?? url)
    }

    static func resolveHTMLPage(source: String, html: String, finalURL: URL) -> GifItem? {
        guard let gifURL = firstDirectGIFURL(in: html, relativeTo: finalURL) else {
            return nil
        }

        return directItem(source: source, gifURL: gifURL.absoluteString, note: "Resolved direct GIF from hosted page.")
    }

    private static func firstDirectGIFURL(in html: String, relativeTo baseURL: URL) -> URL? {
        let unescapedHTML = html
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "&amp;", with: "&")

        let patterns = [
            #"<meta[^>]+(?:property|name)=["'](?:og:image|twitter:image|twitter:image:src)["'][^>]+content=["']([^"']+?\.gif(?:\?[^"']*)?)["']"#,
            #"<meta[^>]+content=["']([^"']+?\.gif(?:\?[^"']*)?)["'][^>]+(?:property|name)=["'](?:og:image|twitter:image|twitter:image:src)["']"#,
            #"(https?:\/\/[^\s"'<>]+?\.gif(?:\?[^\s"'<>]*)?)"#,
            #"(\/\/[^\s"'<>]+?\.gif(?:\?[^\s"'<>]*)?)"#,
            #"(?:(?:src|data-src|data-gif|content)=["'])([^"']+?\.gif(?:\?[^"']*)?)["']"#
        ]

        for pattern in patterns {
            if let match = unescapedHTML.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchedText = String(unescapedHTML[match])
                if let candidate = extractGIFCandidate(from: matchedText), let url = normalizedURL(candidate, relativeTo: baseURL) {
                    return url
                }
            }
        }

        return nil
    }

    private static func extractGIFCandidate(from text: String) -> String? {
        if let match = text.range(of: #"https?:\/\/[^\s"'<>]+?\.gif(?:\?[^\s"'<>]*)?"#, options: [.regularExpression, .caseInsensitive]) {
            return String(text[match])
        }

        if let match = text.range(of: #"\/\/[^\s"'<>]+?\.gif(?:\?[^\s"'<>]*)?"#, options: [.regularExpression, .caseInsensitive]) {
            return String(text[match])
        }

        if let match = text.range(of: #"[^"']+?\.gif(?:\?[^"']*)?"#, options: [.regularExpression, .caseInsensitive]) {
            return String(text[match])
        }

        return nil
    }

    private static func normalizedURL(_ value: String, relativeTo baseURL: URL) -> URL? {
        var candidate = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if candidate.hasPrefix("//") {
            candidate = "https:" + candidate
        }
        return URL(string: candidate, relativeTo: baseURL)?.absoluteURL
    }

    private static func directItem(source: String, gifURL: String, note: String) -> GifItem {
        let url = URL(string: gifURL)
        return GifItem(
            source: source,
            cdnURL: gifURL,
            title: url?.deletingPathExtension().lastPathComponent ?? url?.host(percentEncoded: false) ?? "GIF",
            state: .ready,
            note: note
        )
    }
}
