//
//  PrilaLoadingView.swift
//  Prila6
//
//  Hydro Guru – loading screen.
//

import SwiftUI

struct PrilaLoadingView: View {
    @State private var hydroShowText = false
    @State private var hydroGradientOffset: CGFloat = 0

    var body: some View {
        ZStack {
            PrilaAnimatedGradientBackground(hydroGradientOffset: $hydroGradientOffset)

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    Text("Hydro Guru")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(hydroShowText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: hydroShowText)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    Text("Stay hydrated. Stay healthy.")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(hydroShowText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(1.0), value: hydroShowText)
                }

                Spacer()

                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 16, height: 16)
                                .shadow(color: .blue.opacity(0.6), radius: 8, x: 0, y: 4)
                                .scaleEffect(hydroShowText ? 1.0 : 0.5)
                                .opacity(hydroShowText ? 1.0 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.25),
                                    value: hydroShowText
                                )
                        }
                    }

                    Text("Preparing...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(hydroShowText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(2.0), value: hydroShowText)
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            withAnimation {
                hydroShowText = true
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: true)) {
                hydroGradientOffset = 0.4
            }
        }
    }
}

struct PrilaAnimatedGradientBackground: View {
    @Binding var hydroGradientOffset: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.cyan.opacity(0.6),
                    Color.blue.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.5 + hydroGradientOffset)
                )
            )
            .ignoresSafeArea()
        }
    }
}
