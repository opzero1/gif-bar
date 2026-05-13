import Foundation
import Testing
@testable import GifBar

@Test func decodesGiphySearchResultIntoRecentItemMetadata() throws {
    let data = Data(
        #"""
        {
          "data": [
            {
              "type": "gif",
              "id": "Ke97StdZZrPRbefL6D",
              "url": "https://giphy.com/gifs/example-Ke97StdZZrPRbefL6D",
              "slug": "example-Ke97StdZZrPRbefL6D",
              "bitly_gif_url": "https://gph.is/example",
              "bitly_url": "https://gph.is/example",
              "embed_url": "https://giphy.com/embed/Ke97StdZZrPRbefL6D",
              "username": "giphy",
              "source": "",
              "title": "Example GIF",
              "rating": "g",
              "content_url": "",
              "source_tld": "giphy.com",
              "source_post_url": "",
              "import_datetime": "2026-05-12 01:23:45",
              "trending_datetime": "0000-00-00 00:00:00",
              "images": {
                "original": {
                  "url": "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/giphy.gif",
                  "width": "480",
                  "height": "360",
                  "size": "1000000"
                },
                "fixed_height": {
                  "url": "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif?cid=test&rid=200.gif&ct=g",
                  "width": "267",
                  "height": "200",
                  "size": "250000"
                },
                "fixed_height_small": {
                  "url": "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/100.gif?cid=test&rid=100.gif&ct=g",
                  "width": "133",
                  "height": "100",
                  "size": "100000"
                },
                "fixed_height_small_still": {
                  "url": "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/100_s.gif?cid=test&rid=100_s.gif&ct=g",
                  "width": "133",
                  "height": "100"
                }
              },
              "user": {
                "avatar_url": "https://media.giphy.com/avatar.gif",
                "banner_url": "",
                "profile_url": "https://giphy.com/giphy",
                "username": "giphy",
                "display_name": "GIPHY"
              },
              "tags": ["example", "reaction"],
              "alt_text": "An example reaction."
            }
          ],
          "meta": {
            "status": 200,
            "msg": "OK",
            "response_id": "abc"
          }
        }
        """#.utf8
    )

    let response = try JSONDecoder().decode(GiphySearchResponse.self, from: data)
    let result = try #require(response.data.first)
    let item = try #require(result.makeLibraryItem())

    #expect(item.giphyID == "Ke97StdZZrPRbefL6D")
    #expect(item.cdnURL == "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif?cid=test&rid=200.gif&ct=g")
    #expect(item.previewURL == "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/100.gif?cid=test&rid=100.gif&ct=g")
    #expect(item.stillURL == "https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/100_s.gif?cid=test&rid=100_s.gif&ct=g")
    #expect(item.displayName == "GIPHY")
    #expect(item.rating == "g")
    #expect(item.sourceTLD == "giphy.com")
    #expect(item.importDateTime == "2026-05-12 01:23:45")
    #expect(item.tags == ["example", "reaction"])
    #expect(item.note == "An example reaction.")
}
