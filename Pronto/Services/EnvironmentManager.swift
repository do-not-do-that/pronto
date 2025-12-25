//
//  EnvironmentManager.swift
//  Pronto
//
//  시스템 전역 환경변수 관리
//

import Foundation

enum EnvironmentError: LocalizedError {
    case launchctlFailed(Int32)
    case plistCreationFailed(String)

    var errorDescription: String? {
        switch self {
        case .launchctlFailed(let status):
            return "launchctl 명령 실패 (종료 코드: \(status))"
        case .plistCreationFailed(let message):
            return "LaunchAgent plist 생성 실패: \(message)"
        }
    }
}

class EnvironmentManager {

    func setGlobalEnvironment(profileName: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["setenv", "AWS_PROFILE", profileName]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("❌ launchctl error: \(errorMessage)")
            throw EnvironmentError.launchctlFailed(process.terminationStatus)
        }

        print("✅ launchctl setenv AWS_PROFILE=\(profileName)")
    }

    func getGlobalEnvironment() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["getenv", "AWS_PROFILE"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return output
            }
        } catch {
            print("❌ getenv 실패: \(error)")
        }

        return nil
    }

    func unsetGlobalEnvironment() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unsetenv", "AWS_PROFILE"]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw EnvironmentError.launchctlFailed(process.terminationStatus)
        }

        print("✅ AWS_PROFILE 환경변수 삭제")
    }
}
