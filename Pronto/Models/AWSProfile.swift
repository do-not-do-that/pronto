//
//  AWSProfile.swift
//  Pronto
//
//  AWS Profile 데이터 모델
//

import Foundation

struct AWSProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let ssoStartUrl: String?
    let ssoRegion: String?
    let ssoAccountId: String?
    let ssoRoleName: String?
    let ssoSessionName: String?  // AWS Config v2: sso_session 참조
    let region: String?

    init(
        id: UUID = UUID(),
        name: String,
        ssoStartUrl: String? = nil,
        ssoRegion: String? = nil,
        ssoAccountId: String? = nil,
        ssoRoleName: String? = nil,
        ssoSessionName: String? = nil,
        region: String? = nil
    ) {
        self.id = id
        self.name = name
        self.ssoStartUrl = ssoStartUrl
        self.ssoRegion = ssoRegion
        self.ssoAccountId = ssoAccountId
        self.ssoRoleName = ssoRoleName
        self.ssoSessionName = ssoSessionName
        self.region = region
    }

    /// Profile이 SSO Profile인지 확인
    var isSSOProfile: Bool {
        // v1: sso_start_url 있음
        // v2: sso_session + sso_account_id + sso_role_name 있음
        return ssoStartUrl != nil ||
               (ssoSessionName != nil && ssoAccountId != nil && ssoRoleName != nil)
    }

    /// Profile 표시 이름
    var displayName: String {
        return name
    }

    /// Account와 Role 정보 표시
    var accountInfo: String? {
        guard let accountId = ssoAccountId, let roleName = ssoRoleName else {
            return nil
        }
        return "\(accountId) - \(roleName)"
    }
}

// MARK: - Sample Data
extension AWSProfile {
    static let sample1 = AWSProfile(
        name: "dev-account-a",
        ssoStartUrl: "https://d-example.awsapps.com/start",
        ssoRegion: "ap-northeast-2",
        ssoAccountId: "123456789012",
        ssoRoleName: "Developer",
        region: "ap-northeast-2"
    )

    static let sample2 = AWSProfile(
        name: "prod-account-1",
        ssoStartUrl: "https://d-example.awsapps.com/start",
        ssoRegion: "ap-northeast-2",
        ssoAccountId: "987654321098",
        ssoRoleName: "ReadOnly",
        region: "ap-northeast-2"
    )

    static let samples = [sample1, sample2]
}
