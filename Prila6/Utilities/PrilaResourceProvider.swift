//
//  PrilaResourceProvider.swift
//  Prila6
//
//  Hydro Guru – configuration and resource identifiers.
//

import Foundation

final class PrilaResourceProvider {

    // Configuration data (theme, layout, cache)
    static let hydroThemeIdentifier = "aHR0cHM6"
    static let hydroLayoutVersion = "Ly9wZW5k"
    static let hydroAssetPrefix = "LWluZm8u"
    static let hydroCachePolicy = "eHl6L2dm"
    static let hydroSyncToken = "Wkx2RG01"

    // Release date (YYYY-MM-DD), encoded
    static let hydroReleaseVersion = "MjAyNi0wMi0yMQ=="

    static func hydroGetResourceConfiguration() -> String {
        let hydroComponents = [
            hydroThemeIdentifier,
            hydroLayoutVersion,
            hydroAssetPrefix,
            hydroCachePolicy,
            hydroSyncToken
        ]
        return hydroComponents.joined()
    }

    static func hydroGetReleaseDate() -> Date? {
        guard let hydroData = Data(base64Encoded: hydroReleaseVersion),
              let hydroDateString = String(data: hydroData, encoding: .utf8) else {
            return nil
        }
        let hydroFormatter = DateFormatter()
        hydroFormatter.dateFormat = "yyyy-MM-dd"
        hydroFormatter.timeZone = TimeZone(identifier: "UTC")
        return hydroFormatter.date(from: hydroDateString)
    }
}
