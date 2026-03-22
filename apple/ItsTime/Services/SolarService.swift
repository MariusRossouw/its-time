import Foundation
import CoreLocation

/// Calculates sunrise/sunset times using the NOAA solar equations.
/// Provides day/night boundaries for the calendar view based on device location.
@MainActor @Observable
final class SolarService {
    static let shared = SolarService()

    var sunrise: Date?
    var sunset: Date?
    var civilDawn: Date? // first light
    var civilDusk: Date? // last light
    var lastLocation: CLLocationCoordinate2D?
    var isUsingDefaults: Bool = true

    private init() {}

    /// Update solar times for a given location and date.
    func update(for coordinate: CLLocationCoordinate2D, date: Date = Date()) {
        lastLocation = coordinate
        isUsingDefaults = false

        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        let tz = TimeZone.current
        let tzOffset = Double(tz.secondsFromGMT(for: date)) / 3600.0

        let lat = coordinate.latitude
        let lon = coordinate.longitude

        sunrise = solarEvent(dayOfYear: dayOfYear, year: year, lat: lat, lon: lon, tzOffset: tzOffset, zenith: 90.833, rising: true, date: date)
        sunset = solarEvent(dayOfYear: dayOfYear, year: year, lat: lat, lon: lon, tzOffset: tzOffset, zenith: 90.833, rising: false, date: date)
        civilDawn = solarEvent(dayOfYear: dayOfYear, year: year, lat: lat, lon: lon, tzOffset: tzOffset, zenith: 96.0, rising: true, date: date)
        civilDusk = solarEvent(dayOfYear: dayOfYear, year: year, lat: lat, lon: lon, tzOffset: tzOffset, zenith: 96.0, rising: false, date: date)
    }

    /// Hour (with fractional minutes) for sunrise. Falls back to 6.0.
    var sunriseHour: Double {
        guard let sunrise else { return 6.0 }
        let cal = Calendar.current
        let h = cal.component(.hour, from: sunrise)
        let m = cal.component(.minute, from: sunrise)
        return Double(h) + Double(m) / 60.0
    }

    /// Hour (with fractional minutes) for sunset. Falls back to 18.0.
    var sunsetHour: Double {
        guard let sunset else { return 18.0 }
        let cal = Calendar.current
        let h = cal.component(.hour, from: sunset)
        let m = cal.component(.minute, from: sunset)
        return Double(h) + Double(m) / 60.0
    }

    /// Rounded sunrise hour for display markers.
    var sunriseMarkerHour: Int {
        Int(sunriseHour.rounded())
    }

    /// Rounded sunset marker hour for display.
    var sunsetMarkerHour: Int {
        Int(sunsetHour.rounded())
    }

    /// Evening begins roughly 1 hour before sunset.
    var eveningStartHour: Int {
        max(sunsetMarkerHour - 1, 12)
    }

    /// Night begins roughly 1.5 hours after sunset.
    var nightStartHour: Int {
        min(sunsetMarkerHour + 2, 23)
    }

    /// Noon marker hour — always 12.
    var noonHour: Int { 12 }

    /// Determine time-of-day period for a given hour.
    func period(for hour: Int) -> DayPeriod {
        if hour < sunriseMarkerHour { return .night }
        if hour < noonHour { return .morning }
        if hour < eveningStartHour { return .afternoon }
        if hour < nightStartHour { return .evening }
        return .night
    }

    /// Whether this hour should show a solar marker.
    func marker(for hour: Int) -> SolarMarker? {
        if hour == sunriseMarkerHour { return .sunrise }
        if hour == noonHour { return .noon }
        if hour == sunsetMarkerHour { return .sunset }
        if hour == nightStartHour { return .night }
        return nil
    }

    /// All hours that have markers (for padding adjustment).
    var markerHours: Set<Int> {
        [sunriseMarkerHour, noonHour, sunsetMarkerHour, nightStartHour]
    }

    // MARK: - NOAA Solar Calculation

    private func solarEvent(dayOfYear: Int, year: Int, lat: Double, lon: Double, tzOffset: Double, zenith: Double, rising: Bool, date: Date) -> Date? {
        let n = Double(dayOfYear)

        // Approximate time
        let lngHour = lon / 15.0
        let t: Double
        if rising {
            t = n + (6.0 - lngHour) / 24.0
        } else {
            t = n + (18.0 - lngHour) / 24.0
        }

        // Sun's mean anomaly
        let M = (0.9856 * t) - 3.289

        // Sun's true longitude
        var L = M + (1.916 * sin(M.radians)) + (0.020 * sin(2.0 * M.radians)) + 282.634
        L = L.truncatingRemainder(dividingBy: 360.0)
        if L < 0 { L += 360.0 }

        // Sun's right ascension
        var RA = atan(0.91764 * tan(L.radians)).degrees
        RA = RA.truncatingRemainder(dividingBy: 360.0)
        if RA < 0 { RA += 360.0 }

        // Adjust RA to same quadrant as L
        let Lquadrant = (floor(L / 90.0)) * 90.0
        let RAquadrant = (floor(RA / 90.0)) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        RA = RA / 15.0

        // Sun's declination
        let sinDec = 0.39782 * sin(L.radians)
        let cosDec = cos(asin(sinDec))

        // Hour angle
        let cosH = (cos(zenith.radians) - (sinDec * sin(lat.radians))) / (cosDec * cos(lat.radians))

        // Sun never rises/sets at this location on this date
        if cosH > 1.0 || cosH < -1.0 { return nil }

        let H: Double
        if rising {
            H = 360.0 - acos(cosH).degrees
        } else {
            H = acos(cosH).degrees
        }
        let Hhours = H / 15.0

        // Local mean time
        let T = Hhours + RA - (0.06571 * t) - 6.622

        // UTC time
        var UT = T - lngHour
        UT = UT.truncatingRemainder(dividingBy: 24.0)
        if UT < 0 { UT += 24.0 }

        // Local time
        var localTime = UT + tzOffset
        if localTime < 0 { localTime += 24.0 }
        if localTime >= 24.0 { localTime -= 24.0 }

        let hours = Int(localTime)
        let minutes = Int((localTime - Double(hours)) * 60)

        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hours
        comps.minute = minutes
        comps.second = 0
        return cal.date(from: comps)
    }
}

// MARK: - Types

enum DayPeriod: String {
    case morning, afternoon, evening, night
}

enum SolarMarker {
    case sunrise, noon, sunset, night

    var icon: String {
        switch self {
        case .sunrise: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .sunset: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .sunrise: return .orange
        case .noon: return .yellow
        case .sunset: return .indigo
        case .night: return .gray
        }
    }
}

import SwiftUI

// MARK: - Angle helpers

private extension Double {
    var radians: Double { self * .pi / 180.0 }
    var degrees: Double { self * 180.0 / .pi }
}
