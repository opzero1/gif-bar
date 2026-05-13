# GifBar

Small native macOS 14+ menu bar helper for searching Giphy and copying Slack-friendly CDN GIF links.

## Use

Install with Homebrew:

```sh
brew tap opzero1/tap
brew install --cask gifbar
```

Or build locally:

1. Build the app:

   ```sh
   ./scripts/package-app.sh
   ```

2. Open `dist/GifBar.app`.
3. Click the GifBar icon in the macOS menu bar.
4. Add a Giphy API key when prompted. GifBar also reads `GIPHY_API_KEY` when launched from a shell.
5. Search Giphy.
6. Click a GIF result to copy its CDN GIF URL:

   ```text
   https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif?cid=...&rid=200.gif&ct=g
   ```

Clicked GIFs are saved in Recent with metadata from Giphy, including title, creator, rating, source domain, and tags when available.

## Development

```sh
swift test
swift build
swift run GifBar
```
