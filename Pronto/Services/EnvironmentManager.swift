//
//  EnvironmentManager.swift
//  Pronto
//
//  환경변수 관리 - 안정적인 파일 기반 방식
//

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

    // ~/.pronto_profile 경로
    private var profileFilePath: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".pronto_profile")
    }

    // Shell 설정 파일들
    private var shellConfigFiles: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".zshrc"),
            home.appendingPathComponent(".bashrc")
        ]
    }

    // Pronto 초기화 완료 마커
    private var initMarkerPath: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".pronto_initialized")
    }

    /// 첫 실행 시 Shell 설정 초기화
    func initializeIfNeeded() {
        // 이미 초기화되었으면 스킵
        if FileManager.default.fileExists(atPath: initMarkerPath.path) {
            return
        }

        print("🔧 Pronto 첫 실행 - Shell 설정 초기화 중...")

        do {
            try setupShellConfigs()

            // 초기화 완료 마커 생성
            try "initialized".write(to: initMarkerPath, atomically: true, encoding: .utf8)

            print("✅ Shell 설정 완료!")
            print("💡 새 터미널을 열면 자동으로 AWS_PROFILE이 적용됩니다.")
        } catch {
            print("⚠️ Shell 설정 중 오류 (무시 가능): \(error)")
        }
    }

    /// Shell 설정 파일에 source 라인 추가
    private func setupShellConfigs() throws {
        let sourceeLine = """

        # Pronto - AWS Profile Manager
        [ -f ~/.pronto_profile ] && source ~/.pronto_profile
        """

        for configFile in shellConfigFiles {
            // 파일이 없으면 생성
            if !FileManager.default.fileExists(atPath: configFile.path) {
                try "".write(to: configFile, atomically: true, encoding: .utf8)
            }

            // 기존 내용 읽기
            let existingContent = try String(contentsOf: configFile, encoding: .utf8)

            // 이미 추가되어 있으면 스킵
            if existingContent.contains("pronto_profile") {
                print("✓ \(configFile.lastPathComponent) 이미 설정됨")
                continue
            }

            // 끝에 추가
            let newContent = existingContent + sourceeLine
            try newContent.write(to: configFile, atomically: true, encoding: .utf8)

            print("✅ \(configFile.lastPathComponent) 업데이트 완료")
        }
    }

    /// Profile 환경변수 설정 (파일 기반)
    func setGlobalEnvironment(profileName: String) throws {
        // ~/.pronto_profile 파일에 작성
        let content = "export AWS_PROFILE=\"\(profileName)\"\n"

        do {
            try content.write(to: profileFilePath, atomically: true, encoding: .utf8)

            // 파일 권한 600 (소유자만 읽기/쓰기)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: profileFilePath.path
            )

            print("✅ Profile 설정: \(profileName)")
            print("📁 위치: ~/.pronto_profile")

            // 추가로 launchctl도 실행 (일부 macOS에서 작동)
            tryLaunchctl(profileName: profileName)

        } catch {
            throw EnvironmentError.fileWriteFailed(error.localizedDescription)
        }
    }

    /// 현재 설정된 Profile 읽기
    func getGlobalEnvironment() -> String? {
        guard FileManager.default.fileExists(atPath: profileFilePath.path) else {
            return nil
        }

        do {
            let content = try String(contentsOf: profileFilePath, encoding: .utf8)
            // "export AWS_PROFILE="xxx"" 형식에서 값 추출
            if let match = content.range(of: "AWS_PROFILE=\"([^\"]+)\"", options: .regularExpression) {
                let value = content[match]
                let profileName = value
                    .replacingOccurrences(of: "AWS_PROFILE=\"", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                return profileName
            }
        } catch {
            print("⚠️ Profile 파일 읽기 실패: \(error)")
        }

        return nil
    }

    /// Profile 환경변수 제거
    func unsetGlobalEnvironment() throws {
        if FileManager.default.fileExists(atPath: profileFilePath.path) {
            try FileManager.default.removeItem(at: profileFilePath)
            print("✅ Profile 설정 제거")
        }
    }

    /// launchctl 시도 (보조적으로, 실패해도 무시)
    private func tryLaunchctl(profileName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["setenv", "AWS_PROFILE", profileName]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ launchctl 추가 설정 성공")
            }
        } catch {
            // 실패해도 무시 (파일 기반이 주 방법)
            print("ℹ️ launchctl 설정 건너뜀 (파일 기반 사용)")
        }
    }
}
