import SwiftUI

@MainActor
final class GifBarState: ObservableObject {
    @Published var showsAPIKeySettings = false
}
