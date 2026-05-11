## Context

The `auto_provision.sh` script is a monolithic Bash file that handles several distinct responsibilities:
1. Environment and configuration loading
2. Command-line argument parsing
3. Environment prerequisite checks (OCI CLI installation)
4. OCI API interaction & output parsing (JSON scraping without `jq`)
5. Retry/backoff loop
6. Output artifact generation

Because it's a monolithic script lacking structural markers, maintaining it or auditing its behavior requires parsing Bash idioms directly.

## Goals / Non-Goals

**Goals:**
- Provide clear structural section headers (e.g., `# --- SECTION NAME ---`).
- Add concise block comments for utility functions explaining what they do and their expected outputs.
- Explain the manual JSON parsing logic where `sed`/`grep` is used instead of `jq`.

**Non-Goals:**
- Do not refactor or change any logic.
- Do not document every single line; focus on functions, blocks, and tricky logic.

## Decisions

- **Structural Markers**: Use standard `# === [Section Name] ===` comments to visually divide the file into logical blocks (Configuration, Utilities, Parsing, OCI Helpers, Core Loop, etc.).
- **Function Comments**: Place a short `# Description: ...` block above complex functions (like the dotenv parser or instance ID extractor) to clarify intent.

## Risks / Trade-offs

- [Risk] Adding comments increases file size and might cause merge conflicts with other inflight work. -> Mitigation: No other script changes are currently active; keep comments concise.