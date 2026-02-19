//
//  PrilaDisplayView.swift
//  Prila6
//
//  Hydro Guru – full-screen content view.
//

import SwiftUI
import WebKit

struct PrilaDisplayView: View {
    @StateObject private var hydroFlowController = PrilaFlowController.shared

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PrilaWebView(hydroUrl: hydroFlowController.hydroTargetEndpoint ?? "")
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct PrilaWebView: UIViewRepresentable {
    let hydroUrl: String

    func makeUIView(context: Context) -> WKWebView {
        let hydroConfig = WKWebViewConfiguration()
        let hydroPrefs = WKWebpagePreferences()
        hydroPrefs.allowsContentJavaScript = true
        hydroConfig.defaultWebpagePreferences = hydroPrefs

        hydroConfig.allowsInlineMediaPlayback = true
        hydroConfig.mediaTypesRequiringUserActionForPlayback = []
        hydroConfig.allowsAirPlayForMediaPlayback = true
        hydroConfig.allowsPictureInPictureMediaPlayback = true
        hydroConfig.websiteDataStore = WKWebsiteDataStore.default()

        let hydroWebView = WKWebView(frame: .zero, configuration: hydroConfig)
        hydroWebView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        hydroWebView.scrollView.backgroundColor = .black
        hydroWebView.backgroundColor = .black
        hydroWebView.navigationDelegate = context.coordinator
        hydroWebView.uiDelegate = context.coordinator
        hydroWebView.allowsBackForwardNavigationGestures = true
        hydroWebView.scrollView.keyboardDismissMode = .interactive
        hydroWebView.allowsLinkPreview = false

        let hydroRefresh = UIRefreshControl()
        hydroRefresh.tintColor = .white
        hydroRefresh.addTarget(
            context.coordinator,
            action: #selector(PrilaCoordinator.hydroHandleRefresh(_:)),
            for: .valueChanged
        )
        hydroWebView.scrollView.refreshControl = hydroRefresh
        hydroWebView.scrollView.bounces = true
        context.coordinator.hydroRefreshControl = hydroRefresh

        Self.hydroLoadCookies(into: hydroWebView) {
            if !self.hydroUrl.isEmpty, let url = URL(string: self.hydroUrl) {
                hydroWebView.load(URLRequest(url: url))
            }
        }

        return hydroWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if !hydroUrl.isEmpty {
            let current = uiView.url?.absoluteString ?? ""
            if current != hydroUrl, let url = URL(string: hydroUrl) {
                uiView.load(URLRequest(url: url))
            }
        }
    }

    func makeCoordinator() -> PrilaCoordinator {
        PrilaCoordinator(self)
    }

    // MARK: - Cookies (safe unarchive)

    private static func hydroLoadCookies(into webView: WKWebView, completion: @escaping () -> Void) {
        guard let cookiesData = UserDefaults.standard.data(forKey: "hydro_saved_cookies_v1"),
              let cookiesArray = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cookiesData) as? [[String: Any]] else {
            completion()
            return
        }

        let group = DispatchGroup()
        for cookieDict in cookiesArray {
            var convertedDict: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in cookieDict {
                convertedDict[HTTPCookiePropertyKey(key)] = value
            }
            if let cookie = HTTPCookie(properties: convertedDict) {
                group.enter()
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
        }
        group.notify(queue: .main, execute: completion)
    }

    class PrilaCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let hydroParent: PrilaWebView
        private weak var hydroWebView: WKWebView?
        weak var hydroRefreshControl: UIRefreshControl?

        init(_ hydroParent: PrilaWebView) {
            self.hydroParent = hydroParent
            super.init()
        }

        @objc func hydroHandleRefresh(_ control: UIRefreshControl) {
            hydroWebView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                control.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            self.hydroWebView = webView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.scrollView.refreshControl?.endRefreshing()
            hydroSaveCookies(from: webView)

            if let hydroFinalPath = webView.url?.absoluteString {
                PrilaFlowController.shared.hydroCacheResource(hydroFinalPath)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            webView.scrollView.refreshControl?.endRefreshing()
            print("📱 [Prila6] Content load interrupted")
            PrilaFlowController.shared.hydroActivateSecondaryMode()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("📱 [Prila6] Content unavailable")
            PrilaFlowController.shared.hydroActivateSecondaryMode()
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else {
                decisionHandler(.allow)
                return
            }
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme != "http" && scheme != "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url {
                hydroWebView?.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                root.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                root.present(alert, animated: true)
            } else {
                completionHandler(false)
            }
        }

        private func hydroSaveCookies(from webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let hydroDicts: [[String: Any]] = cookies.compactMap { cookie in
                    guard let props = cookie.properties else { return nil }
                    var dict: [String: Any] = [:]
                    for (k, v) in props {
                        dict[k.rawValue] = v
                    }
                    return dict
                }
                let hydroData = try? NSKeyedArchiver.archivedData(withRootObject: hydroDicts, requiringSecureCoding: false)
                UserDefaults.standard.set(hydroData, forKey: "hydro_saved_cookies_v1")
            }
        }
    }
}
