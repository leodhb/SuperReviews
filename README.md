# SuperReviews

macOS menu bar app for tracking GitHub pull requests that need your review.

## What it does

- Shows PRs waiting for your review in the menu bar
- Polls GitHub API every 5 minutes
- Opens PRs directly in your browser
- Filter by repositories if you want

## Requirements

- macOS 13.5+
- GitHub personal access token with `repo` scope

## Download

Get the latest release from the [Releases](https://github.com/leodhb/SuperReviews/releases) page.

## Building from source

```bash
git clone https://github.com/leodhb/SuperReviews.git
cd SuperReviews
open SuperReviews.xcodeproj
```

Build with `Cmd+B`, run with `Cmd+R`.

## Setup

1. Launch the app
2. Click the menu bar icon
3. Add your GitHub token
4. (Optional) Filter specific repos: `owner/repo1, owner/repo2`

## License

MIT
