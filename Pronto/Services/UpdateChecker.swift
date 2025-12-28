import Foundation
import Combine

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case body
    }
}

class UpdateChecker: ObservableObject {
    @Published var isChecking = false
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var currentVersion: String
    @Published var releaseURL: String?
    @Published var errorMessage: String?

    init() {
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    func checkForUpdates() async {
        await MainActor.run {
            isChecking = true
            errorMessage = nil
            updateAvailable = false
        }

        do {
            let url = URL(string: "https://api.github.com/repos/do-not-do-that/pronto/releases/latest")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            // Extract version from tag (e.g., "v1.2.1" -> "1.2.1")
            let latestVersionString = release.tagName.replacingOccurrences(of: "v", with: "")

            await MainActor.run {
                self.latestVersion = latestVersionString
                self.releaseURL = release.htmlUrl
                self.updateAvailable = self.compareVersions(current: currentVersion, latest: latestVersionString)
                self.isChecking = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "업데이트 확인 실패: \(error.localizedDescription)"
                self.isChecking = false
            }
        }
    }

    private func compareVersions(current: String, latest: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(currentComponents.count, latestComponents.count) {
            let currentNum = i < currentComponents.count ? currentComponents[i] : 0
            let latestNum = i < latestComponents.count ? latestComponents[i] : 0

            if latestNum > currentNum {
                return true
            } else if latestNum < currentNum {
                return false
            }
        }

        return false
    }

    func startAutoUpdate() {
        let script = """
        tell application "Terminal"
            activate
            do script "brew reinstall --cask do-not-do-that/pronto/pronto && killall Pronto && sleep 1 && open -a Pronto"
        end tell
        """

        if let scriptObject = NSAppleScript(source: script) {
            var error: NSDictionary?
            scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}
