import SwiftUI

@main
struct ProntoApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Pronto", image: "menubar-icon") {
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
