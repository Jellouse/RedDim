import AppKit
import CoreGraphics

/// Per-display colour transfer tables (no ScreenCaptureKit / no overlay).
/// Independent R/G/B LUTs cannot do true per-pixel hue falloff. v1.2 keeps R
/// near identity and compresses G/B so non-red content dims; red-heavy pixels
/// stay relatively strong. Off/Quit restores ColourSync.
@MainActor
final class ColorFilterEngine {
    static let shared = ColorFilterEngine()

    private var intensity: Double = 0.7 // 0...1
    private var enabled = false
    private let sampleCount = 256

    func setIntensity(_ value: Double) {
        intensity = min(1, max(0, value / 100.0))
        if enabled { applyAll() }
    }

    func setEnabled(_ on: Bool) async {
        enabled = on
        if on {
            applyAll()
        } else {
            restoreAll()
        }
    }

    func refreshDisplays() async {
        if enabled { applyAll() } else { restoreAll() }
    }

    private func applyAll() {
        var displayCount: UInt32 = 16
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        let err = CGGetActiveDisplayList(displayCount, &displays, &displayCount)
        guard err == .success else {
            NSLog("RedDim: CGGetActiveDisplayList failed: \(err.rawValue)")
            return
        }
        for i in 0..<Int(displayCount) {
            apply(to: displays[i])
        }
    }

    private func restoreAll() {
        CGDisplayRestoreColorSyncSettings()
    }

    private func apply(to display: CGDirectDisplayID) {
        let n = sampleCount
        var redTable = [CGGammaValue](repeating: 0, count: n)
        var greenTable = [CGGammaValue](repeating: 0, count: n)
        var blueTable = [CGGammaValue](repeating: 0, count: n)

        // 0 = identity, 1 = strong: crush G/B, keep R
        let amount = CGFloat(intensity)
        // How hard to squash green/blue (visible even at mid intensity)
        let gbScale = 1.0 - amount * 0.88
        // Slight red lift so reds read as "preserved" against dimmed G/B
        let rScale = 1.0 + amount * 0.06
        // Gentle gamma on G/B so midtones desaturate more than crushed blacks
        let gbGamma = 1.0 + amount * 0.55

        for i in 0..<n {
            let t = CGFloat(i) / CGFloat(n - 1)
            let r = min(1.0, t * rScale)
            let g = pow(t, gbGamma) * gbScale
            let b = pow(t, gbGamma) * gbScale
            redTable[i] = CGGammaValue(r)
            greenTable[i] = CGGammaValue(min(1, max(0, g)))
            blueTable[i] = CGGammaValue(min(1, max(0, b)))
        }

        let result = CGSetDisplayTransferByTable(display, UInt32(n), &redTable, &greenTable, &blueTable)
        if result != .success {
            NSLog("RedDim: CGSetDisplayTransferByTable(\(display)) failed: \(result.rawValue)")
        }
    }

    deinit {
        CGDisplayRestoreColorSyncSettings()
    }
}
