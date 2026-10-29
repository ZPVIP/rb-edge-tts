# CHANGELOG

## 1.0.0 (2026-01-08)
- Initial release  

## 1.0.1 (2026-01-08)
- Update gemspec metadata and README with correct repository information.
- Bump version number for new release.

## Unreleased
- Fix HTTP 403 from Microsoft's service: send the v2 `Sec-MS-GEC` token (`<16 hex>-<64 hex>`) and `Sec-MS-GEC-Version` `2-...`, ported from edge-tts 7.3.0 (rany2/edge-tts#490).
- `list_voices` no longer raises on new fields in the voice list response (e.g. `LocaleName`).
