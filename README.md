# Moon FindCore

Full text indexing and search, implemented in MoonBit with a JSON CLI and reusable library API.

- Repository: [https://github.com/btlqql/moon-findcore](https://github.com/btlqql/moon-findcore)
- Package: `btlqql/moon_findcore@0.1.0`
- License: Apache-2.0
- Release scope: **0.1.0 initial implementation**. The broader competition proposal in `docs/proposal.md` is a reference design, not a claim that every planned capability is implemented.

## Implemented

Per-field positional postings; Latin/accented-word and CJK unigram analyser; BM25 scoring; field-qualified terms; quoted phrases; parentheses; AND/OR/NOT; implicit AND; deterministic tie handling; upsert/delete; versioned source snapshots; term highlight ranges.

## Build and run

Use MoonBit and Node.js 24. The core library supports JS, wasm, wasm-gc and native; the filesystem/HTTP/process CLI is JS only.

```sh
moon update
moon build --target js
moon run cmd/main --target js -- examples/scenario-1.json
node _build/js/debug/build/cmd/main/main.js examples/scenario-1.json
```

Pass `-` to read a UTF-8 JSON request from stdin. A single request must be at most 16 MiB. Successful requests print one JSON result; invalid requests exit nonzero. The host runner is a separate process and does not edit the input request file.

## Library use

```sh
moon add btlqql/moon_findcore@0.1.0
```

In the consumer's `moon.pkg`:

```moonbit
import {
  "btlqql/moon_findcore" @engine,
  "moonbitlang/core/json",
}
```

```moonbit
fn example(request : Json) -> Json raise {
  @engine.execute(request)
}
```

`execute(Json) -> Json raise` is the standard JSON boundary. `from_json`, `Value::to_json`, and `run(Value) -> Value raise` provide a typed semantic value interface. Object ordering is not significant; numeric values use finite Double. Public domain functions are listed in `pkg.generated.mbti`.

## Tests

```sh
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon test --target native  # requires a C compiler
moon build --target js
node scripts/check.mjs
python -B scripts/reference.py
```

There are 6 checked fixture cases in `tests/cases.json`, executed both in MoonBit white-box tests and through the actual Node CLI. Independent reference checks use Python's standard library or separately written algorithms. Fixtures are synthetic and are not presented as production adoption evidence. See [input and output examples](docs/usage.md) and [current boundaries](docs/boundaries.md).

## Current boundaries

All processing is in memory. Snapshots store source documents and rebuild postings on load. CJK matching is character based, without a dictionary segmenter. No wildcard, fuzzy search or stemming. Highlight ranges use Unicode code-point offsets and identify positive query terms, not complete phrase spans; they are data rather than HTML. Results use Double scores; displayed serialised scores may round to the same value.

See [source and dependency attribution](THIRD_PARTY.md). This release does not establish competition eligibility or organizer acceptance.
