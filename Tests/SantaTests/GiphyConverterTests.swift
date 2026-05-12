import Testing
import Foundation
@testable import GifBar

@Test func convertsVersionedGiphyMediaURLToDirectCDNURL() {
    let item = GiphyConverter.makeItem(
        from: "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbTg5bmM5YW94NHVtcnVhMWFjdHIwcWYzNHBuZ2dlZXFmaHlwOTcybyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Ke97StdZZrPRbefL6D/giphy.gif"
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif")
}

@Test func convertsDraggedGiphyWebPAssetToGIFCDNURL() {
    let item = GiphyConverter.makeItem(
        from: "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbTg5bmM5YW94NHVtcnVhMWFjdHIwcWYzNHBuZ2dlZXFmaHlwOTcybyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Ke97StdZZrPRbefL6D/giphy.webp"
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif")
}

@Test func convertsShortGiphyWebPAssetToGIFCDNURL() {
    let item = GiphyConverter.makeItem(
        from: "https://i.giphy.com/Ke97StdZZrPRbefL6D.webp"
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif")
}

@Test func preservesDirectHostedGIFURLs() {
    let item = GiphyConverter.makeItem(
        from: "https://media.tenor.com/2roX3uxz_68AAAAC/cat-space.gif"
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://media.tenor.com/2roX3uxz_68AAAAC/cat-space.gif")
}

@Test func extractsDirectGIFURLFromMessyDraggedText() {
    let item = GiphyConverter.makeItem(
        from: #"Phone Whodis <a href="https://media.tenor.com/2roX3uxz_68AAAAC/cat-space.gif">link</a>"#
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://media.tenor.com/2roX3uxz_68AAAAC/cat-space.gif")
}

@Test func localGIFFilesNeedUploader() {
    let item = GiphyConverter.makeItem(
        from: "file:///Users/example/Desktop/reaction.gif"
    )

    #expect(item.state == .needsUpload)
    #expect(item.cdnURL == nil)
}

@Test func resolvesDirectGIFFromGenericHostedPageHTML() throws {
    let pageURL = try #require(URL(string: "https://example.com/reaction"))
    let item = try #require(
        GiphyConverter.resolveHTMLPage(
            source: "https://example.com/reaction",
            html: #"""
            <html>
              <head>
                <meta property="og:image" content="https://cdn.example.com/reaction.gif?size=medium">
              </head>
            </html>
            """#,
            finalURL: pageURL
        )
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://cdn.example.com/reaction.gif?size=medium")
    #expect(item.note == "Resolved direct GIF from hosted page.")
}

@Test func resolvesEscapedDirectGIFFromPageHTML() throws {
    let pageURL = try #require(URL(string: "https://example.com/reaction"))
    let item = try #require(
        GiphyConverter.resolveHTMLPage(
            source: "https://example.com/reaction",
            html: #"{"url":"https:\/\/media.example.com\/asset\/reaction.gif"}"#,
            finalURL: pageURL
        )
    )

    #expect(item.state == .ready)
    #expect(item.cdnURL == "https://media.example.com/asset/reaction.gif")
}
