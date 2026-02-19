//
//  PrilaDataProcessor.swift
//  Prila6
//
//  Hydro Guru – data processing utilities.
//

import Foundation

final class PrilaDataProcessor {

    static func hydroProcessResourceData(_ input: String) -> String? {
        guard let hydroData = Data(base64Encoded: input) else {
            return nil
        }
        return String(data: hydroData, encoding: .utf8)
    }

    static func hydroGetProcessedResource() -> String? {
        let hydroRawData = PrilaResourceProvider.hydroGetResourceConfiguration()
        return hydroProcessResourceData(hydroRawData)
    }
}
