//
//  ProfileManager.swift
//  Pronto
//
//  AWS Profile 관리
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileManager: ObservableObject {
    @Published var profiles: [AWSProfile] = []
    @Published var activeProfile: AWSProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let environmentManager = EnvironmentManager()

    init() {
        // 첫 실행 시 Shell 설정 초기화
        environmentManager.initializeIfNeeded()

        Task {
            await loadProfiles()
            await loadActiveProfile()
        }
    }

    func loadProfiles() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedProfiles = try AWSConfigParser.parseProfiles()
            self.profiles = loadedProfiles
        } catch {
            self.errorMessage = error.localizedDescription
            self.profiles = []
        }

        isLoading = false
    }

    func loadActiveProfile() async {
        if let currentProfileName = ProcessInfo.processInfo.environment["AWS_PROFILE"] {
            self.activeProfile = profiles.first { $0.name == currentProfileName }
        } else {
            self.activeProfile = nil
        }
    }

    func switchProfile(_ profile: AWSProfile) async throws {
        isLoading = true
        errorMessage = nil

        do {
            // 1. 환경변수 설정
            try environmentManager.setGlobalEnvironment(profileName: profile.name)
            self.activeProfile = profile
            print("✅ Profile 전환 완료: \(profile.name)")

            // 2. SSO Profile이면 자동 로그인 시도
            if profile.isSSOProfile {
                print("🔐 SSO 로그인 시도 중...")
                try? await ssoLogin(profile: profile)
            }

        } catch {
            self.errorMessage = "Profile 전환 실패: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    func refreshProfiles() async {
        await loadProfiles()
        await loadActiveProfile()
    }

    func ssoLogin(profile: AWSProfile) async throws {
        guard profile.isSSOProfile else {
            throw ProfileError.notSSOProfile
        }

        isLoading = true
        errorMessage = nil

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/aws")
            process.arguments = ["sso", "login", "--profile", profile.name]

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ SSO 로그인 성공: \(profile.name)")
            } else {
                throw ProfileError.ssoLoginFailed
            }
        } catch {
            self.errorMessage = "SSO 로그인 실패: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }
}

enum ProfileError: LocalizedError {
    case notSSOProfile
    case ssoLoginFailed
    case switchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSSOProfile:
            return "SSO Profile이 아닙니다."
        case .ssoLoginFailed:
            return "SSO 로그인에 실패했습니다."
        case .switchFailed(let message):
            return "Profile 전환 실패: \(message)"
        }
    }
}
