import Foundation

struct GifItem: Identifiable, Codable, Equatable {
    enum State: String, Codable {
        case ready
        case needsUpload
        case invalid
    }

    var id: UUID
    var source: String
    var cdnURL: String?
    var title: String
    var slackText: String
    var state: State
    var createdAt: Date
    var note: String?

    init(
        id: UUID = UUID(),
        source: String,
        cdnURL: String?,
        title: String,
        slackText: String = "gif",
        state: State,
        createdAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.source = source
        self.cdnURL = cdnURL
        self.title = title
        self.slackText = slackText
        self.state = state
        self.createdAt = createdAt
        self.note = note
    }

    var slackLink: String? {
        guard let cdnURL else { return nil }
        let label = slackText.trimmingCharacters(in: .whitespacesAndNewlines)
        return "<\(cdnURL)|\(label.isEmpty ? "gif" : label)>"
    }
}
