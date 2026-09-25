<#
    Freebuff video background - single file installer.
    The CSS and the panel markup are embedded below, so this file needs no
    companion files. Copy it anywhere and run it.

    Works on any Windows machine and any user name, because it finds the
    Freebuff app folder instead of assuming a path.

    Usage:
      .\Apply.ps1                      apply the patch
      .\Apply.ps1 "C:\clip.mp4"        apply, and copy that clip in
      .\Apply.ps1 -List                show what it found, change nothing
      .\Apply.ps1 -Undo                restore the original file

    Windows blocks .ps1 files by default, so run it like this:
      powershell -NoProfile -ExecutionPolicy Bypass -File Apply.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Clip,
    [string]$UiFolder,
    [switch]$Undo,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

$StyleBlock = @'
<!-- ==== Freebuff video background ==== -->
  <style>
    /* Defaults only. The on-screen panel overrides these live and remembers
       your choice, so you normally never edit this file by hand. */
    :root, :root[data-theme=dark], :root[data-theme=light] {
      --fbv-video-opacity: 0.5;
      --fbv-video-dim: 0.5;
      --fbv-video-blur: 0px;
      --fbv-panel-alpha: 0.62;
      --fbv-panel-w: 296px;
    }

    #freebuff-video-bg, #freebuff-video-bg-img {
      position: fixed; inset: 0; width: 100vw; height: 100vh;
      object-fit: cover; z-index: 0; pointer-events: none;
      opacity: var(--fbv-video-opacity);
      filter: brightness(var(--fbv-video-dim)) blur(var(--fbv-video-blur));
    }
    #freebuff-video-bg[hidden], #freebuff-video-bg-img[hidden] { display: none !important; }

    /* A colour behind the video, so a missing clip never leaves a pale window. */
    html { background: #0a0a0a !important; }
    html[data-theme=light] { background: #eef1ef !important; }
    html, body, #root { background-color: transparent !important; }
    #root { position: relative; z-index: 1; }

    /* The app paints its own surfaces from these. Making them translucent is
       what lets the video show through instead of hiding behind the UI. */
    :root, :root[data-theme=dark] {
      --bg: rgb(10 10 10 / var(--fbv-panel-alpha)) !important;
      --chrome: rgb(15 15 15 / var(--fbv-panel-alpha)) !important;
      --surface: rgb(23 23 23 / var(--fbv-panel-alpha)) !important;
      --surface-2: rgb(28 28 28 / var(--fbv-panel-alpha)) !important;
      --raised: rgb(33 33 33 / var(--fbv-panel-alpha)) !important;
    }
    :root[data-theme=light] {
      --bg: rgb(244 246 245 / var(--fbv-panel-alpha)) !important;
      --chrome: rgb(237 241 238 / var(--fbv-panel-alpha)) !important;
      --surface: rgb(255 255 255 / var(--fbv-panel-alpha)) !important;
      --surface-2: rgb(244 246 245 / var(--fbv-panel-alpha)) !important;
      --raised: rgb(255 255 255 / var(--fbv-panel-alpha)) !important;
    }

    /* ---------- the controls panel, docked right ---------- */
    #fbv-panel *, #fbv-panel *::before, #fbv-panel *::after { box-sizing: border-box; }
    #fbv-panel {
      box-sizing: border-box;
      position: fixed; top: 0; right: 0; height: 100vh; width: var(--fbv-panel-w);
      z-index: 2147483000;
      background: rgb(11 13 17 / 0.88);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border-left: 1px solid rgb(255 255 255 / 0.13);
      color: #e8edf4;
      font: 13px/1.45 ui-sans-serif, system-ui, "Segoe UI", Roboto, sans-serif;
      overflow-y: auto;
      padding: 16px 16px 48px;
      transition: transform 0.22s ease;
    }
    body.fbv-collapsed #fbv-panel { transform: translateX(var(--fbv-panel-w)); }

    #fbv-toggle {
      box-sizing: border-box;
      position: fixed; top: 50%; right: var(--fbv-panel-w); transform: translateY(-50%);
      width: 34px; height: 76px; z-index: 2147483001;
      display: flex; align-items: center; justify-content: center;
      background: rgb(42 50 64 / 0.98);
      color: #ffffff;
      border: 1px solid rgb(150 175 215 / 0.55); border-right: 0;
      border-radius: 11px 0 0 11px;
      box-shadow: -8px 0 26px rgb(0 0 0 / 0.5);
      cursor: pointer; padding: 0; font-size: 23px; font-weight: 700; line-height: 1;
      transition: right 0.22s ease, background 0.15s;
    }
    #fbv-toggle:hover { background: rgb(64 100 168 / 0.98); }
    body.fbv-collapsed #fbv-toggle { right: 0; }

    .fbv-arrow-shut { display: none; }
    body.fbv-collapsed .fbv-arrow-open { display: none; }
    body.fbv-collapsed .fbv-arrow-shut { display: inline; }

    #fbv-panel .fbv-head {
      display: flex; align-items: flex-start; justify-content: space-between; gap: 8px;
      margin: 0 0 3px;
    }
    #fbv-panel h3 { margin: 0; font-size: 13px; font-weight: 600; letter-spacing: 0.2px; }
    #fbv-panel #fbv-hide {
      box-sizing: border-box; flex: none;
      background: rgb(255 255 255 / 0.1); color: #e8edf4;
      border: 1px solid rgb(255 255 255 / 0.22); border-radius: 7px;
      padding: 4px 9px; font: inherit; font-size: 11.5px; cursor: pointer;
    }
    #fbv-panel #fbv-hide:hover { background: rgb(255 255 255 / 0.2); }
    #fbv-panel .fbv-sub {
      margin: 0 0 13px; font-size: 11px; color: #8d9aab;
      overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    #fbv-panel .fbv-group { border-top: 1px solid rgb(255 255 255 / 0.1); padding-top: 12px; margin-top: 13px; }
    #fbv-panel label { display: block; margin-bottom: 11px; font-size: 11.5px; color: #8d9aab; }
    #fbv-panel label:last-child { margin-bottom: 0; }
    #fbv-panel .fbv-row { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 5px; gap: 8px; }
    #fbv-panel .fbv-val { color: #e8edf4; font-variant-numeric: tabular-nums; }
    #fbv-panel input[type=range] { width: 100%; margin: 0; accent-color: #5b8cff; }
    #fbv-panel button.fbv-btn {
      width: 100%; background: rgb(255 255 255 / 0.07); color: #e8edf4;
      border: 1px solid rgb(255 255 255 / 0.15); border-radius: 8px;
      padding: 8px 10px; font: inherit; font-size: 12.5px; cursor: pointer;
    }
    #fbv-panel button.fbv-btn:hover { background: rgb(255 255 255 / 0.14); }
    #fbv-panel button.fbv-btn.primary { background: #5b8cff; border-color: #5b8cff; color: #05101f; font-weight: 600; }
    #fbv-panel button.fbv-btn.primary:hover { background: #7ba3ff; }
    #fbv-panel .fbv-btns { display: flex; gap: 7px; }
    #fbv-panel .fbv-btns > button { flex: 1 1 auto; }
    #fbv-panel .fbv-hint { margin: 9px 0 0; font-size: 10.5px; line-height: 1.5; color: #7f8c9d; }
    #fbv-panel .fbv-state { margin: 0; font-size: 11.5px; color: #e8edf4; }
  </style>
<!-- ==== end Freebuff video background ==== -->
'@

$PanelBlock = @'
<!-- ==== Freebuff video background ==== -->
    <video id="freebuff-video-bg" autoplay muted loop playsinline preload="auto">
      <source src="./background.mp4" type="video/mp4" />
      <source src="./background.webm" type="video/webm" />
    </video>

    <img id="freebuff-video-bg-img" src="./background.gif" alt="" />

    <button id="fbv-toggle" title="Hide the background controls" aria-controls="fbv-panel" aria-expanded="true">
      <span class="fbv-arrow-open">&#8250;</span>
      <span class="fbv-arrow-shut">&#8249;</span>
    </button>

    <div id="fbv-panel">
      <div class="fbv-head">
        <h3>Background video</h3>
        <button id="fbv-hide" type="button" title="Hide the controls">Hide &#8250;</button>
      </div>
      <p class="fbv-sub" id="fbv-status">No clip chosen.</p>

      <input type="file" id="fbv-file" accept="video/*,image/*" hidden />
      <div class="fbv-btns">
        <button class="fbv-btn primary" id="fbv-choose">Choose a clip</button>
        <button class="fbv-btn" id="fbv-remove">Remove</button>
      </div>
      <p class="fbv-hint">The clip is kept inside the app, so it survives a reload. Nothing is uploaded anywhere.</p>

      <div class="fbv-group">
        <label>
          <span class="fbv-row"><span>Brightness</span><span class="fbv-val" id="fbv-v-brightness">50%</span></span>
          <input type="range" id="fbv-brightness" min="0" max="100" value="50" />
        </label>
        <label>
          <span class="fbv-row"><span>Video opacity</span><span class="fbv-val" id="fbv-v-opacity">50%</span></span>
          <input type="range" id="fbv-opacity" min="0" max="100" value="50" />
        </label>
        <label>
          <span class="fbv-row"><span>Blur</span><span class="fbv-val" id="fbv-v-blur">0px</span></span>
          <input type="range" id="fbv-blur" min="0" max="30" value="0" />
        </label>
        <label>
          <span class="fbv-row"><span>Interface opacity</span><span class="fbv-val" id="fbv-v-panel">62%</span></span>
          <input type="range" id="fbv-panel-alpha" min="0" max="100" value="62" />
        </label>
        <p class="fbv-hint">Interface opacity sets how much the app covers the video. Lower shows more of the clip.</p>
      </div>

      <div class="fbv-group">
        <p class="fbv-state" id="fbv-play-state">Checking.</p>
        <p class="fbv-hint">While the app is in the background the browser may pause the clip to save power. It is resumed the moment you come back.</p>
      </div>

      <div class="fbv-group">
        <button class="fbv-btn" id="fbv-reset">Reset the sliders</button>
      </div>
    </div>

    <script>
      (function () {
        'use strict';

        var DEFAULTS = { brightness: 50, opacity: 50, blur: 0, panelAlpha: 62, collapsed: false };
        var LS_KEY = 'fbv:settings';
        var DB_NAME = 'freebuff-video-bg';
        var STORE = 'clips';
        var COLLAPSED = 'fbv-collapsed';

        var settings = Object.assign({}, DEFAULTS);
        var video = document.getElementById('freebuff-video-bg');
        var img = document.getElementById('freebuff-video-bg-img');
        var clipUrl = null;

        function $(id) { return document.getElementById(id); }
        function clamp(v, lo, hi) { return Math.min(hi, Math.max(lo, v)); }
        function megabytes(bytes) { return (bytes / 1048576).toFixed(1); }
        function setStatus(text) { $('fbv-status').textContent = text; }

        function loadSettings() {
          var saved = {};
          try { saved = JSON.parse(window.localStorage.getItem(LS_KEY) || '{}') || {}; } catch (err) { saved = {}; }
          Object.keys(DEFAULTS).forEach(function (key) {
            if (typeof saved[key] === typeof DEFAULTS[key]) settings[key] = saved[key];
          });
          settings.brightness = clamp(settings.brightness, 0, 100);
          settings.opacity = clamp(settings.opacity, 0, 100);
          settings.blur = clamp(settings.blur, 0, 30);
          settings.panelAlpha = clamp(settings.panelAlpha, 0, 100);
        }

        function saveSettings() {
          try { window.localStorage.setItem(LS_KEY, JSON.stringify(settings)); } catch (err) {}
        }

        function apply() {
          var root = document.documentElement.style;
          root.setProperty('--fbv-video-opacity', String(settings.opacity / 100));
          root.setProperty('--fbv-video-dim', String(settings.brightness / 100));
          root.setProperty('--fbv-video-blur', settings.blur + 'px');
          root.setProperty('--fbv-panel-alpha', String(settings.panelAlpha / 100));
          document.body.classList.toggle(COLLAPSED, settings.collapsed);

          $('fbv-brightness').value = String(settings.brightness);
          $('fbv-opacity').value = String(settings.opacity);
          $('fbv-blur').value = String(settings.blur);
          $('fbv-panel-alpha').value = String(settings.panelAlpha);
          $('fbv-v-brightness').textContent = settings.brightness + '%';
          $('fbv-v-opacity').textContent = settings.opacity + '%';
          $('fbv-v-blur').textContent = settings.blur + 'px';
          $('fbv-v-panel').textContent = settings.panelAlpha + '%';

          var toggle = $('fbv-toggle');
          toggle.title = settings.collapsed ? 'Show the background controls' : 'Hide the background controls';
          toggle.setAttribute('aria-expanded', settings.collapsed ? 'false' : 'true');
        }

        function openDb() {
          return new Promise(function (resolve, reject) {
            var request = window.indexedDB.open(DB_NAME, 1);
            request.onupgradeneeded = function () { request.result.createObjectStore(STORE); };
            request.onsuccess = function () { resolve(request.result); };
            request.onerror = function () { reject(request.error); };
          });
        }

        function storage(mode, action) {
          return openDb().then(function (db) {
            return new Promise(function (resolve, reject) {
              var tx = db.transaction(STORE, mode);
              var request = action(tx.objectStore(STORE));
              tx.oncomplete = function () { resolve(request ? request.result : undefined); };
              tx.onerror = function () { reject(tx.error); };
              tx.onabort = function () { reject(tx.error); };
            });
          });
        }

        function showBlob(blob) {
          if (clipUrl) window.URL.revokeObjectURL(clipUrl);
          clipUrl = window.URL.createObjectURL(blob);
          var isImage = blob.type.indexOf('image/') === 0;
          video.hidden = isImage;
          img.hidden = !isImage;
          if (isImage) {
            video.pause();
            video.removeAttribute('src');
            video.load();
            img.src = clipUrl;
          } else {
            video.src = clipUrl;
            video.load();
            var started = video.play();
            if (started && started.catch) started.catch(function () {});
          }
          reportPlayState();
        }

        function clearClip() {
          if (clipUrl) { window.URL.revokeObjectURL(clipUrl); clipUrl = null; }
          video.hidden = false;
          img.hidden = false;
          video.removeAttribute('src');
          video.load();
          img.src = './background.gif';
          reportPlayState();
        }

        function restoreClip() {
          storage('readonly', function (store) { return store.get('current'); })
            .then(function (blob) {
              if (!blob) return;
              showBlob(blob);
              setStatus('Saved clip, ' + megabytes(blob.size) + ' MB');
            })
            .catch(function () {});
        }

        function bindSlider(elementId, key) {
          $(elementId).addEventListener('input', function () {
            settings[key] = Number($(elementId).value);
            saveSettings();
            apply();
          });
        }

        function setCollapsed(collapsed) {
          settings.collapsed = collapsed;
          saveSettings();
          apply();
        }

        // Bound on window in the capture phase. If the host app stops click
        // events while they bubble, a listener on the button never fires.
        function onControlClick(event) {
          var target = event.target;
          if (!target || !target.closest) return;
          if (target.closest('#fbv-toggle')) {
            setCollapsed(!settings.collapsed);
          } else if (target.closest('#fbv-hide')) {
            setCollapsed(true);
          }
        }
        window.addEventListener('click', onControlClick, true);

        $('fbv-choose').addEventListener('click', function () { $('fbv-file').click(); });

        $('fbv-file').addEventListener('change', function (event) {
          var file = event.target.files && event.target.files[0];
          event.target.value = '';
          if (!file) return;
          var isVideo = file.type.indexOf('video/') === 0;
          var isImage = file.type.indexOf('image/') === 0;
          if (!isVideo && !isImage) { setStatus('That is not a video or an image.'); return; }
          showBlob(file);
          setStatus(file.name + ' - ' + megabytes(file.size) + ' MB');
          storage('readwrite', function (store) { return store.put(file, 'current'); })
            .then(function () { setStatus(file.name + ' - ' + megabytes(file.size) + ' MB, saved'); })
            .catch(function () { setStatus(file.name + ' - could not be saved, so it resets on reload'); });
        });

        $('fbv-remove').addEventListener('click', function () {
          clearClip();
          setStatus('No clip chosen.');
          storage('readwrite', function (store) { return store.delete('current'); }).catch(function () {});
        });

        $('fbv-reset').addEventListener('click', function () {
          settings.brightness = DEFAULTS.brightness;
          settings.opacity = DEFAULTS.opacity;
          settings.blur = DEFAULTS.blur;
          settings.panelAlpha = DEFAULTS.panelAlpha;
          saveSettings();
          apply();
        });

        bindSlider('fbv-brightness', 'brightness');
        bindSlider('fbv-opacity', 'opacity');
        bindSlider('fbv-blur', 'blur');
        bindSlider('fbv-panel-alpha', 'panelAlpha');

        // ---- background behaviour ----
        // Chromium pauses a muted video whose page is hidden, to save power.
        // A page cannot stop that from the inside. What it can always do is
        // catch the moment it comes back, so the clip is already running by
        // the time anyone looks at it.
        var stateLine = $('fbv-play-state');

        function reportPlayState() {
          if (!stateLine) return;
          if (video.hidden) {
            stateLine.textContent = 'Background is a still image.';
            return;
          }
          // readyState 0 means nothing playable ever loaded. currentSrc is
          // not a safe test: it holds a value even when the file it points
          // at comes back 404.
          if (video.readyState === 0) {
            stateLine.textContent = 'No clip chosen.';
          } else if (!video.paused) {
            stateLine.textContent = document.visibilityState === 'hidden'
              ? 'Playing while the app is in the background.'
              : 'Playing.';
          } else {
            stateLine.textContent = 'Paused.';
          }
        }

        function resumeClip() {
          if (!video.hidden && video.paused && (video.currentSrc || video.src)) {
            var started = video.play();
            if (started && started.catch) started.catch(function () {});
          }
          reportPlayState();
        }

        document.addEventListener('visibilitychange', resumeClip);
        window.addEventListener('focus', resumeClip);
        window.setInterval(resumeClip, 5000);
        video.addEventListener('play', reportPlayState);
        video.addEventListener('pause', reportPlayState);

        loadSettings();
        apply();
        restoreClip();
        reportPlayState();
      })();
    </script>
<!-- ==== end Freebuff video background ==== -->
'@
$Marker    = '<!-- ==== Freebuff video background'
$EndMarker = '<!-- ==== end Freebuff video background'

function Find-FreebuffUiFolders {
    $roots = @()
    if ($env:LOCALAPPDATA)   { $roots += (Join-Path $env:LOCALAPPDATA 'Programs') }
    if ($env:PROGRAMFILES)   { $roots += $env:PROGRAMFILES }
    $x86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($x86) { $roots += $x86 }

    # Every product folder under each root, then the known names directly.
    $candidates = @()
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $dirs = @()
        $dirs += Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
        foreach ($name in @('@codebufffreebuff-desktop', 'freebuff-desktop', 'Freebuff')) {
            $named = Join-Path $root $name
            if (Test-Path -LiteralPath $named) { $dirs += (Get-Item -LiteralPath $named) }
        }
        foreach ($dir in $dirs) {
            $ui = Join-Path $dir.FullName 'resources\orchestrator\ui'
            if ($candidates -notcontains $ui) { $candidates += $ui }
        }
    }

    # Keep only folders that really are the Freebuff interface.
    $found = @()
    foreach ($ui in $candidates) {
        $index = Join-Path $ui 'index.html'
        if (-not (Test-Path -LiteralPath $index)) { continue }
        $text = [System.IO.File]::ReadAllText($index)
        if ($text -match 'Freebuff Desktop') { $found += $ui }
    }
    return $found
}

function Remove-Patch([string]$html) {
    for ($guard = 0; $guard -lt 20; $guard++) {
        $start = $html.IndexOf($Marker)
        if ($start -lt 0) { return $html }
        $endAt = $html.IndexOf($EndMarker, $start)
        if ($endAt -lt 0) { throw 'Found a start marker with no end marker. Refusing to edit.' }
        $close = $html.IndexOf('-->', $endAt)
        if ($close -lt 0) { throw 'The end marker is not closed. Refusing to edit.' }
        $after = $close + 3
        while ($after -lt $html.Length -and ($html[$after] -eq ' ' -or $html[$after] -eq "`t")) { $after++ }
        if ($after -lt $html.Length -and $html[$after] -eq "`r") { $after++ }
        if ($after -lt $html.Length -and $html[$after] -eq "`n") { $after++ }
        $html = $html.Substring(0, $start) + $html.Substring($after)
    }
    throw 'More than twenty patch chunks found. Something is wrong.'
}

function Count-Of([string]$text, [string]$token) {
    return $text.Split([string[]]@($token), [System.StringSplitOptions]::None).Count - 1
}

# --- pick the folder ----------------------------------------------------------
if ($UiFolder) {
    $ui = $UiFolder
} else {
    $found = @(Find-FreebuffUiFolders)
    if ($found.Count -eq 1) {
        $ui = $found[0]
    } elseif ($found.Count -eq 0) {
        Write-Host ''
        Write-Host 'Could not find the Freebuff app folder.' -ForegroundColor Yellow
        Write-Host 'Open Freebuff at least once, then run this again.'
        Write-Host 'If it lives somewhere unusual, pass -UiFolder with the ui folder.'
        exit 1
    } else {
        Write-Host ''
        Write-Host 'Found more than one. Pass the right one with -UiFolder:' -ForegroundColor Yellow
        foreach ($f in $found) { Write-Host ('  ' + $f) }
        exit 1
    }
}

$indexPath  = Join-Path $ui 'index.html'
$backupPath = Join-Path $ui 'index.html.before-video-bg'
if (-not (Test-Path -LiteralPath $indexPath)) { throw ('No index.html in ' + $ui) }

$raw   = [System.IO.File]::ReadAllBytes($indexPath)
$hasBom = ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF)
$enc   = if ($hasBom) { [System.Text.UTF8Encoding]::new($true) } else { [System.Text.UTF8Encoding]::new($false) }

Write-Host ''
Write-Host ('Freebuff folder: ' + $ui)
Write-Host ('index.html:      ' + $raw.Length + ' bytes')

if ($List) {
    Write-Host ('patch present:   ' + (([System.IO.File]::ReadAllText($indexPath)).Contains($Marker)))
    Write-Host ''
    exit 0
}

if ($Undo) {
    if (-not (Test-Path -LiteralPath $backupPath)) { throw ('No backup at ' + $backupPath) }
    Copy-Item -LiteralPath $backupPath -Destination $indexPath -Force
    Write-Host ''
    Write-Host 'Restored the original index.html.' -ForegroundColor Green
    exit 0
}

# --- read the two blocks ------------------------------------------------------
$styleBlock = $StyleBlock.Trim()
$panelBlock = $PanelBlock.Trim()

# --- patch --------------------------------------------------------------------
$html = [System.IO.File]::ReadAllText($indexPath)

if (-not (Test-Path -LiteralPath $backupPath)) {
    [System.IO.File]::WriteAllText($backupPath, (Remove-Patch $html), $enc)
    Write-Host ('Saved the untouched original to index.html.before-video-bg')
}

$html = Remove-Patch $html

foreach ($anchor in @('</head>', '<body>')) {
    $seen = Count-Of $html $anchor
    if ($seen -ne 1) { throw ('Expected exactly one ' + $anchor + ' but found ' + $seen + '. Refusing to edit.') }
}

$nl = if ($html.Contains("`r`n")) { "`r`n" } else { "`n" }
$html = $html.Replace('</head>', $styleBlock + $nl + '</head>')
$html = $html.Replace('<body>', '<body>' + $nl + $panelBlock)

foreach ($pair in @(@('<video id="freebuff-video-bg"', 'background video'), @('id="fbv-panel"', 'controls panel'))) {
    $n = Count-Of $html $pair[0]
    if ($n -ne 1) { throw ('Expected exactly one ' + $pair[1] + ' but found ' + $n + '. Refusing to write.') }
}

[System.IO.File]::WriteAllText($indexPath, $html, $enc)
Write-Host ('Patched. ') -NoNewline -ForegroundColor Green
Write-Host ((Get-Item -LiteralPath $indexPath).Length.ToString() + ' bytes')

if ($Clip) {
    if (-not (Test-Path -LiteralPath $Clip)) { throw ('No such file: ' + $Clip) }
    $ext  = [System.IO.Path]::GetExtension($Clip).ToLower()
    $name = if ($ext -eq '.gif') { 'background.gif' } elseif ($ext -eq '.webm') { 'background.webm' } else { 'background.mp4' }
    Copy-Item -LiteralPath $Clip -Destination (Join-Path $ui $name) -Force
    Write-Host ('Copied the clip to ' + $name) -ForegroundColor Green
}

Write-Host ''
Write-Host 'Now reload the Freebuff window with Ctrl+R.' -ForegroundColor Cyan
Write-Host 'The controls sit on the right edge; the arrow tab hides them.'
