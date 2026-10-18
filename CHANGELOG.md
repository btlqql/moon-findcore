# Changelog

## 0.3.0 — 2026-10-18

Registry version: 0.3.0.

新增 compare 操作，对两份语料或更新请求在固定查询、筛选、排序及分页参数下执行检索，报告当前页文档新增、移除、顺序、分数及 total 的变化。比较输入配置不一致时拒绝请求，避免将参数改变误当作语料改变。

## 0.2.0 — 2026-10-16

Exact metadata filtering, bounded offset pagination and facets over the complete filtered result set. Missing metadata fields are distinct from explicit null. Equal-count facet buckets use explicit lexical canonical-value ordering.

Added regression fixtures and independent randomized checks for the revised behavior.

## 0.1.0 — 2026-10-05

Initial library, JSON CLI, fixtures and independent reference checks.
