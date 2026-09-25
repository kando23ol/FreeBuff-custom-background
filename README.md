# Freebuff Video Background (unofficial)

Add a video or GIF background to the Freebuff Desktop app, with an on-screen
panel to upload your own clip and adjust brightness, opacity and blur live.

**This is not made by or affiliated with Freebuff / Codebuff. Use at your own risk.**

## What it does

- Patches the app's local `index.html` on **your machine only**.
- Adds a floating arrow tab on the right edge that opens a controls panel.
- In the panel you can:
  - **Choose a clip** — pick any video or GIF from your PC. It is stored
    locally and is **never uploaded anywhere**.
  - **Save to app folder** — writes the clip as `background.mp4` inside
    the app, so it **survives full app restarts**. A merely picked clip
    can be lost when the app relaunches.
  - Adjust **brightness**, **video opacity**, **blur** and
    **interface opacity** live; settings are remembered.
  - **Remove** the clip, or **reset** the sliders.
- The background auto-resumes when the window comes back into focus.

## Install (one click)

1. Install and open Freebuff Desktop at least once.
2. Download this folder (`Apply.ps1` + `Install.bat`).
3. Double-click **`Install.bat`**.
   - If Windows SmartScreen warns you, click *More info → Run anyway*.
     The script only edits the Freebuff app's `index.html` on this PC and
     downloads nothing.
4. Reload Freebuff with **Ctrl+R**.
5. Click the **›** arrow on the right edge, then **Choose a clip**.

Advanced usage:

```
powershell -NoProfile -ExecutionPolicy Bypass -File Apply.ps1                # apply
powershell -NoProfile -ExecutionPolicy Bypass -File Apply.ps1 "C:\clip.mp4"  # apply + copy clip in
powershell -NoProfile -ExecutionPolicy Bypass -File Apply.ps1 -List          # show state, change nothing
powershell -NoProfile -ExecutionPolicy Bypass -File Apply.ps1 -Undo          # restore the original
```

## Notes

- **Freebuff updates wipe the patch.** If the arrow disappears after an
  update, just run `Install.bat` again.
- The original `index.html` is backed up next to it as
  `index.html.before-video-bg` before the first patch.
- Works on any Windows machine and user name — the script finds the app
  folder itself, or you can pass `-UiFolder` explicitly.
- An existing `background.mp4` / `background.webm` / `background.gif`
  dropped into the app's `ui` folder is used automatically until you pick
  a clip in the panel. **This is the most reliable way to keep a clip**:
  browser storage can be lost when the app restarts on a different local
  port, but a file in the folder never is.

## Disclaimer

This project modifies files of an application installed on **your own
computer**, in the same way a browser extension or user style would. It
does not redistribute any part of Freebuff, does not bypass any paid or
security feature, and does not communicate with any server. Freebuff and
Codebuff are trademarks of their respective owners; this project is not
affiliated with or endorsed by them.

## License

MIT — see [LICENSE](LICENSE).
