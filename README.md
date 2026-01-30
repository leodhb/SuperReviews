# Nag

**Stop ignoring PR reviews.**

macOS menu bar app for tracking GitHub pull requests that need your review<br>
<img width="300" alt="Captura de Tela 2026-01-29 às 18 26 42" src="https://github.com/user-attachments/assets/8917480d-ee79-4d01-b0ce-6e9953c02c87" />
<img width="300" alt="Captura de Tela 2026-01-29 às 18 02 05" src="https://github.com/user-attachments/assets/97a59792-0b7c-42b6-89ae-d8d932e46ae1" />
<img width="300" alt="Captura de Tela 2026-01-29 às 18 04 52" src="https://github.com/user-attachments/assets/7943ec7c-40a8-4b68-ab11-41809d4ba98b" />


## What it does


- Shows PRs waiting for your review in the menu bar
- Polls GitHub API every 60 seconds
- Opens PRs directly in your browser
- Monitor specific repositories or all at once

## Requirements

- macOS 13.5+
- A GitHub account

## Download

Get the latest release from the [Releases](https://github.com/leodhb/Nag/releases) page.

## Building from source

```bash
git clone https://github.com/leodhb/Nag.git
cd Nag
open Nag.xcodeproj
```

Build with `Cmd+B`, run with `Cmd+R`.

**Note:** The app uses GitHub's Device Flow for authentication - no configuration needed!

## Setup

1. Launch the app
2. Click the menu bar icon → **"Connect with GitHub"**
3. Authorize the app in your browser (you can skip "Organization access")
4. Done! The app will start monitoring your PRs
5. (Optional) Add specific repos in **Settings → Manage Monitored Repositories**

**Note:** Nag monitors repositories you have access to. For private organization repositories that need explicit permission, add them manually in settings.

## License

MIT
