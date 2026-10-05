# Implemented architecture

## Core

Per-field positional postings; Latin/accented-word and CJK unigram analyser; BM25 scoring; field-qualified terms; quoted phrases; parentheses; AND/OR/NOT; implicit AND; deterministic tie handling; upsert/delete; versioned source snapshots; term highlight ranges.

## Boundaries

All processing is in memory. Snapshots store source documents and rebuild postings on load. CJK matching is character based, without a dictionary segmenter. No wildcard, fuzzy search or stemming. Highlight ranges use Unicode code-point offsets and identify positive query terms, not complete phrase spans; they are data rather than HTML. Results use Double scores; displayed serialised scores may round to the same value.

## Integration

The core accepts semantic values and returns deterministic JSON-shaped reports. Host adapters handle files, network or processes; they invoke the compiled MoonBit engine. The CLI package declares `supported_targets = "js"`; other backends test the portable core.

## Validation evidence

Fixture cases are hand-checked assertions. Independent reference checks and integration scripts are runnable from a clean checkout. CI executes four core backends and host checks. Historical proposal targets are not release results.
