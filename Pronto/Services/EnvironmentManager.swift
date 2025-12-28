import Foundation

enum EnvironmentError: LocalizedError {
    case fileWriteFailed(String)
    case shellSetupFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileWriteFailed(let message):
            return "환경 파일 작성 실패: \(message)"
        case .shellSetupFailed(let message):
            return "Shell 설정 실패: \(message)"
        }
    }
}

class EnvironmentManager {

    private var profileFilePath: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".pronto_profile")
    }

    private var shellConfigFiles: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".zshrc"),
            home.appendingPathComponent(".bashrc")
        ]
    }

    private var initMarkerPath: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".pronto_initialized")
    }

    func initializeIfNeeded() {
        if FileManager.default.fileExists(atPath: initMarkerPath.path) {
            return
        }

        do {
            try setupShellConfigs()
            try "initialized".write(to: initMarkerPath, atomically: true, encoding: .utf8)
        } catch {
            // Silently fail
        }
    }

    private func setupShellConfigs() throws {
        let sourceeLine = """

        # Pronto - AWS Profile Manager
        [ -f ~/.pronto_profile ] && source ~/.pronto_profile
        """

        for configFile in shellConfigFiles {
            if !FileManager.default.fileExists(atPath: configFile.path) {
                try "".write(to: configFile, atomically: true, encoding: .utf8)
            }

            let existingContent = try String(contentsOf: configFile, encoding: .utf8)

            if existingContent.contains("pronto_profile") {
                continue
            }

            let newContent = existingContent + sourceeLine
            try newContent.write(to: configFile, atomically: true, encoding: .utf8)
        }
    }

    func setGlobalEnvironment(profileName: String) throws {
        let content = "export AWS_PROFILE=\"\(profileName)\"\n"

        do {
            try content.write(to: profileFilePath, atomically: true, encoding: .utf8)

            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: profileFilePath.path
            )

            tryLaunchctl(profileName: profileName)

        } catch {
            throw EnvironmentError.fileWriteFailed(error.localizedDescription)
        }
    }

    func getGlobalEnvironment() -> String? {
        guard FileManager.default.fileExists(atPath: profileFilePath.path) else {
            return nil
        }

        do {
            let content = try String(contentsOf: profileFilePath, encoding: .utf8)
            if let match = content.range(of: "AWS_PROFILE=\"([^\"]+)\"", options: .regularExpression) {
                let value = content[match]
                let profileName = value
                    .replacingOccurrences(of: "AWS_PROFILE=\"", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                return profileName
            }
        } catch {
            return nil
        }

        return nil
    }

    func unsetGlobalEnvironment() throws {
        if FileManager.default.fileExists(atPath: profileFilePath.path) {
            try FileManager.default.removeItem(at: profileFilePath)
        }
    }

    private func tryLaunchctl(profileName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["setenv", "AWS_PROFILE", profileName]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Silently fail
        }
    }
}
