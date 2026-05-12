import Foundation

@MainActor
final class GifLibrary: ObservableObject {
    @Published var items: [GifItem] = [] {
        didSet { save() }
    }

    private let defaultsKey = "gifbar.gif-library.v1"
    private let legacyDefaultsKey = "santa.gif-library.v1"

    init() {
        load()
    }

    func add(_ item: GifItem) {
        if let cdnURL = item.cdnURL, let existingIndex = items.firstIndex(where: { $0.cdnURL == cdnURL }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
            return
        }

        items.insert(item, at: 0)
    }

    func resolveAndAdd(_ value: String?) async -> GifItem? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let item = GiphyConverter.unresolvedItem(from: value)
            add(item)
            return item
        }

        let item = await GiphyConverter.resolveItem(from: value)
        add(item)
        return item
    }

    func update(_ item: GifItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
    }

    func remove(_ item: GifItem) {
        items.removeAll { $0.id == item.id }
    }

    func removeAll() {
        items.removeAll()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) ?? UserDefaults.standard.data(forKey: legacyDefaultsKey) else { return }
        do {
            items = try JSONDecoder().decode([GifItem].self, from: data)
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
