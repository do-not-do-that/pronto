import Foundation
import Combine
import AppKit

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
        Task {
            await installUpdate()
        }
    }

    private func installUpdate() async {
        // 백그라운드 업데이트 스크립트 생성
        let updateScript = """
        #!/bin/bash

        # 1. 앱이 완전히 종료될 때까지 대기
        sleep 2

        # 2. Homebrew 업데이트 실행
        brew update
        brew tap --force do-not-do-that/pronto
        brew cleanup do-not-do-that/pronto/pronto
        brew upgrade --cask --force --no-quarantine do-not-do-that/pronto/pronto || brew reinstall --cask --force --no-quarantine do-not-do-that/pronto/pronto

        # 3. 설치 완료 후 앱 재시작
        sleep 1
        open /Applications/Pronto.app

        # 4. 임시 스크립트 삭제
        rm -f /tmp/pronto_update.sh
        """

        // 임시 스크립트 파일 생성
        let scriptPath = "/tmp/pronto_update.sh"
        let scriptURL = URL(fileURLWithPath: scriptPath)
        do {
            try updateScript.write(to: scriptURL, atomically: true, encoding: .utf8)

            // 실행 권한 부여
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", scriptPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()

            // 백그라운드에서 스크립트 실행
            let execProcess = Process()
            execProcess.executableURL = URL(fileURLWithPath: "/bin/sh")
            execProcess.arguments = ["-c", "nohup \(scriptPath) > /dev/null 2>&1 &"]
            try execProcess.run()

            // 앱 종료
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "업데이트 설치 실패: \(error.localizedDescription)"
            }
        }
    }
}
