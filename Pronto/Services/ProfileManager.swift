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
    private let terminalController = TerminalController()
    let credentialMonitor = CredentialMonitor()
    @AppStorage("updateTerminals") private var updateTerminals = false

    init() {
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
            if let profile = activeProfile {
                credentialMonitor.startMonitoring(for: profile)
            }
        } else {
            self.activeProfile = nil
            await credentialMonitor.stopMonitoring()
        }
    }

    func switchProfile(_ profile: AWSProfile) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try environmentManager.setGlobalEnvironment(profileName: profile.name)
            self.activeProfile = profile

            if updateTerminals {
                try? terminalController.updateAllTerminals(profileName: profile.name)
            }

            if profile.isSSOProfile {
                try? await ssoLogin(profile: profile)
            }

            credentialMonitor.startMonitoring(for: profile)

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
            guard let awsPath = findAWSCLI() else {
                throw ProfileError.awsCLINotFound
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: awsPath)
            process.arguments = ["sso", "login", "--profile", profile.name]

            let errorPipe = Pipe()
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                throw ProfileError.ssoLoginFailed
            }
        } catch {
            self.errorMessage = "SSO 로그인 실패: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    private func findAWSCLI() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/aws",
            "/usr/local/bin/aws",
            "/usr/bin/aws"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["aws"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    return path
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}

enum ProfileError: LocalizedError {
    case notSSOProfile
    case ssoLoginFailed
    case awsCLINotFound
    case switchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSSOProfile:
            return "SSO Profile이 아닙니다."
        case .ssoLoginFailed:
            return "SSO 로그인에 실패했습니다."
        case .awsCLINotFound:
            return "AWS CLI를 찾을 수 없습니다. Homebrew로 설치해주세요: brew install awscli"
        case .switchFailed(let message):
            return "Profile 전환 실패: \(message)"
        }
    }
}
