# AI Rephrase

A macOS menu bar app that rephrases selected text using on-device AI. Works in any application — select text, hit a shortcut, get a polished version instantly pasted back.

Supports Ollama (recommended) and Apple Intelligence. Everything runs locally — no API keys, no cloud.

<p align="center">
  <img src="screenshots/apple.png" width="320" alt="Apple Intelligence backend">
  &nbsp;&nbsp;
  <img src="screenshots/ollama.png" width="320" alt="Ollama backend">
</p>

<p align="center">
  <img src="screenshots/rephrase-result.png" width="320" alt="Rephrase result">
  &nbsp;&nbsp;
  <img src="screenshots/history.png" width="320" alt="History window">
</p>

## Why?

Writing in a non-native language means constantly second-guessing your phrasing. AI Rephrase fixes that — select awkward text anywhere (Slack, email, docs, IDE), press one shortcut, and it gets rephrased in-place. No API keys, no cloud, no copy-pasting into ChatGPT.

## How It Works

1. Select text in **any** application
2. Press **⌥⇧⌘R** (customizable)
3. App copies the selection, sends it to on-device AI for rephrasing
4. Rephrased text is automatically pasted back

## Features

- **Works everywhere** — any app that supports text selection
- **One shortcut** — ⌥⇧⌘R (customizable in the menu bar popover)
- **Dual backend** — Apple Intelligence (on-device) or Ollama (local models)
- **Auto-detection** — picks the best available backend, manual switch anytime
- **Ollama model picker** — choose any locally installed model (gemma3, llama, etc.)
- **Persistent history** — browse all past rephrasings with search
- **Copy original or rephrased** — from the history window
- **Menu bar app** — no dock icon, stays out of your way
- **Native macOS** — SwiftUI, zero external API dependencies

## Backends

| Backend | Recommendation |
|---|---|
| **Ollama** | **Recommended.** Works with any language, reliable results. Use `gemma3:12b` or similar. |
| **Apple Intelligence** | Limited. English only, ~3B model struggles with rephrasing (tends to answer questions instead), frequently triggers false-positive content filters. |

You can switch between backends at any time via the dropdown in the menu bar popover.

## Requirements

- **macOS 26 (Tahoe)** or later
- **Apple Silicon** Mac (M1 or later)
- **Ollama** running locally (recommended) — or **Apple Intelligence** enabled

### Setting up Ollama (recommended)

```bash
brew install ollama
ollama pull gemma3:12b
ollama serve
```

AI Rephrase will detect Ollama automatically on launch.

### Apple Intelligence (limited)

The built-in Apple model is small (~3B params). It only supports English, may refuse to process some text, and sometimes answers questions instead of rephrasing them. If you still want to use it:

1. Open **System Settings → Apple Intelligence & Siri**
2. Turn Apple Intelligence **on**
3. Set Mac language and Siri language to **English (US)**
4. Wait for the on-device model to download

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
