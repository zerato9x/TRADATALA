# Endless history and resolve presentation

## Behavior

- A completed deal plays its existing resolution feedback, archives its full accounting report, and advances to the event table without a receipt screen or extra Continue click.
- Daily collection presents totals and payment information, without scoring-card or transaction-history tabs. Payment still belongs to `CampaignManager.collect_day_debt()`.
- Hiding a receipt releases its report and generated content controls. The end-of-run scroll remains available.
- No historical gameplay records are truncated. Completed deal reports, per-card scoring passes/properties, day reports, activity records, and the wallet journal remain available for future zodiac modifier rules. This change does not implement zodiac rules.

## Save format

The envelope is version 2, at the existing save path. The reader accepts versions 1 and 2; older game builds cannot read version 2. Backup/checksum/atomic replacement behavior is unchanged.

Known value-only history fields use native Variant containers instead of recursively wrapping every historical dictionary key and array element in GDScript. Live card/meld objects still use the existing whitelist/reference encoder. History producers must continue to store value snapshots, never live Objects. The synchronous save path also skips redundant history duplication; normal gameplay snapshots retain their default copying behavior.

## Verification (2026-09-23)

- Core: 203/203 passed.
- Runtime, tutorial, resolve presentation, and progression scene smokes passed.
- Rendered resolve scene smoke passed; collection screenshot inspected at 1280x720.
- `endless_history_smoke.gd`: 900 archived deal fixtures; version 1 load, version 2 write/load/restore, full history, wallet balance, and draw order passed.
- Same-process synthetic encoding comparison: recursive 209.88 ms / 2,534,812 bytes; native history 38.34 ms / 1,720,660 bytes. Complete new save: 63.34 ms. These are local synthetic measurements, not gameplay FPS measurements.

Remaining limitation: history is retained in memory and a whole snapshot is still serialized and written for autosave. Cost therefore still grows with run length, and the existing 64 MiB load limit remains. If real Endless profiling shows save hitches after this improvement, the next step is a separately persisted append-only archive with transactional checkpoint references, or a safely detached asynchronous save pipeline. Do not silently prune records needed by zodiac work.
