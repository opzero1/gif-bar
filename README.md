# GifBar

Small native macOS 14+ menu bar helper for turning GIF links into Slack-friendly CDN links.

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
4. Drag in a Giphy media URL, Giphy page URL, or direct hosted `.gif` URL.
5. Click `Copy URL` for the raw CDN URL, or `Copy Slack Link` for Slack mrkdwn:

   ```text
   <https://media0.giphy.com/media/Ke97StdZZrPRbefL6D/200.gif|gif>
   ```

Local GIF files are detected, but they cannot become Slack-previewable links until a CDN uploader is configured.

## Development

```sh
swift test
swift build
swift run GifBar
```
