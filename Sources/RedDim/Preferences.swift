import Foundation

enum Preferences {
    private static let defaults = UserDefaults.standard
    private static let enabledKey = "redDim.enabled"
    private static let intensityKey = "redDim.intensity"
    private static let autoKey = "redDim.autoSun"
    private static let latKey = "redDim.latitude"
    private static let lonKey = "redDim.longitude"

    static var isEnabled: Bool {
        get { defaults.object(forKey: enabledKey) as? Bool ?? false }
        set { defaults.set(newValue, forKey: enabledKey) }
    }

    /// Cap / manual intensity 0...100. When Auto is on, this is "up to X%".
    static var intensity: Double {
        get {
            if defaults.object(forKey: intensityKey) == nil { return 70 }
            return defaults.double(forKey: intensityKey)
        }
        set { defaults.set(min(100, max(0, newValue)), forKey: intensityKey) }
    }

    static var autoSun: Bool {
        get { defaults.object(forKey: autoKey) as? Bool ?? false }
        set { defaults.set(newValue, forKey: autoKey) }
    }

    /// Berlin default (Johann TZ Europe/Berlin); override when CoreLocation succeeds.
    static var latitude: Double {
        get {
            if defaults.object(forKey: latKey) == nil { return 52.52 }
            return defaults.double(forKey: latKey)
        }
        set { defaults.set(newValue, forKey: latKey) }
    }

    static var longitude: Double {
        get {
            if defaults.object(forKey: lonKey) == nil { return 13.405 }
            return defaults.double(forKey: lonKey)
        }
        set { defaults.set(newValue, forKey: lonKey) }
    }
}
