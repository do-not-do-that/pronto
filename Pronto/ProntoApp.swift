//
//  ProntoApp.swift
//  Pronto
//
//  메인 앱 진입점
//

import SwiftUI

@main
struct ProntoApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Pronto", systemImage: "cloud") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "settings") {
            SettingsView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
    }
}
