# Skill: a11y-bug-repro

Generate minimal Electron Fiddle apps that reproduce Chromium accessibility bugs.

## Invocation

User-invocable via `/a11y-bug-repro`.

## Input

The user provides a Chromium accessibility bug description, which may include:
- A crbug URL or bug ID
- A description of the expected vs actual accessibility behavior
- The platform(s) affected
- Relevant ARIA roles, properties, or events

## Output

A set of Electron Fiddle files in `a11y-repros/<bug-slug>/`:
- `main.js` — Main process: creates a BrowserWindow with accessibility features enabled
- `preload.js` — Preload script (contextBridge if needed)
- `renderer.js` — Renderer-side JS that manipulates the DOM to trigger the bug
- `index.html` — Minimal HTML with ARIA markup demonstrating the issue
- `package.json` — Minimal package.json so the repro can be run standalone

## Instructions

When generating a repro:

1. **Understand the bug**: Identify the specific accessibility event, role, or property that is broken. If a crbug URL is provided, fetch it or ask the user for the key details.

2. **Keep it minimal**: The repro should contain the absolute minimum DOM and JS needed to trigger the bug. No frameworks, no styling beyond basic visibility.

3. **Main process setup**:
   - Create a single `BrowserWindow`
   - Set `webPreferences.preload` to the preload script path
   - Load `index.html` via a file URL or `loadFile`
   - Optionally enable `app.accessibilitySupport = 'on'` if needed

4. **HTML structure**:
   - Use semantic ARIA roles/attributes that trigger the bug
   - Include clear labels so elements are identifiable in Accessibility Inspector
   - Add buttons/controls that let the user trigger the buggy behavior interactively

5. **Renderer script**:
   - Wire up button clicks to DOM mutations that trigger the a11y issue
   - Use `setTimeout` or `requestAnimationFrame` if timing matters
   - Log accessibility-relevant state changes to the console

6. **Testing instructions**: Include a comment block at the top of `index.html` explaining:
   - How to test with macOS Accessibility Inspector (Xcode > Open Developer Tool > Accessibility Inspector)
   - What to look for in the Inspector's notification log (Window > Show Notifications)
   - Expected behavior (with fix) vs actual behavior (without fix)

7. **File naming**: Use a descriptive slug based on the bug, e.g., `menu-popup-start`, `live-region-announce`, `focus-lost-on-hide`.

## Fiddle Compatibility

Files should work both as an Electron Fiddle project (paste into Fiddle's panels) and when run directly via:
```bash
e start a11y-repros/<bug-slug>/
```

## Reference

See `references/fiddle-template.md` for the base template structure.
