import SwiftUI

@main
struct ProntoApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("Pronto", image: "menubar-icon") {
            MenuBarView()
                .environmentObject(appState)
                .onChange(of: appState.showSettings) { _, newValue in
                    if newValue {
                        openWindow(id: "settings")
                        appState.showSettings = false
                    }
                }
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
