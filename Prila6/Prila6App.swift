//
//  Prila6App.swift
//  Hydro Guru
//
//  Created by Садыг Садыгов on 03.11.2025.
//

import SwiftUI

@main
struct Prila6App: App {
    @StateObject private var hydroFlowController = PrilaFlowController.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                hydroContentView
                    .opacity(hydroFlowController.hydroIsLoading ? 0 : 1)

                if hydroFlowController.hydroIsLoading {
                    PrilaLoadingView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hydroFlowController.hydroIsLoading)
        }
    }

    @ViewBuilder
    private var hydroContentView: some View {
        switch hydroFlowController.hydroDisplayMode {
        case .preparing, .original:
            MainTabView()
        case .webContent:
            PrilaDisplayView()
        }
    }
}
