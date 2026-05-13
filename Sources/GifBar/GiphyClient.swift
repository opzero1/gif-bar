import Foundation

enum GiphyClientError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidResponse
    case apiMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Add a Giphy API key to search."
        case .invalidResponse:
            "Giphy returned an unreadable response."
        case .apiMessage(let message):
            message
        }
    }
}

struct GiphyClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func search(query: String, apiKey: String, limit: Int = 24) async throws -> [GiphyGIF] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else { throw GiphyClientError.missingAPIKey }
        guard !trimmedQuery.isEmpty else { return [] }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.giphy.com"
        components.path = "/v1/gifs/search"
        components.queryItems = [
            URLQueryItem(name: "api_key", value: trimmedKey),
            URLQueryItem(name: "q", value: trimmedQuery),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "rating", value: "pg-13"),
            URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "bundle", value: "messaging_non_clips")
        ]

        guard let url = components.url else { throw GiphyClientError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(GiphySearchResponse.self, from: data)

        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw GiphyClientError.apiMessage(decoded.meta.msg)
        }

        guard decoded.meta.status == 200 else {
            throw GiphyClientError.apiMessage(decoded.meta.msg)
        }

        return decoded.data.filter { $0.cdnURL != nil }
    }
}

struct GiphySearchResponse: Decodable {
    let data: [GiphyGIF]
    let meta: GiphyMeta
}

struct GiphyMeta: Decodable {
    let status: Int
    let msg: String
}

struct GiphyGIF: Identifiable, Decodable, Equatable {
    let type: String?
    let id: String
    let url: String
    let slug: String?
    let bitlyGIFURL: String?
    let bitlyURL: String?
    let embedURL: String?
    let username: String?
    let source: String?
    let title: String
    let rating: String?
    let contentURL: String?
    let sourceTLD: String?
    let sourcePostURL: String?
    let importDateTime: String?
    let trendingDateTime: String?
    let images: GiphyImages
    let user: GiphyUser?
    let tags: [String]?
    let altText: String?

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case url
        case slug
        case bitlyGIFURL = "bitly_gif_url"
        case bitlyURL = "bitly_url"
        case embedURL = "embed_url"
        case username
        case source
        case title
        case rating
        case contentURL = "content_url"
        case sourceTLD = "source_tld"
        case sourcePostURL = "source_post_url"
        case importDateTime = "import_datetime"
        case trendingDateTime = "trending_datetime"
        case images
        case user
        case tags
        case altText = "alt_text"
    }

    var cdnURL: String? {
        images.fixedHeight?.url ?? images.original?.url
    }

    var previewURL: String? {
        images.fixedHeightSmall?.url ?? images.fixedWidthSmall?.url ?? cdnURL
    }

    var stillURL: String? {
        images.fixedHeightSmallStill?.url ?? images.fixedWidthSmallStill?.url ?? images.fixedHeightStill?.url
    }

    var displayCreator: String? {
        if let displayName = user?.displayName, !displayName.isEmpty {
            return displayName
        }

        if let username, !username.isEmpty {
            return "@\(username)"
        }

        return nil
    }

    func makeLibraryItem() -> GifItem? {
        guard let cdnURL else { return nil }

        return GifItem(
            source: url,
            cdnURL: cdnURL,
            title: title.isEmpty ? "Giphy GIF" : title,
            note: altText?.isEmpty == false ? altText : "Copied from Giphy search.",
            giphyID: id,
            previewURL: previewURL,
            stillURL: stillURL,
            username: username,
            displayName: user?.displayName,
            rating: rating,
            sourceTLD: sourceTLD,
            importDateTime: importDateTime,
            tags: tags
        )
    }
}

struct GiphyImages: Decodable, Equatable {
    let original: GiphyImage?
    let fixedHeight: GiphyImage?
    let fixedHeightStill: GiphyImage?
    let fixedHeightSmall: GiphyImage?
    let fixedHeightSmallStill: GiphyImage?
    let fixedWidthSmall: GiphyImage?
    let fixedWidthSmallStill: GiphyImage?

    enum CodingKeys: String, CodingKey {
        case original
        case fixedHeight = "fixed_height"
        case fixedHeightStill = "fixed_height_still"
        case fixedHeightSmall = "fixed_height_small"
        case fixedHeightSmallStill = "fixed_height_small_still"
        case fixedWidthSmall = "fixed_width_small"
        case fixedWidthSmallStill = "fixed_width_small_still"
    }
}

struct GiphyImage: Decodable, Equatable {
    let url: String?
    let width: String?
    let height: String?
    let size: String?
}

struct GiphyUser: Decodable, Equatable {
    let avatarURL: String?
    let bannerURL: String?
    let profileURL: String?
    let username: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
        case bannerURL = "banner_url"
        case profileURL = "profile_url"
        case username
        case displayName = "display_name"
    }
}
