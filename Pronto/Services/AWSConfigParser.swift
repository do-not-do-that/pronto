import Foundation

enum AWSConfigError: LocalizedError {
    case fileNotFound
    case parseError(String)
    case noProfilesFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "AWS Config 파일을 찾을 수 없습니다. ~/.aws/config 파일이 존재하는지 확인해주세요."
        case .parseError(let message):
            return "Config 파일 파싱 오류: \(message)"
        case .noProfilesFound:
            return "SSO Profile을 찾을 수 없습니다. AWS SSO를 설정해주세요."
        }
    }
}

class AWSConfigParser {

    private static var configPath: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".aws/config")
    }

    static func parseProfiles() throws -> [AWSProfile] {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw AWSConfigError.fileNotFound
        }

        let content: String
        do {
            content = try String(contentsOf: configPath, encoding: .utf8)
        } catch {
            throw AWSConfigError.parseError("파일을 읽을 수 없습니다: \(error.localizedDescription)")
        }

        let profiles = parseINI(content)
        let ssoProfiles = profiles.filter { $0.isSSOProfile }

        guard !ssoProfiles.isEmpty else {
            throw AWSConfigError.noProfilesFound
        }

        return ssoProfiles
    }

    private static func parseINI(_ content: String) -> [AWSProfile] {
        var profiles: [AWSProfile] = []
        var currentProfileName: String?
        var currentProfileData: [String: String] = [:]

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") {
                continue
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                if let profileName = currentProfileName {
                    if let profile = createProfile(name: profileName, data: currentProfileData) {
                        profiles.append(profile)
                    }
                }

                let sectionName = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)

                if sectionName.hasPrefix("profile ") {
                    currentProfileName = String(sectionName.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                } else if sectionName == "default" {
                    currentProfileName = "default"
                } else if sectionName.hasPrefix("sso-session ") {
                    currentProfileName = nil
                } else {
                    currentProfileName = nil
                }

                currentProfileData = [:]
                continue
            }

            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = trimmed[..<equalIndex].trimmingCharacters(in: .whitespaces)
                let value = trimmed[trimmed.index(after: equalIndex)...].trimmingCharacters(in: .whitespaces)
                currentProfileData[key] = value
            }
        }

        if let profileName = currentProfileName {
            if let profile = createProfile(name: profileName, data: currentProfileData) {
                profiles.append(profile)
            }
        }

        return profiles
    }

    private static func createProfile(name: String, data: [String: String]) -> AWSProfile? {
        return AWSProfile(
            name: name,
            ssoStartUrl: data["sso_start_url"],
            ssoRegion: data["sso_region"],
            ssoAccountId: data["sso_account_id"],
            ssoRoleName: data["sso_role_name"],
            ssoSessionName: data["sso_session"],
            region: data["region"]
        )
    }
}
