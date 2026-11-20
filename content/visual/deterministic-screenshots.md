---
title: Deterministic screenshots
linkTitle: Visual tracking
description: How to make Playwright screenshots stable for Cairn Report's visual change tracking.
weight: 20
---

**Not released yet.** Visual tracking comes with the next release of the Playwright reporter
`@cairnreport/playwright` and the Cairn Report server. It requires `@playwright/test` 1.65 or
later.

Cairn Report tracks the screenshots your Playwright tests take: it keeps one copy of each image per
repository, compares it with the baseline in the background and shows what changed on the run
page. To track them, import `test` and `expect` from `@cairnreport/playwright/test` instead of
`@playwright/test`; the tests need no other change:

```ts
import { test, expect } from '@cairnreport/playwright/test';
```

A comparison is only useful when the same page gives the same pixels on every run. Clocks, dates,
random data, third-party content and animations change from run to run and make screenshots look
changed when nothing in your product did. This page shows how to keep each of them still. Every
section has a snippet you can copy.

<!-- Snippet markers: the block after each "snippet:<topic>" marker is the documented snippet.
     The docs check and the server's visual sample check read them; keep each marker directly
     before its code block. -->

## Freeze time with page.clock

Anything that shows the current date or time (a clock, "updated 5 minutes ago", a copyright year)
changes on every run. Fix the time before the page loads, in a `beforeEach`:

<!-- snippet:clock -->
```ts
await page.clock.setFixedTime(new Date('2026-11-19T10:00:00Z'));
```

`setFixedTime` keeps `Date.now()` and `new Date()` at that moment while timers still run. To
control timers as well, use `page.clock.install()` and advance the clock with
`page.clock.runFor()`.

## Fix the locale and time zone

Dates, numbers and currencies are formatted with the browser's locale and time zone, which differ
between your laptop and the CI runner. Set both for every test in the `use` block of
`playwright.config.ts`:

<!-- snippet:locale -->
```ts
locale: 'en-GB',
timezoneId: 'Europe/Lisbon',
```

With both fixed, `€ 100,00` and `19/11/2026, 10:00:00` render the same everywhere.

## Seed the test data

Pages that list orders, users or products change whenever the data behind them changes. Start
each test from the same data: reset the test database or create the records the page shows, with
fixed names, IDs and dates, and seed any random generator with a constant.

<!-- snippet:data -->
```ts
test.beforeEach(async ({ request }) => {
  // Your app's own test endpoint: same records, same IDs, same dates on every run.
  await request.post('/test/reset', { data: { fixture: 'shop-basic', seed: 42 } });
});
```

Prefer data your test creates over data that happens to be in a shared environment.

## Mock third-party content with page.route

Ads, maps, embedded videos, avatars from another service and A/B-test banners come from servers
you do not control. Answer those requests with a fixed response, in a `beforeEach`:

<!-- snippet:route -->
```ts
await page.route('https://ads.example.test/**', (route) =>
  route.fulfill({ path: 'fixtures/ad.png', contentType: 'image/png' }));
```

The same works for your own APIs that return changing data: fulfil them with a fixed JSON body.

## Mask what you cannot control

Some content cannot be fixed, such as a user's avatar or a live counter. Mask it: the fixture paints
masked elements in a solid colour, records their boxes with the screenshot, and the server leaves
them out of the comparison.

Every element with the attribute `data-visual-mask` is always masked, for example
`<img src="/avatar.png" alt="" data-visual-mask>`. Add your own selectors for every screenshot in
the reporter options, and one more mask for a single screenshot with Playwright's `mask` option:

<!-- snippet:mask -->
```ts
// playwright.config.ts: masked in every screenshot, in addition to [data-visual-mask]
reporter: [['@cairnreport/playwright', { visual: { mask: ['.timestamp', '[data-testid=avatar]'] } }]],

// In a test: also mask .price, for this screenshot only
await page.screenshot({ path: 'shots/cart.png', mask: [page.locator('.price')] });
```

Masks only add: the configured selectors never replace `[data-visual-mask]`, and a per-call `mask`
never replaces either. Hidden elements and selectors that match nothing give no box and no error.

For differences you cannot mask in the page, draw an ignore region on the screenshot in the Cairn
Report UI. It is saved for that screenshot or for all screenshots of the test, and left out of
future comparisons.

## Hide moving parts with a shared stylesheet

Spinners, blinking cursors, carousels and skeleton loaders are caught mid-movement. The fixture
already turns off CSS animations and hides the text caret. For the rest, write a stylesheet that
hides them, for example `visual.css` with `.spinner { visibility: hidden }`, and apply it to every
screenshot with `stylePath`:

<!-- snippet:style -->
```ts
reporter: [['@cairnreport/playwright', { visual: { stylePath: 'visual.css' } }]],
```

The path is relative to the config file. A `stylePath` on one screenshot call replaces the shared
one for that call, and Playwright's `style` option is applied after it.

## What is tracked

- Every `page.screenshot()` and `locator.screenshot()` made through the fixture, on pages of the
  test's own browser context: the `page` fixture, pages from `context.newPage()` and popups.
  **Pages of other browser contexts are not tracked**: a page of a context you create yourself
  with `browser.newContext()` is not tracked.
- Images attached with `testInfo.attach(name, { contentType: 'image/png', … })`, also without the
  fixture.
- `toHaveScreenshot` assertions. With our `expect`, a passing assertion is tracked (one extra
  screenshot right after it) and a failing one through Playwright's actual image; with
  Playwright's own `expect`, only failing assertions are tracked. The assertion, its retries and
  its messages stay Playwright's own.
- Playwright's automatic end-of-test screenshots (`screenshot: 'on'`) only with
  `trackAutoScreenshots: true`.
- Attachments named `visual:<name>` from any other language or framework.

Only PNG images are tracked. **JPEG screenshots are not tracked**: `type: 'jpeg'` or `'webp'`, a
`quality` option, or a `.jpg`, `.jpeg` or `.webp` path give an ordinary screenshot that stays a
plain attachment.

The buffer your test gets and the file written to `path` are exactly what Playwright makes with the
same options; the fixture only adds the defaults in the table below.

## Retries and noise

A screenshot that differs between retries of the same test, or between runs on the same commit, is
marked **noisy**: something on the page is still moving. Noisy screenshots show a heatmap of the
pixels that keep changing, which shows where the fix or the ignore region belongs. They cannot be
approved as a baseline until they are stable, and they do not count as changes in quality gates.

A retry that passes does not make a noisy screenshot stable. When a screenshot turns noisy, apply
the sections above to the part of the page the heatmap shows.

Small rendering differences are tolerated: a pixel counts as changed only above a colour threshold
of 0.1 (the same meaning as in Playwright), anti-aliased edges are ignored, and a screenshot is
changed only when more than 0.1 % of its pixels differ. Both values can be set per repository and
per screenshot in the Cairn Report UI.

## The visual options

Set the options in the reporter tuple of `@cairnreport/playwright`, or as the fixture option
`use: { visual: { … } }` in the config or a `test.use()`. Use the fixture option when you upload
Playwright's JSON report with `cairn upload playwright` instead of the native reporter. Later
layers win: the defaults, then the reporter option, then `use.visual`, then the options of each
screenshot call.

| `visual` option | Default | Meaning |
|---|---|---|
| `mask` | `[]` | Selectors masked in every screenshot, added to `[data-visual-mask]` (always masked); a per-call `mask` adds to both |
| `maskColor` | `'#FF00FF'` | Colour of the masked boxes |
| `animations` | `'disabled'` | `'disabled'` or `'allow'` |
| `caret` | `'hide'` | `'hide'` or `'initial'` |
| `scale` | `'css'` | `'css'` or `'device'` |
| `stylePath` | none | Stylesheet or list of stylesheets applied to every screenshot, relative to the config file |
| `trackAutoScreenshots` | `false` | Also track Playwright's automatic end-of-test screenshots (`screenshot: 'on'`) |
| `trackToHaveScreenshot` | `true` | Track passing `toHaveScreenshot` assertions made with our `expect` (failing ones are always tracked) |
| `disabled` | `false` | Turn tracking off: screenshots pass through unchanged |

Each default can also be overridden for one call with Playwright's own screenshot options
(`animations`, `caret`, `scale`, `maskColor`, `style`). The screenshot methods accept two more
options, which are not passed to Playwright: `name`, the name the screenshot is tracked under, and
`stylePath`.

A screenshot is named after its `name` option, else the file name of its `path` without the
extension (`shots/home.png` is `home`), else the title of the innermost `test.step`, else
`screenshot`. A name repeated in one test attempt becomes `home#2`, `home#3`. Keep names stable:
the name is how a screenshot is matched with its baseline from run to run.
