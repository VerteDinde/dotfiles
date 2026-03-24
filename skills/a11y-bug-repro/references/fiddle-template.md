# Electron Fiddle Template for A11y Bug Repros

## main.js

```js
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 600,
    height: 400,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  win.loadFile('index.html');

  // Uncomment to open DevTools for debugging:
  // win.webContents.openDevTools();
}

app.whenReady().then(createWindow);
```

## preload.js

```js
// Add contextBridge exposures here if the repro needs IPC.
// Most a11y repros don't need preload logic.
```

## index.html

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>A11y Bug Repro</title>
</head>
<body>
  <!-- Minimal DOM for the repro -->
  <script src="./renderer.js"></script>
</body>
</html>
```

## renderer.js

```js
// DOM manipulation to trigger the accessibility bug
```

## package.json

```json
{
  "name": "a11y-repro",
  "version": "1.0.0",
  "main": "main.js"
}
```

## Testing with macOS Accessibility Inspector

1. Open Xcode, then **Xcode > Open Developer Tool > Accessibility Inspector**
2. In Accessibility Inspector, select the Electron window from the target dropdown
3. Open **Window > Show Notifications** to see accessibility events in real time
4. Interact with the repro app and observe events in the notification log
5. Compare with/without the patch to confirm the fix
