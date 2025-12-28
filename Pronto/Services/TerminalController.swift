import Foundation
import AppKit

enum TerminalError: LocalizedError {
    case scriptFailed(String)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let message):
            return "터미널 업데이트 실패: \(message)"
        case .permissionDenied:
            return "터미널 접근 권한이 필요합니다. 시스템 설정 > 개인정보 보호 > 자동화에서 권한을 허용해주세요."
        }
    }
}

class TerminalController {

    func updateAllTerminals(profileName: String) throws {
        try updateITerm2(profileName: profileName)
        try updateTerminalApp(profileName: profileName)
    }

    private func updateITerm2(profileName: String) throws {
        guard isAppRunning("iTerm") || isAppRunning("iTerm2") else {
            return
        }

        let script = """
        tell application "iTerm"
            try
                tell every session of every window
                    write text "export AWS_PROFILE=\(profileName)"
                end tell
            end try
        end tell
        """

        try executeAppleScript(script)
    }

    private func updateTerminalApp(profileName: String) throws {
        guard isAppRunning("Terminal") else {
            return
        }

        let script = """
        tell application "Terminal"
            try
                repeat with win in windows
                    repeat with t in tabs of win
                        do script "export AWS_PROFILE=\(profileName)" in t
                    end repeat
                end repeat
            end try
        end tell
        """

        try executeAppleScript(script)
    }

    private func executeAppleScript(_ script: String) throws {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            throw TerminalError.scriptFailed("스크립트 생성 실패")
        }

        scriptObject.executeAndReturnError(&error)

        if let error = error {
            let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "알 수 없는 오류"
            throw TerminalError.scriptFailed(errorMessage)
        }
    }

    private func isAppRunning(_ appName: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { app in
            app.localizedName == appName || app.bundleIdentifier?.contains(appName.lowercased()) == true
        }
    }
}
