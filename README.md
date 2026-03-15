# AI Rephrase

A macOS menu bar app that rephrases selected text using Apple Intelligence. Works in any application — select text, hit a shortcut, get a polished version instantly pasted back.

<p align="center">
  <img src="screenshots/rephrase-result.png" width="320" alt="Rephrase result">
  &nbsp;&nbsp;
  <img src="screenshots/history.png" width="320" alt="History window">
</p>

## Why?

Writing in a non-native language means constantly second-guessing your phrasing. AI Rephrase fixes that — select awkward text anywhere (Slack, email, docs, IDE), press one shortcut, and it gets rephrased in-place using Apple's on-device language model. No API keys, no cloud, no copy-pasting into ChatGPT.

## How It Works

1. Select text in **any** application
2. Press **⌥⇧⌘R** (customizable)
3. App copies the selection, sends it to Apple Intelligence for rephrasing
4. Rephrased text is automatically pasted back

Everything happens on-device through Apple's `FoundationModels` framework — your text never leaves your Mac.

## Features

- **Works everywhere** — any app that supports text selection
- **One shortcut** — ⌥⇧⌘R (customizable in the menu bar popover)
- **On-device AI** — uses Apple Intelligence, no API keys, no internet required
- **Persistent history** — browse all past rephrasings with search
- **Copy original or rephrased** — from the history window
- **Menu bar app** — no dock icon, stays out of your way
- **Native macOS** — SwiftUI, zero external API dependencies

## Requirements

- **macOS 26 (Tahoe)** or later
- **Apple Silicon** Mac (M1 or later)
- **Apple Intelligence** must be enabled

### Enabling Apple Intelligence

1. Open **System Settings → Apple Intelligence & Siri**
2. Make sure Apple Intelligence is turned **on**
3. If you see a language mismatch warning — set both Mac language and Siri language to **English (US)**
4. Wait for the on-device model to download (may take a few minutes on first setup)
5. Grant **Accessibility** permission to AiRephrase in **System Settings → Privacy & Security → Accessibility**

## Install

### Homebrew

```bash
brew install --cask alexrett/tap/ai-rephrase
```

### Download

Grab the latest `AiRephrase.dmg` from [Releases](https://github.com/alexrett/rephrase/releases).

### Build from Source

```bash
git clone https://github.com/alexrett/rephrase.git
cd rephrase
swift build -c release --arch arm64 --arch x86_64
```

## License

MIT
