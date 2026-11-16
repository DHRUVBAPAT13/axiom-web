# Axiom — A Web Browser Engine From Scratch in C++20

A lightweight, standards-compliant, hardware-accelerated web browser engine built from first principles in **C++20**. Axiom implements the full browser rendering pipeline—from raw POSIX sockets and TLS 1.3 networking to WHATWG HTML5 tokenization, CSS3 cascade resolution, multi-context box layout, GPU-backed rasterization, and embedded JavaScript execution—validated against W3C/WHATWG acid and visual regression tests.

---

## Architecture Pipeline

```text
  [ URL / User Input ]
           │
           ▼
┌─────────────────────┐
│  1. Network Stack   │  POSIX Sockets + OpenSSL (HTTP/1.1, TLS 1.3, Chunked, Redirects)
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  2. HTML5 Engine    │  WHATWG State-Machine Lexer ──► Stack-Based DOM Tree (Arena-Allocated)
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  3. CSS & Cascade   │  CSS3 Parser ──► Rule Indexing ──► Specificity & Inheritance ──► Styled Tree
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  4. Layout Engine   │  Box Model (BFC/IFC), Flexbox, CSS Grid, Positioning, FreeType Text Metrics
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│  5. Paint & Render  │  Z-Index Display List ──► Cairo / Skia Rasterizer ──► SDL2 Window
└──────────┬──────────┘
           ▲
           │ (DOM Mutation / Dirty-Bit Reflow)
┌──────────┴──────────┐
│  6. JS & Event Loop │  QuickJS Runtime + C++ DOM Bindings + Macrotask/Microtask Queues
└─────────────────────┘
```

---

## Core Subsystems

### 1. Network & Resource Loader (`src/net/`)
* **RFC 3986 URL Parser:** Parses schemes, hosts, default/explicit ports, paths, query strings, and fragments, plus relative path resolution (`../`, `./`, protocol-relative `//`).
* **Transport & Security:** RAII POSIX TCP sockets wrapped in OpenSSL for TLS 1.3 handshakes, Server Name Indication (SNI), and X.509 certificate verification.
* **HTTP/1.1 Client:** Handles request serialization, case-insensitive header parsing, fixed `Content-Length` reads, hex-framed `Transfer-Encoding: chunked` decoding, redirect loops (`301`, `302`, `307`, `308`), and in-memory asset caching.

### 2. HTML5 Parser & Arena-Backed DOM (`src/html/`)
* **WHATWG State-Machine Tokenizer:** Single-pass lexer handling tags, quoted/unquoted attributes, self-closing tags, comments, `RAWTEXT` states (`<script>`, `<style>`), UTF-8 stream normalization, and named/numeric HTML character entity decoding (`&amp;`, `&#x1F600;`).
* **Stack-Based Tree Builder:** Constructs the DOM tree using an open-elements stack with implicit tag insertion (`<html>`, `<head>`, `<body>`), void elements (`<img>`, `<br>`, `<meta>`, `<link>`), and error recovery auto-closing rules for malformed markup (`<p>`, `<li>`).
* **Arena Memory Management:** Custom bump **Arena Allocator** storing DOM and Layout nodes in contiguous cache-friendly blocks with $O(1)$ page teardown and zero leaks.

### 3. CSS3 Engine & Style Resolution (`src/css/`)
* **CSS3 Tokenizer & Parser:** Recursive-descent parser supporting rulesets, tag/class/ID selectors, descendant (` `) and child (`>`) combinators, universal (`*`) selectors, and property declarations.
* **Cascade & Specificity:** Evaluates `(ID, Class, Tag)` specificity tuples, `!important` overrides, source order, CSS custom properties (`--var`), and inherited properties (`color`, `font-size`, `font-family`) to attach a `ComputedStyle` struct to every DOM node.

### 4. Multi-Context Layout Engine (`src/layout/`)
* **Layout Tree & Box Model:** Separates `LayoutBox` geometry from the DOM, filtering `display: none` and generating anonymous block/inline wrapper boxes.
* **Block & Inline Formatting Contexts (BFC/IFC):** Computes top-down width constraints, vertical margin collapsing, multi-line text wrapping via **FreeType** glyph advance metrics, and bottom-up heights.
* **Modern Layout Modes:** Supports `position: relative/absolute/fixed`, **CSS Flexbox** (main/cross axis alignment, `flex-grow`, `flex-shrink`), and **CSS Grid** (`fr` fractional units, explicit row/column tracks).

### 5. Paint Pipeline & Interactive Window (`src/gfx/`)
* **Display List Generation:** Walks the layout tree in CSS stacking-context paint order (`z-index`, backgrounds, borders, rounded corners, images, foreground text) to emit flat drawing operations.
* **Rasterization & Windowing:** Uses **Cairo** + **FreeType** + `stb_image` to render primitives into an **SDL2** window supporting smooth scrolling, viewport resizing, hover states, and coordinate hit-testing for clickable links.

### 6. JavaScript Runtime & Event Loop (`src/js/`)
* **Embedded QuickJS Engine:** Integrates **QuickJS** (ES2023 compliant) via a C++ wrapper layer exposing `window`, `document.getElementById`, `querySelector`, `createElement`, `appendChild`, `innerHTML`, `style`, and `addEventListener`.
* **Incremental Reflow:** DOM mutations flip dirty flags (`needs_style_recalc`, `needs_layout`), scheduling minimal re-layout and repaint passes alongside `setTimeout` macrotask queues.

### 7. Conformance & Visual Regression Testing (`tests/`)
* **Unit Test Suite (GoogleTest):** Deterministic assertions verifying URL resolution, chunked HTTP parsing, malformed HTML tree recovery, CSS specificity, and exact `(x, y, width, height)` layout bounding boxes.
* **Headless Reftest Runner:** Automated test harness rendering HTML test cases to PNGs and running pixel-by-pixel diffs against reference outputs for **Acid1**, **Acid2**, and selected **Web Platform Tests (WPT)**.

---

## Project Structure

```text
axiom/
├── CMakeLists.txt
├── third_party/
│   ├── quickjs/          # Embedded ES2023 JS engine
│   └── stb/              # stb_image.h & stb_image_write.h
├── src/
│   ├── main.cpp          # CLI entry point (--dump-dom, --render-png, interactive GUI)
│   ├── mem/              # Custom bump Arena Allocator
│   ├── net/              # URL parser, POSIX TCP, OpenSSL TLS, HTTP/1.1 client
│   ├── html/             # UTF-8 decoder, entities, WHATWG tokenizer, DOM, TreeBuilder
│   ├── css/              # CSS3 tokenizer, parser, selector matching, cascade
│   ├── layout/           # Box model, BFC/IFC, Flexbox, Grid, FreeType text shaping
│   ├── gfx/              # Stacking contexts, Display List, Cairo/SDL2 renderer
│   └── js/               # QuickJS bindings, DOM wrappers, Event Loop
└── tests/
    ├── unit/             # GoogleTest suites (net, html, css, layout)
    └── reftests/         # Acid1, Acid2, and WPT visual regression runner
```

---

## Tech Stack & Dependencies

* **Language & Build:** C++20 (`-std=c++20`), CMake (3.20+), Ninja
* **Sanitizers:** AddressSanitizer (`-fsanitize=address`) & UndefinedBehaviorSanitizer (`-fsanitize=undefined`)

| Dependency | Role | Installation (Ubuntu / WSL2) |
| :--- | :--- | :--- |
| **OpenSSL** | TLS 1.3 encryption & X.509 certificate verification | `sudo apt install libssl-dev` |
| **FreeType** | TrueType font parsing, glyph metrics & rasterization | `sudo apt install libfreetype-dev` |
| **Cairo** | Anti-aliased 2D vector drawing, borders & text | `sudo apt install libcairo2-dev` |
| **SDL2** | Cross-platform windowing & input event loop | `sudo apt install libsdl2-dev` |
| **QuickJS** | Embedded ES2023 JavaScript interpreter | Vendored in `third_party/quickjs` |
| **stb_image** | PNG/JPEG decoding & headless screenshot export | Vendored in `third_party/stb` |
| **GoogleTest** | C++ unit testing & layout box assertions | Fetched automatically via CMake |

---

## Building & Running

### Build (Debug with ASan & UBSan)
```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build
```

### Run Unit Tests
```bash
ctest --test-dir build --output-on-failure
```

### Usage Modes
```bash
# 1. Fetch a live HTTPS page and print its parsed HTML5 DOM tree
./build/axiom https://example.com --dump-dom

# 2. Render a local or remote page headlessly to a PNG image
./build/axiom https://example.com --render-png output.png

# 3. Launch the interactive SDL2 browser window
./build/axiom https://example.com
```

---

## 250-Day Development Roadmap

| Phase | Days | Subsystem | Exit Milestone |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **1–30** | **Networking & HTML5 Parser** | Fetch live HTTPS pages via CLI and dump valid indented DOM trees (`--dump-dom`). |
| **Phase 2** | **31–60** | **CSS3 Parser & Style Cascade** | Resolve stylesheets, specificity, and inheritance into `ComputedStyle` trees. |
| **Phase 3** | **61–100** | **Box Model & Block/Inline Layout** | Compute full layout coordinates, wrap text via FreeType, pass **Acid1** box assertions, and export PNGs. |
| **Phase 4** | **101–135** | **SDL2 Window, Display List & Paint** | Interactive desktop window with `z-index` painting, scrolling, link clicking, and PNG/JPEG images. |
| **Phase 5** | **136–175** | **Flexbox, CSS Grid & Positioning** | Implement `position: absolute/fixed`, Flexbox, and Grid layouts; pass **Acid2** visual inspection. |
| **Phase 6** | **176–215** | **QuickJS & DOM Event Loop** | Execute interactive JavaScript (`addEventListener`, DOM mutations, `setTimeout`) with dirty-bit reflows. |
| **Phase 7** | **216–235** | **Arena Allocator & Async Pipeline** | Migrate DOM/Layout nodes to a custom bump arena and load assets concurrently on a worker pool. |
| **Phase 8** | **236–250** | **WPT Reftest Suite & Profiling** | Automated visual regression runner reporting pass rates across curated WPT layout suites. |