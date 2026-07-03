# Roadmap

## v1.1 — Modular (current)
- [x] Plugin system with priority-based dispatch
- [x] Workflow engine (modules emit events, trigger other modules)
- [x] 14 modules covering common CTF techniques (now 44)
- [x] Config system (flag patterns, passwords)
- [x] `stegoforge doctor` — dependency checker
- [x] Structured output (sessions, reports, carved, bitplanes, spectrograms, repaired)

## v1.2 — Recursive
- [x] Trailing data detection (data after IEND/FFD9)
- [x] File extension vs magic byte mismatch detection (polyglot fixer)
- [ ] HTML/PDF reports
- [ ] Parallel module execution (faster scanning)
- [ ] Recursive archive extraction

## v1.3 — Intelligent
- [x] Partial flag / tail detection when full pattern doesn't match
- [ ] Entropy analysis heatmap
- [ ] Image diff (XOR two images)
- [ ] Multi-file correlation
- [ ] Session save/load (JSON)
- [ ] Custom workflow YAML config

## v2.0 — Framework
- [ ] Plugin SDK (write modules in Python too)
- [ ] Workflow engine with conditional branching
- [ ] AI-assisted decoding (LLM integration)
- [ ] GUI (TUI or web interface)
- [ ] Distributed scanning
