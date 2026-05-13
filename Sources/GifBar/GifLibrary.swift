import Foundation

@MainActor
final class GifLibrary: ObservableObject {
    @Published var items: [GifItem] = [] {
        didSet { save() }
    }

    private let defaultsKey = "gifbar.gif-library.v1"
    init() {
        load()
    }

    @discardableResult
    func add(_ item: GifItem) -> GifItem {
        if let giphyID = item.giphyID, let existingIndex = items.firstIndex(where: { $0.giphyID == giphyID }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
            return existing
        }

        if let cdnURL = item.cdnURL, let existingIndex = items.firstIndex(where: { $0.cdnURL == cdnURL }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
            return existing
        }

        items.insert(item, at: 0)
        return item
    }

    func remove(_ item: GifItem) {
        items.removeAll { $0.id == item.id }
    }

    func removeAll() {
        items.removeAll()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            items = try JSONDecoder().decode([GifItem].self, from: data)
                .filter { $0.cdnURL != nil }
        } catch {
            items = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            assertionFailure("Failed to save GIF library: \(error)")
        }
    }
}
