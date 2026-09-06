import Foundation

enum Solar {
    /// Returns (sunrise, sunset) in local timezone for the given calendar day.
    static func sunTimes(for date: Date, latitude: Double, longitude: Double, calendar: Calendar = .current) -> (sunrise: Date, sunset: Date)? {
        var cal = calendar
        cal.timeZone = .current
        let dayStart = cal.startOfDay(for: date)
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)

        let latRad = latitude * .pi / 180
        // Fractional year
        let gamma = 2 * .pi / 365.0 * (dayOfYear - 1)
        // Equation of time (minutes) and solar declination
        let eqTime = 229.18 * (0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2 * gamma)
            - 0.040849 * sin(2 * gamma))
        let decl = 0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)

        // Hour angle for sunrise (zenith 90.833°)
        let zenith = 90.833 * .pi / 180
        let cosHA = (cos(zenith) / (cos(latRad) * cos(decl))) - tan(latRad) * tan(decl)
        guard cosHA >= -1, cosHA <= 1 else { return nil } // polar day/night
        let ha = acos(cosHA) * 180 / .pi // degrees

        let noonMinutes = 720 - 4 * longitude - eqTime
        let riseMinutes = noonMinutes - 4 * ha
        let setMinutes = noonMinutes + 4 * ha

        func dateFromMinutes(_ m: Double) -> Date {
            dayStart.addingTimeInterval(m * 60)
        }
        return (dateFromMinutes(riseMinutes), dateFromMinutes(setMinutes))
    }

    /// Night factor 0...1 for auto ramp.
    /// Sunset: 0 → 1 over `rampSeconds` starting at sunset.
    /// Sunrise: 1 → 0 over `rampSeconds` starting at sunrise.
    /// Overnight between: 1. Daytime before next sunset: 0.
    static func nightFactor(at now: Date, latitude: Double, longitude: Double, rampSeconds: TimeInterval = 30 * 60) -> Double {
        let cal = Calendar.current
        guard let today = sunTimes(for: now, latitude: latitude, longitude: longitude, calendar: cal) else {
            return 0
        }
        let yesterdayDate = cal.date(byAdding: .day, value: -1, to: now) ?? now
        let tomorrowDate = cal.date(byAdding: .day, value: 1, to: now) ?? now
        let yesterday = sunTimes(for: yesterdayDate, latitude: latitude, longitude: longitude, calendar: cal)
        let tomorrow = sunTimes(for: tomorrowDate, latitude: latitude, longitude: longitude, calendar: cal)

        let sunrise = today.sunrise
        let sunset = today.sunset

        // After today's sunrise ramp-down window until sunset: day
        let sunriseEnd = sunrise.addingTimeInterval(rampSeconds)
        let sunsetEnd = sunset.addingTimeInterval(rampSeconds)

        if now < sunrise {
            // Before sunrise: still night from yesterday's sunset ramp
            if let y = yesterday {
                let ySunset = y.sunset
                let ySunsetEnd = ySunset.addingTimeInterval(rampSeconds)
                if now < ySunset { return 0 }
                if now < ySunsetEnd {
                    return (now.timeIntervalSince(ySunset)) / rampSeconds
                }
                return 1
            }
            return 1
        }

        if now < sunriseEnd {
            // Ramping down at sunrise
            let t = now.timeIntervalSince(sunrise) / rampSeconds
            return max(0, 1 - t)
        }

        if now < sunset {
            return 0 // daytime
        }

        if now < sunsetEnd {
            // Ramping up at sunset
            return min(1, now.timeIntervalSince(sunset) / rampSeconds)
        }

        // After sunset ramp until midnight / next sunrise
        if let tmr = tomorrow, now < tmr.sunrise {
            return 1
        }
        return 1
    }
}
