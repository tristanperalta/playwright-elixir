# Playwright Feature Parity Tracking

This document tracks the implementation status of Playwright features in playwright-elixir compared to the official TypeScript client.

**Reference:** `/home/tristan/sources/playwright/packages/playwright-core/src/client/`

**Legend:**
- [x] Implemented
- [~] Partially implemented / stubbed
- [ ] Not implemented
- [!] Priority implementation candidate

---

## Page Module

**File:** `lib/playwright/page.ex`
**Reference:** `page.ts`

### Navigation & Loading

| Method | Status | Notes |
|--------|--------|-------|
| `goto(url, options)` | [x] | |
| `reload(options)` | [x] | |
| `goBack(options)` | [x] | |
| `goForward(options)` | [x] | |
| `waitForLoadState(state, options)` | [x] | |
| `waitForNavigation(options)` | [x] | |
| `waitForURL(url, options)` | [x] | Polling-based implementation |
| `waitForRequest(urlOrPredicate, options)` | [ ] | |
| `waitForResponse(urlOrPredicate, options)` | [ ] | |
| `waitForEvent(event, options)` | [~] | As `expect_event` |
| `bringToFront()` | [ ] | |

### Content & State

| Method | Status | Notes |
|--------|--------|-------|
| `url()` | [x] | |
| `title()` | [x] | |
| `content()` | [ ] | Get page HTML |
| `setContent(html, options)` | [x] | |
| `setViewportSize(size)` | [x] | |
| `viewportSize()` | [ ] | |
| `isClosed()` | [~] | Via `is_closed` field |
| `close(options)` | [x] | |
| `opener()` | [ ] | |

### Frames

| Method | Status | Notes |
|--------|--------|-------|
| `mainFrame()` | [~] | Via `main_frame` field |
| `frames()` | [x] | |
| `frame(selector)` | [ ] | Get frame by name/url |
| `frameLocator(selector)` | [ ] | !Priority |

### Locators (getBy* methods)

| Method | Status | Notes |
|--------|--------|-------|
| `locator(selector, options)` | [x] | |
| `getByText(text, options)` | [x] | |
| `getByRole(role, options)` | [x] | |
| `getByTestId(testId)` | [x] | |
| `getByLabel(text, options)` | [x] | |
| `getByPlaceholder(text, options)` | [ ] | |
| `getByAltText(text, options)` | [ ] | |
| `getByTitle(text, options)` | [ ] | |

### Actions (selector-based)

| Method | Status | Notes |
|--------|--------|-------|
| `click(selector, options)` | [x] | |
| `dblclick(selector, options)` | [x] | |
| `tap(selector, options)` | [~] | Stubbed |
| `fill(selector, value, options)` | [x] | |
| `type(selector, text, options)` | [ ] | Deprecated, use fill |
| `press(selector, key, options)` | [x] | |
| `hover(selector, options)` | [x] | |
| `focus(selector, options)` | [x] | |
| `selectOption(selector, values, options)` | [x] | |
| `check(selector, options)` | [ ] | |
| `uncheck(selector, options)` | [ ] | |
| `setChecked(selector, checked, options)` | [ ] | |
| `setInputFiles(selector, files, options)` | [ ] | |
| `dragAndDrop(source, target, options)` | [x] | |
| `dispatchEvent(selector, type, eventInit, options)` | [x] | |

### Query Methods

| Method | Status | Notes |
|--------|--------|-------|
| `textContent(selector, options)` | [x] | |
| `innerText(selector, options)` | [ ] | |
| `innerHTML(selector, options)` | [ ] | |
| `getAttribute(selector, name, options)` | [x] | |
| `inputValue(selector, options)` | [ ] | |
| `isChecked(selector, options)` | [ ] | |
| `isDisabled(selector, options)` | [ ] | |
| `isEditable(selector, options)` | [ ] | |
| `isEnabled(selector, options)` | [ ] | |
| `isHidden(selector, options)` | [ ] | |
| `isVisible(selector, options)` | [ ] | |
| `waitForSelector(selector, options)` | [x] | |

### JavaScript Evaluation

| Method | Status | Notes |
|--------|--------|-------|
| `evaluate(expression, arg)` | [x] | |
| `evaluateHandle(expression, arg)` | [x] | |
| `evalOnSelector(selector, expression, arg)` | [x] | |
| `evalOnSelectorAll(selector, expression, arg)` | [ ] | |
| `exposeFunction(name, callback)` | [x] | |
| `exposeBinding(name, callback, options)` | [x] | |
| `addInitScript(script, arg)` | [x] | |
| `addScriptTag(options)` | [ ] | |
| `addStyleTag(options)` | [ ] | |

### Routing & Network

| Method | Status | Notes |
|--------|--------|-------|
| `route(url, handler, options)` | [x] | |
| `unroute(url, handler)` | [x] | |
| `unrouteAll(options)` | [ ] | |
| `routeFromHAR(har, options)` | [ ] | |
| `routeWebSocket(url, handler)` | [ ] | |
| `setExtraHTTPHeaders(headers)` | [ ] | |

### Screenshots & Media

| Method | Status | Notes |
|--------|--------|-------|
| `screenshot(options)` | [x] | |
| `pdf(options)` | [ ] | Chromium only |
| `video()` | [ ] | |
| `emulateMedia(options)` | [ ] | |

### Events

| Method | Status | Notes |
|--------|--------|-------|
| `on(event, callback)` | [x] | With event validation |
| `waitForEvent(event, options)` | [~] | As `expect_event` |
| `consoleMessages()` | [ ] | |
| `pageErrors()` | [ ] | |

### Locator Handlers

| Method | Status | Notes |
|--------|--------|-------|
| `addLocatorHandler(locator, handler, options)` | [ ] | For auto-dismiss dialogs |
| `removeLocatorHandler(locator)` | [ ] | |

### Timeouts

| Method | Status | Notes |
|--------|--------|-------|
| `setDefaultTimeout(timeout)` | [ ] | |
| `setDefaultNavigationTimeout(timeout)` | [ ] | |

### Other

| Method | Status | Notes |
|--------|--------|-------|
| `context()` | [x] | |
| `pause()` | [ ] | Inspector |
| `requestGC()` | [ ] | |

---

## Locator Module

**File:** `lib/playwright/locator.ex`
**Reference:** `locator.ts`

### Creation & Chaining

| Method | Status | Notes |
|--------|--------|-------|
| `locator(selector, options)` | [x] | |
| `first()` | [x] | |
| `last()` | [x] | |
| `nth(index)` | [x] | |
| `filter(options)` | [x] | has_text, has_not_text, has, has_not, visible |
| `and(locator)` | [ ] | Combine locators |
| `or(locator)` | [x] | As `or_` |
| `getByText(text, options)` | [x] | |
| `getByRole(role, options)` | [x] | |
| `getByTestId(testId)` | [x] | |
| `getByLabel(text, options)` | [x] | |
| `getByPlaceholder(text, options)` | [ ] | |
| `getByAltText(text, options)` | [ ] | |
| `getByTitle(text, options)` | [ ] | |
| `frameLocator(selector)` | [ ] | |
| `contentFrame()` | [ ] | |
| `owner()` | [ ] | |

### Actions

| Method | Status | Notes |
|--------|--------|-------|
| `click(options)` | [x] | |
| `dblclick(options)` | [x] | |
| `tap(options)` | [x] | |
| `fill(value, options)` | [x] | |
| `clear(options)` | [x] | |
| `type(text, options)` | [x] | Deprecated |
| `pressSequentially(text, options)` | [ ] | Replaces type |
| `press(key, options)` | [x] | |
| `hover(options)` | [x] | |
| `focus(options)` | [x] | |
| `blur(options)` | [x] | |
| `check(options)` | [x] | |
| `uncheck(options)` | [x] | |
| `setChecked(checked, options)` | [x] | |
| `selectOption(values, options)` | [x] | |
| `selectText(options)` | [x] | |
| `setInputFiles(files, options)` | [x] | |
| `dragTo(target, options)` | [x] | |
| `scrollIntoViewIfNeeded(options)` | [~] | As `scroll_into_view` |
| `dispatchEvent(type, eventInit, options)` | [x] | |
| `highlight()` | [ ] | |

### Query Methods

| Method | Status | Notes |
|--------|--------|-------|
| `count()` | [x] | |
| `all()` | [x] | |
| `textContent(options)` | [x] | |
| `innerText(options)` | [x] | |
| `innerHTML(options)` | [x] | |
| `getAttribute(name, options)` | [x] | |
| `inputValue(options)` | [x] | |
| `boundingBox(options)` | [x] | |
| `allTextContents()` | [x] | |
| `allInnerTexts()` | [x] | |

### State Checks

| Method | Status | Notes |
|--------|--------|-------|
| `isChecked(options)` | [x] | |
| `isDisabled(options)` | [x] | |
| `isEditable(options)` | [x] | |
| `isEnabled(options)` | [x] | |
| `isHidden(options)` | [x] | |
| `isVisible(options)` | [x] | |

### Evaluation

| Method | Status | Notes |
|--------|--------|-------|
| `evaluate(expression, arg, options)` | [x] | |
| `evaluateAll(expression, arg)` | [x] | |
| `evaluateHandle(expression, arg, options)` | [x] | |

### Screenshots & Handles

| Method | Status | Notes |
|--------|--------|-------|
| `screenshot(options)` | [x] | |
| `elementHandle(options)` | [x] | |
| `elementHandles()` | [x] | |
| `ariaSnapshot(options)` | [ ] | |

### Waiting

| Method | Status | Notes |
|--------|--------|-------|
| `waitFor(options)` | [x] | |

### Other

| Method | Status | Notes |
|--------|--------|-------|
| `page()` | [ ] | |
| `describe(description)` | [ ] | |

---

## BrowserContext Module

**File:** `lib/playwright/browser_context.ex`
**Reference:** `browserContext.ts`

### Pages

| Method | Status | Notes |
|--------|--------|-------|
| `newPage()` | [x] | |
| `pages()` | [x] | |
| `browser()` | [x] | |

### Cookies

| Method | Status | Notes |
|--------|--------|-------|
| `cookies(urls)` | [x] | |
| `addCookies(cookies)` | [x] | |
| `clearCookies(options)` | [x] | |

### Permissions

| Method | Status | Notes |
|--------|--------|-------|
| `grantPermissions(permissions, options)` | [x] | |
| `clearPermissions()` | [x] | |

### Settings

| Method | Status | Notes |
|--------|--------|-------|
| `setGeolocation(geolocation)` | [ ] | !Priority |
| `setExtraHTTPHeaders(headers)` | [ ] | |
| `setOffline(offline)` | [x] | |
| `setHTTPCredentials(credentials)` | [ ] | |
| `setDefaultTimeout(timeout)` | [ ] | |
| `setDefaultNavigationTimeout(timeout)` | [ ] | |

### Scripts & Bindings

| Method | Status | Notes |
|--------|--------|-------|
| `addInitScript(script, arg)` | [x] | |
| `exposeBinding(name, callback, options)` | [x] | |
| `exposeFunction(name, callback)` | [x] | |

### Routing

| Method | Status | Notes |
|--------|--------|-------|
| `route(url, handler, options)` | [x] | |
| `unroute(url, handler)` | [x] | |
| `unrouteAll(options)` | [ ] | |
| `routeFromHAR(har, options)` | [ ] | |
| `routeWebSocket(url, handler)` | [ ] | |

### State

| Method | Status | Notes |
|--------|--------|-------|
| `storageState(options)` | [ ] | !Priority - session persistence |
| `close(options)` | [x] | |

### Events

| Method | Status | Notes |
|--------|--------|-------|
| `on(event, callback)` | [x] | |
| `waitForEvent(event, options)` | [~] | As `expect_event` |

### Workers

| Method | Status | Notes |
|--------|--------|-------|
| `backgroundPages()` | [ ] | |
| `serviceWorkers()` | [ ] | |

### CDP

| Method | Status | Notes |
|--------|--------|-------|
| `newCDPSession(page)` | [x] | |

---

## Browser Module

**File:** `lib/playwright/browser.ex`
**Reference:** `browser.ts`

| Method | Status | Notes |
|--------|--------|-------|
| `newContext(options)` | [x] | |
| `newPage(options)` | [x] | Returns `{:ok, page}` |
| `contexts()` | [x] | |
| `close()` | [x] | |
| `isConnected()` | [ ] | |
| `browserType()` | [ ] | |
| `version` | [x] | Property |
| `name` | [x] | Property |
| `newBrowserCDPSession()` | [ ] | |
| `startTracing(page, options)` | [ ] | |
| `stopTracing()` | [ ] | |

---

## Frame Module

**File:** `lib/playwright/frame.ex`
**Reference:** `frame.ts`

### Navigation

| Method | Status | Notes |
|--------|--------|-------|
| `goto(url, options)` | [x] | |
| `waitForNavigation(options)` | [x] | |
| `waitForURL(url, options)` | [x] | |
| `waitForLoadState(state, options)` | [x] | |
| `url()` | [x] | |
| `name()` | [ ] | |
| `title()` | [x] | |

### Content

| Method | Status | Notes |
|--------|--------|-------|
| `content()` | [x] | |
| `setContent(html, options)` | [x] | |

### Hierarchy

| Method | Status | Notes |
|--------|--------|-------|
| `page()` | [ ] | |
| `parentFrame()` | [ ] | |
| `childFrames()` | [ ] | |
| `isDetached()` | [ ] | |
| `frameElement()` | [ ] | |
| `frameLocator(selector)` | [ ] | |

### Locators

| Method | Status | Notes |
|--------|--------|-------|
| `locator(selector, options)` | [x] | |
| `getByText(text, options)` | [x] | |
| `getByRole(role, options)` | [x] | |
| `getByTestId(testId)` | [x] | |
| `getByLabel(text, options)` | [x] | |
| `getByPlaceholder(text, options)` | [ ] | |
| `getByAltText(text, options)` | [ ] | |
| `getByTitle(text, options)` | [ ] | |

### Actions

| Method | Status | Notes |
|--------|--------|-------|
| `click(selector, options)` | [x] | |
| `dblclick(selector, options)` | [x] | |
| `tap(selector, options)` | [x] | |
| `fill(selector, value, options)` | [x] | |
| `type(selector, text, options)` | [x] | |
| `press(selector, key, options)` | [x] | |
| `hover(selector, options)` | [x] | |
| `focus(selector, options)` | [x] | |
| `check(selector, options)` | [x] | |
| `uncheck(selector, options)` | [x] | |
| `selectOption(selector, values, options)` | [x] | |
| `setInputFiles(selector, files, options)` | [x] | |
| `dragAndDrop(source, target, options)` | [x] | |
| `dispatchEvent(selector, type, eventInit, options)` | [x] | |

### Query Methods

| Method | Status | Notes |
|--------|--------|-------|
| `textContent(selector, options)` | [x] | |
| `innerText(selector, options)` | [x] | |
| `innerHTML(selector, options)` | [x] | |
| `getAttribute(selector, name, options)` | [x] | |
| `inputValue(selector, options)` | [x] | |
| `isChecked(selector, options)` | [x] | |
| `isDisabled(selector, options)` | [x] | |
| `isEditable(selector, options)` | [x] | |
| `isEnabled(selector, options)` | [x] | |
| `isHidden(selector, options)` | [x] | |
| `isVisible(selector, options)` | [x] | |
| `waitForSelector(selector, options)` | [x] | |
| `querySelector(selector)` | [x] | As `query_selector` |
| `querySelectorAll(selector)` | [x] | As `query_selector_all` |

### Evaluation

| Method | Status | Notes |
|--------|--------|-------|
| `evaluate(expression, arg)` | [x] | |
| `evaluateHandle(expression, arg)` | [x] | |
| `evalOnSelector(selector, expression, arg)` | [x] | |
| `evalOnSelectorAll(selector, expression, arg)` | [x] | |

---

## Completely Stubbed/Empty Modules

These modules exist but have no implemented methods (all commented out):

### Mouse (`lib/playwright/page/mouse.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `click(x, y, options)` | [ ] | |
| `dblclick(x, y, options)` | [ ] | |
| `down(options)` | [ ] | |
| `up(options)` | [ ] | |
| `move(x, y, options)` | [ ] | |
| `wheel(deltaX, deltaY)` | [ ] | |

### Touchscreen (`lib/playwright/page/touchscreen.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `tap(x, y)` | [ ] | |

### Dialog (`lib/playwright/dialog.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `accept(promptText)` | [x] | |
| `dismiss()` | [x] | |
| `message()` | [x] | |
| `defaultValue()` | [x] | `default_value/1` |
| `type()` | [x] | |
| `page()` | [x] | |

### Download (`lib/playwright/page/download.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `cancel()` | [ ] | |
| `delete()` | [ ] | |
| `failure()` | [ ] | |
| `page()` | [ ] | |
| `path()` | [ ] | !Priority |
| `saveAs(path)` | [ ] | !Priority |
| `suggestedFilename()` | [ ] | |
| `url()` | [ ] | |

### Coverage (`lib/playwright/page/coverage.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `startJSCoverage(options)` | [ ] | |
| `stopJSCoverage()` | [ ] | |
| `startCSSCoverage(options)` | [ ] | |
| `stopCSSCoverage()` | [ ] | |

### Tracing (`lib/playwright/tracing.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `start(options)` | [ ] | |
| `stop(options)` | [ ] | |
| `group(name, options)` | [ ] | |
| `groupEnd()` | [ ] | |

### FrameLocator (`lib/playwright/page/frame_locator.ex`)

| Method | Status | Notes |
|--------|--------|-------|
| `first()` | [ ] | |
| `last()` | [ ] | |
| `nth(index)` | [ ] | |
| `frameLocator(selector)` | [ ] | |
| `locator(selector)` | [ ] | |
| `getByText(text, options)` | [ ] | |
| `getByRole(role, options)` | [ ] | |
| `getByTestId(testId)` | [ ] | |
| `getByLabel(text, options)` | [ ] | |
| `getByPlaceholder(text, options)` | [ ] | |
| `getByAltText(text, options)` | [ ] | |
| `getByTitle(text, options)` | [ ] | |
| `owner()` | [ ] | |

---

## Missing Modules (Not Yet Created)

### FileChooser

| Method | Status | Notes |
|--------|--------|-------|
| `element()` | [ ] | |
| `isMultiple()` | [ ] | |
| `page()` | [ ] | |
| `setFiles(files, options)` | [ ] | !Priority |

### Clock

| Method | Status | Notes |
|--------|--------|-------|
| `install(options)` | [ ] | |
| `fastForward(ticks)` | [ ] | |
| `pauseAt(time)` | [ ] | |
| `resume()` | [ ] | |
| `runFor(ticks)` | [ ] | |
| `setFixedTime(time)` | [ ] | |
| `setSystemTime(time)` | [ ] | |

### Video

| Method | Status | Notes |
|--------|--------|-------|
| `delete()` | [ ] | |
| `path()` | [ ] | |
| `saveAs(path)` | [ ] | |

---

## Priority Implementation Roadmap

### Phase 1: Core Navigation & Waiting (High Impact)
1. ~~`Page.goBack()` / `Page.goForward()`~~ DONE
2. ~~`Page.waitForNavigation()`~~ DONE
3. ~~`Page.waitForURL()`~~ DONE
4. ~~`Dialog.accept()` / `Dialog.dismiss()`~~ DONE

### Phase 2: Modern Locators (Developer Experience)
1. ~~`*.getByRole()`~~ DONE
2. ~~`*.getByTestId()`~~ DONE
3. ~~`*.getByLabel()`~~ DONE
4. ~~`Locator.filter()`~~ DONE

### Phase 3: Session & State (Testing Infrastructure)
1. `BrowserContext.storageState()`
2. `BrowserContext.setGeolocation()`
3. `Download.saveAs()` / `Download.path()`

### Phase 4: Advanced Features
1. `Mouse` module
2. `FrameLocator` module
3. `Page.pdf()`
4. `Tracing` module

### Phase 5: Completeness
1. Remaining Page query methods
2. `FileChooser` module
3. `Clock` module
4. `Video` module

---

## Implementation Notes

### Event Names (from Playwright events.ts)

```typescript
Page: {
  AgentTurn: 'agentturn',
  Close: 'close',
  Crash: 'crash',
  Console: 'console',
  Dialog: 'dialog',
  Download: 'download',
  FileChooser: 'filechooser',
  DOMContentLoaded: 'domcontentloaded',
  PageError: 'pageerror',
  Request: 'request',
  Response: 'response',
  RequestFailed: 'requestfailed',
  RequestFinished: 'requestfinished',
  FrameAttached: 'frameattached',
  FrameDetached: 'framedetached',
  FrameNavigated: 'framenavigated',
  Load: 'load',
  Popup: 'popup',
  WebSocket: 'websocket',
  Worker: 'worker',
}
```

### Channel Commands Reference

When implementing new methods, refer to the protocol definitions in:
- `/home/tristan/sources/playwright/packages/protocol/src/channels.ts`

### Testing Patterns

Each new feature should include tests following the existing pattern in `test/api/`.
