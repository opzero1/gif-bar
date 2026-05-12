import Foundation
import UniformTypeIdentifiers

enum DropReader {
    static let supportedTypes = [
        UTType.url.identifier,
        UTType.fileURL.identifier,
        UTType.plainText.identifier,
        UTType.text.identifier,
        UTType.html.identifier,
        UTType.data.identifier,
        UTType.item.identifier
    ]

    static func readFirstValue(from providers: [NSItemProvider], completion: @escaping @Sendable (String?) -> Void) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSURL.self) {
                provider.loadObject(ofClass: NSURL.self) { item, _ in
                    completion((item as? URL)?.absoluteString ?? (item as? NSURL)?.absoluteString)
                }
                return true
            }

            if provider.canLoadObject(ofClass: NSString.self) {
                provider.loadObject(ofClass: NSString.self) { item, _ in
                    completion((item as? String) ?? (item as? NSString).map(String.init))
                }
                return true
            }

            for typeIdentifier in preferredTypeIdentifiers(for: provider) {
                provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                    completion(stringValue(from: item))
                }
                return true
            }
        }

        completion(nil)
        return false
    }

    private static func preferredTypeIdentifiers(for provider: NSItemProvider) -> [String] {
        let priority = [
            UTType.fileURL.identifier,
            UTType.url.identifier,
            UTType.plainText.identifier,
            UTType.text.identifier,
            UTType.html.identifier,
            "public.utf8-plain-text",
            "public.url-name",
            UTType.data.identifier
        ]

        let registered = provider.registeredTypeIdentifiers
        return priority.filter { registered.contains($0) } + registered.filter { !priority.contains($0) }
    }

    private static func stringValue(from item: NSSecureCoding?) -> String? {
        if let url = item as? URL {
            return url.absoluteString
        }

        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }

        if let string = item as? String {
            return string
        }

        if let string = item as? NSString {
            return String(string)
        }

        return nil
    }
}
