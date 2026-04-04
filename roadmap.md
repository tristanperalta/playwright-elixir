# Playwright Elixir Upgrade Roadmap: 1.49.1 → 1.59.1

This roadmap tracks the upgrade of playwright-elixir from Playwright 1.49.1 to 1.59.1.

**Branch:** `upgrade-playwright-1.59`
**Protocol diff:** ~3,715 lines changed in `protocol.yml` across 10 minor versions.

---

## Phase 1: Package & Version Bump

- [ ] Update `priv/static/package.json`: `playwright` from `1.49.1` to `1.59.1`
- [ ] Update `priv/static/package.json`: `engines.node` from `>=16` to `>=18`
- [ ] Run `npm install` in `priv/static/`
- [ ] Install updated browser binaries (`npx playwright install`)
- [ ] Update `mix.exs` version from `1.49.1-alpha.2` to `1.59.1-alpha.1`
- [ ] Verify `priv/static/driver.js` symlink still resolves

---

## Phase 2: Breaking Changes

These must be addressed before the library will work with 1.59.1.

### 2a: Removed Protocol Commands

- [ ] **Remove `Page.Accessibility` module** — `accessibilitySnapshot` command removed in 1.57
  - Remove `lib/playwright/page/accessibility.ex`
  - Remove `test/api/page/accessibility_test.exs`
  - Update docs references and `mix.exs` doc groups
  - Note: `Frame.aria_snapshot/3` and `Locator.aria_snapshot/2` exist as replacements (different API shape — returns YAML string, not tree)

- [ ] **Migrate `Selectors` module** — `Selectors` interface removed entirely
  - Remove or rewrite `lib/playwright/selectors.ex`
  - Replacement: `BrowserContext.registerSelectorEngine` and `BrowserContext.setTestIdAttributeName`
  - Alternative: pass `selectorEngines` and `testIdAttributeName` via `ContextOptions`

- [ ] **Remove `backgroundPage` event** — `BrowserContext.backgroundPage` event removed in 1.57
  - Remove any event binding in `BrowserContext.init/2`

### 2b: Required Timeouts

The protocol changed nearly every `timeout` parameter from optional (`number?`) to required (`float`). The server no longer fills in defaults.

- [ ] Audit all `Channel.post` calls that pass timeout options
- [ ] Ensure the library always sends a timeout value (use `Config` defaults as fallback)
- [ ] Special cases:
  - `Frame.isHidden`/`isVisible` — timeout parameter removed entirely (now one-shot)
  - `Frame.waitForTimeout` — param renamed from `timeout` to `waitTimeout`

### 2c: Type System Changes

The protocol split `number` into `int` and `float`. JSON doesn't distinguish, so this is low risk, but:

- [ ] Review `Serialization.ex` for any type assumptions
- [ ] Add typed array (`ta`) support to `SerializedValue` deserialization
  - New types: Int8Array, Uint8Array, Uint8ClampedArray, Int16Array, Uint16Array, Int32Array, Uint32Array, Float32Array, Float64Array, BigInt64Array, BigUint64Array

### 2d: Other Breaking Changes

- [ ] `ContextOptions.recordHar` removed — HAR recording now via `harStart`/`harExport` commands
- [ ] `Route.continue` no longer allows overriding Cookie header (document only)
- [ ] Glob patterns in `page.route()` no longer support `?` and `[]` (document only)
- [ ] `BrowserType.launchPersistentContext` now returns `{browser, context}` instead of just `context`

---

## Phase 3: Deprecations

- [ ] Mark `Page.type/4` as deprecated — use `Page.fill/4` or `Locator.press_sequentially/3`
- [ ] Mark `Frame.type/4` as deprecated — use `Frame.fill/4`
- [ ] Mark `Locator.type/3` as deprecated — use `Locator.fill/3` or `Locator.press_sequentially/3`

---

## Phase 4: New APIs

### Priority (small, high value)

- [ ] `Page.requests/1` — returns up to 100 last network requests (1.56)
- [ ] `Page.aria_snapshot/2` — shorthand for `Locator.aria_snapshot` on body (1.59)
- [ ] `Locator.describe/2` — annotate locator for trace viewer/reports (1.53)
- [ ] Cookie `partitionKey` field in `BrowserContext` cookie types (1.53)
- [ ] `Page.emulateMedia` `contrast` option: `no-preference`, `more`, `no-override` (1.56)

### Medium (new params on existing commands)

- [ ] `Frame.click`/`dblclick`/`dragAndDrop` `steps: int` option (1.54)
- [ ] `ElementHandle.click`/`dblclick` `steps: int` option (1.54)
- [ ] `Frame.expect` `selector` now optional (1.57)
- [ ] Worker console event support — Worker now extends EventTarget (1.59)
- [ ] `BrowserContext.storageState` `indexedDB` option (1.57)

### Deferred (larger effort)

- [ ] `Screencast` module — new ChannelOwner for video recording with annotations (1.50)
  - Methods: `start`, `stop`, `showActions`, `hideActions`, `showChapter`, `showOverlay`, `showOverlays`, `hideOverlays`
- [ ] IndexedDB support in storage state (new `IndexedDBDatabase` type)
- [ ] `Page.snapshotForAI` (internal, for MCP/AI integrations)

---

## Phase 5: Testing & Validation

- [ ] Run full test suite after package update — expect accessibility test failures
- [ ] Remove/skip accessibility tests
- [ ] Verify browser installation works (Chrome for Testing switch in 1.57)
- [ ] Test on all browser engines: Chromium, Firefox, WebKit
- [ ] Add smoke test verifying driver version is 1.59.x
- [ ] Test `routeWebSocket`, `consoleMessages`, `pageErrors` (already implemented, now supported by server)

---

## Phase 6: Documentation & Release

- [ ] Update README version references
- [ ] Update `man/guides/feature_parity.md` to reflect final state
- [ ] Write changelog entry covering:
  - Breaking: Accessibility API removed, Selectors interface removed
  - Deprecated: `type()` methods
  - New: `requests/1`, `aria_snapshot/2`, `describe/2`, cookie `partitionKey`
- [ ] Update `man/basics/release-notes.md`

---

## Protocol Change Summary

| Version | Key Changes |
|---------|------------|
| 1.50 | `type()` deprecated, Screencast API added |
| 1.51 | Glob patterns changed, Route.continue cookie override removed |
| 1.53 | `Locator.describe()`, cookie `partitionKey` |
| 1.54 | `click`/`dragTo` `steps` option |
| 1.55 | Chromium extension manifest v2 dropped |
| 1.56 | `Page.requests()`, `emulateMedia` contrast |
| 1.57 | **Accessibility API removed**, Selectors removed, Node 16 dropped, Chrome for Testing, all timeouts required |
| 1.58 | `tracing.group()` |
| 1.59 | `routeWebSocket`, `Page.ariaSnapshot()`, Worker console events |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| `accessibilitySnapshot` removed | **High** | Remove module, skip tests |
| `Selectors` interface removed | **High** | Migrate to BrowserContext methods |
| Timeouts now required | **High** | Audit all Channel.post calls, add defaults |
| New ChannelOwner types (e.g. Screencast) cause crash | **Medium** | Add fallback in `ChannelOwner.module/1` |
| Serialization changes (typed arrays) | **Medium** | Add `ta` handler in Serialization.ex |
| Glob pattern behavior change | **Low** | Document only — Elixir-side matcher already ignores `?`/`[]` |
| `number` → `int`/`float` split | **Low** | JSON doesn't distinguish; cosmetic |
