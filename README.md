# SuperReviews

macOS menu bar app for tracking GitHub pull requests that need your review<br>
<img width="300" alt="Captura de Tela 2026-01-29 às 17 59 06" src="https://github.com/user-attachments/assets/2f672f94-baee-4325-9b9b-55364902cfe5" />
<img width="300" alt="Captura de Tela 2026-01-29 às 18 02 05" src="https://github.com/user-attachments/assets/97a59792-0b7c-42b6-89ae-d8d932e46ae1" />
<img width="300" alt="Captura de Tela 2026-01-29 às 18 04 52" src="https://github.com/user-attachments/assets/7943ec7c-40a8-4b68-ab11-41809d4ba98b" />

## What it does


- Shows PRs waiting for your review in the menu bar
- Polls GitHub API every 60 seconds
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
