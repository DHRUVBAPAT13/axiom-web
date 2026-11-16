# Phase 1: Networking & HTML5 Parser (Days 1–30)

## Tech Stack & System Requirements

- **Language:** C++20 (`-std=c++20`)
- **Build System:** CMake (3.20+) & Ninja
- **Sanitizers & Debugging:** AddressSanitizer (`-fsanitize=address`), UndefinedBehaviorSanitizer (`-fsanitize=undefined`), GDB / LLDB
- **Operating Environment:** Linux (WSL Ubuntu / native Linux) for POSIX sockets (`<sys/socket.h>`, `<netdb.h>`)
- **Target Timeline:** Days 1–30 (~40 hours across thirty 80-minute daily sessions)

---

## Daily Working Procedure (The 80-Minute Cadence)

Execute every daily session using a strict three-block workflow so you never lose momentum between days:

1. **Test & Spec Review (Minutes 0–15):**
   - Check the WHATWG HTML5 / RFC 9112 (HTTP/1.1) spec section for the current step.
   - Write a failing unit test first (e.g., parsing a malformed unclosed `<p>` tag or chunked HTTP response) before touching implementation files.
2. **Core Implementation (Minutes 15–70):**
   - Write clean, modular C++20 code inside `src/net/` or `src/html/`.
   - Keep components decoupled: the HTML tokenizer must consume `std::string_view` streams without knowing anything about sockets or URLs.
3. **Sanitize, Verify & Checkpoint (Minutes 70–80):**
   - Compile and run all unit tests with ASan and UBSan enabled (`ctest --output-on-failure`).
   - Commit working increments to Git and write a 1-line `NEXT:` note at the top of your scratchpad specifying the exact file and function to open tomorrow.

---

## Phase 1: Networking & HTML5 Parser (10 Discrete Steps)

### Step 1: Project Scaffolding, CMake & Sanitizers (Days 1–2)

- **Directory Layout:**
  ```text
  axiom/
  ├── CMakeLists.txt
  ├── src/
  │   ├── main.cpp
  │   ├── net/      (URL, TCP, TLS, HTTP)
  │   └── html/     (Entities, Tokenizer, DOM, TreeBuilder)
  └── tests/
      ├── test_net.cpp
      └── test_html.cpp
  ```
- **Deliverable:** Configure `CMakeLists.txt` with C++20, strict compiler warnings (`-Wall -Wextra -Wpedantic`), ASan/UBSan flags for Debug builds, and GoogleTest integration via `FetchContent`.

### Step 2: RFC 3986 URL Parser & Relative Resolver (Days 3–5)

- **Scope:** Implement a `URL` struct (`scheme`, `host`, `port`, `path`, `query`, `fragment`).
- **Deliverable:** Parse absolute URLs (`https://example.com:8443/docs/index.html?v=1#top`), apply default ports (`80` for `http`, `443` for `https`), and resolve relative paths (`../style.css`, `/about`, `//cdn.site.com/a.js`) against a base document URL.

### Step 3: Raw POSIX TCP Socket Client (Days 6–8)

- **Scope:** Wrap Linux POSIX networking (`getaddrinfo`, `socket`, `connect`, `send`, `recv`) in an RAII `TcpSocket` class that safely closes file descriptors on destruction.
- **Deliverable:** Connect to a remote host on port 80, send a raw `GET / HTTP/1.1` payload, and read the response stream into a byte buffer.

### Step 4: TLS 1.3 Encryption Layer via OpenSSL (Days 9–12)

- **Scope:** Wrap `TcpSocket` in a `TlsSocket` using OpenSSL (`SSL_CTX_new`, `SSL_set_tlsext_host_name` for SNI, `SSL_connect`, `SSL_read`, `SSL_write`).
- **Deliverable:** Establish verified HTTPS connections with Server Name Indication (SNI) and system CA root certificate validation.

### Step 5: HTTP/1.1 Client, Chunked Decoding & Redirects (Days 13–16)

- **Scope:** Build `HttpClient::fetch(const URL&)`:
  - Format request headers (`Host`, `User-Agent`, `Connection: close`, `Accept-Encoding: identity`).
  - Parse status lines (`HTTP/1.1 200 OK`) and case-insensitive response headers.
  - Support both `Content-Length` fixed reads and `Transfer-Encoding: chunked` hex-framed body assembly.
  - Automatically follow `301`, `302`, `307`, and `308` `Location` redirects (up to a max depth of 10).
- **Deliverable:** Fetch real-world HTTPS pages cleanly into an `HttpResponse { int status_code; Headers headers; std::string body; }`.

### Step 6: UTF-8 Stream Decoder & HTML Character Entity Resolver (Days 17–19)

- **Scope:**
  - Normalize `\r\n` and `\r` line endings into `\n` and strip null bytes (`\0` $\rightarrow$ `U+FFFD`) per WHATWG preprocessing rules.
  - Decode named entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&apos;`, `&nbsp;`) and numeric code points (`&#65;`, `&#x1F600;`) into valid UTF-8 sequences.
- **Deliverable:** Pass unit tests covering multi-byte UTF-8 emojis and nested/malformed character references.

### Step 7: WHATWG HTML5 State-Machine Tokenizer (Days 20–23)

- **Scope:** Implement a single-pass character-by-character state machine emitting `Token` variants:
  - `DoctypeToken`, `StartTagToken` (name, attributes map, self-closing flag), `EndTagToken`, `CommentToken`, `CharacterToken`, and `EOFToken`.
  - Cover core states: `Data`, `TagOpen`, `EndTagOpen`, `TagName`, `BeforeAttributeName`, `AttributeName`, `BeforeAttributeValue`, `AttributeValueQuoted/Unquoted`, `SelfClosingStartTag`, and `RAWTEXT` (for `<style>`/`<script>`).
- **Deliverable:** Tokenize arbitrary HTML files without regexes or backtracking.

### Step 8: Core DOM Tree Data Structures (Days 24–25)

- **Scope:** Design the Document Object Model hierarchy in `src/html/dom.hpp`:
  - Base `Node` (`NodeType`, `parent`, `children`, `append_child()`, `get_element_by_id()`, `query_elements_by_tag()`).
  - Derived classes: `Document`, `Element` (`tag_name`, `attributes`, `id()`, `class_list()`), `Text`, and `Comment`.
- **Deliverable:** Clean ownership model (`std::unique_ptr` for downward child ownership, raw non-owning pointers for `parent`) verified leak-free under ASan.

### Step 9: Stack-Based HTML5 Tree Builder & Error Recovery (Days 26–28)

- **Scope:** Consume tokens from Step 7 to construct the DOM tree from Step 8 using an **Open Elements Stack**:
  - Synthesize implicit `<html>`, `<head>`, and `<body>` wrappers if omitted in the markup.
  - Handle void elements (`<img>`, `<br>`, `<meta>`, `<link>`, `<input>`, `<hr>`) that never push onto the stack.
  - Implement auto-closing rules for real-world malformed HTML (e.g., an opening `<p>` implicitly closes an open `<p>`, `<li>` closes an open `<li>`).
- **Deliverable:** Parse messy real-world HTML documents into well-formed DOM trees without crashing or losing nodes.

### Step 10: End-to-End CLI Integration & DOM Serializer (Days 29–30)

- **Scope:** Wire `URL` $\rightarrow$ `HttpClient` $\rightarrow$ `HtmlTokenizer` $\rightarrow$ `TreeBuilder` in `src/main.cpp`.
- **Deliverable:** Run `./build/axiom https://example.com --dump-dom` to fetch a live HTTPS page, parse its HTML5 markup, and print an indented, color-coded DOM tree with tag attributes and text nodes to the terminal.

---

## Open-Source Libraries Required (Non-Compiler / Non-CMake)

- **OpenSSL (`libssl-dev`):** Handles TLS 1.3 handshakes, SNI negotiation, and X.509 certificate verification for HTTPS connections.
- **GoogleTest (`gtest`):** Unit testing framework used to validate URL resolution, HTTP chunked parsing, entity decoding, and DOM tree assertions after every 80-minute session.
