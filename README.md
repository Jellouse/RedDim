# RedDim

Tiny macOS menubar app for **reducing blue light for better sleep**. Dims non-red colours on screen; red stays relatively strong, so evenings feel warmer without a full orange wash.

## Install

Download `RedDim.app.zip` from the [latest release](https://github.com/Jellouse/RedDim/releases/latest), unzip, open. Unsigned local build: right-click → Open the first time, or `xattr -cr RedDim.app`.

## Build

Needs Command Line Tools (full Xcode optional):

```bash
git clone https://github.com/Jellouse/RedDim.git
cd RedDim
./scripts/package-app.sh
open RedDim.app
```

## Controls

- **On/Off** — remembers last intensity
- **Auto sunset** — ramps up over 30 minutes after sunset to the slider cap; ramps down over 30 minutes after sunrise (for night wind-down / morning fade-out)
- **Slider** — intensity, or “up to X%” when Auto is on
- **Applied** — current effective %

Location optional (defaults Berlin) for sunrise/sunset timing.

## How it works

`CGSetDisplayTransferByTable` on all active displays: keep the red curve, compress green/blue (less short-wavelength light). No ScreenCaptureKit overlay.

Independent channel LUTs cannot do true ±15–20° hue soft-falloff; this is a visible channel approximation aimed at sleep-friendly evenings, not a medical device.

## Limits

Night Shift / True Tone / f.lux can drift red→orange; HDR / exclusive-fullscreen may bypass; red UI chrome will scream; skin tones shift.

## License

MIT
