# Moon FindCore

## Competition direction status (2026-10-21)

This historical retrieval library overlaps existing MoonRetrieve capabilities. It is not presented as an independently differentiated replacement by adding more retrieval endpoints. The btlqql replacement candidate is [ProtocolDiff](https://github.com/btlqql/moon-protocoldiff), a separate explicit protocol-machine comparison project. HistoryCheck belongs to 123123213weqw and is not reassigned to this account. Competition form replacement is pending; this notice does not claim organizer approval.

Full text indexing and search, implemented in MoonBit with a JSON CLI and reusable library API.

- Repository: [https://github.com/btlqql/moon-findcore](https://github.com/btlqql/moon-findcore)
- Package: `btlqql/moon_findcore@0.3.0`
- License: Apache-2.0
- Release scope: **0.2.0 revised component release**. The broader competition proposal in `docs/proposal.md` is a reference design, not a claim that every planned capability is implemented.

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
moon add btlqql/moon_findcore@0.3.0
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

There are 15 checked fixture cases in `tests/cases.json`, executed both in MoonBit white-box tests and through the actual Node CLI. Independent reference checks use Python's standard library or separately written algorithms. Fixtures are synthetic and are not presented as production adoption evidence. See [input and output examples](docs/usage.md) and [current boundaries](docs/boundaries.md).

## Current boundaries

All processing is in memory. Snapshots store source documents and rebuild postings on load. CJK matching is character based, without a dictionary segmenter. No wildcard, fuzzy search or stemming. Highlight ranges use Unicode code-point offsets and identify positive query terms, not complete phrase spans; they are data rather than HTML. Results use Double scores; displayed serialised scores may round to the same value.

See [source and dependency attribution](THIRD_PARTY.md). This release does not establish competition eligibility or organizer acceptance.


## Version 0.2.0 revision

Exact metadata filtering, bounded offset pagination and facets over the complete filtered result set. Missing metadata fields are distinct from explicit null. Equal-count facet buckets use explicit lexical canonical-value ordering.

当前索引和查询均在内存中完成，快照载入会重建索引，没有磁盘倒排数据库、模糊搜索、通配符、词干化或语义向量检索。高亮输出 Unicode 码点范围，不是 HTML 或完整短语跨度。元数据筛选不替代鉴权；分面是完整值统计，不展开多值字段。不同分数在序列化显示时可能因浮点舍入看起来相同。

Run the additional complete scenario:

```sh
moon run cmd/main --target js -- examples/scenario-4.json
```


## 2026-10-18 follow-up

新增 compare 操作，对两份语料或更新请求在固定查询、筛选、排序及分页参数下执行检索，报告当前页文档新增、移除、顺序、分数及 total 的变化。比较输入配置不一致时拒绝请求，避免将参数改变误当作语料改变。

变化范围明确为所返回窗口与总数，不证明整个索引等价。分页之外的具体文档未全部列出；浮点分数可受语料整体 BM25 统计影响。

Repository release: 0.3.0; installable MoonCakes module: `btlqql/moon_findcore@0.3.0`. Earlier repository 1.0.0 labels are retained as history; the module uses the registry-compatible zero-major sequence.

Current source contains 19 MoonBit test declarations and 15 CLI fixtures (generated fixture tests are included in the declaration count). Run `python -B scripts/followup_reference.py` for independent follow-up oracles and `examples/followup-20261018.json` for the new scenario.
