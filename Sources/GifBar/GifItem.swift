import Foundation

struct GifItem: Identifiable, Codable, Equatable {
    var id: UUID
    var source: String
    var cdnURL: String?
    var title: String
    var createdAt: Date
    var note: String?
    var giphyID: String?
    var previewURL: String?
    var stillURL: String?
    var username: String?
    var displayName: String?
    var rating: String?
    var sourceTLD: String?
    var importDateTime: String?
    var tags: [String]?

    init(
        id: UUID = UUID(),
        source: String,
        cdnURL: String?,
        title: String,
        createdAt: Date = Date(),
        note: String? = nil,
        giphyID: String? = nil,
        previewURL: String? = nil,
        stillURL: String? = nil,
        username: String? = nil,
        displayName: String? = nil,
        rating: String? = nil,
        sourceTLD: String? = nil,
        importDateTime: String? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.source = source
        self.cdnURL = cdnURL
        self.title = title
        self.createdAt = createdAt
        self.note = note
        self.giphyID = giphyID
        self.previewURL = previewURL
        self.stillURL = stillURL
        self.username = username
        self.displayName = displayName
        self.rating = rating
        self.sourceTLD = sourceTLD
        self.importDateTime = importDateTime
        self.tags = tags
    }
}
