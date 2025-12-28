import Foundation

struct AWSProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let ssoStartUrl: String?
    let ssoRegion: String?
    let ssoAccountId: String?
    let ssoRoleName: String?
    let ssoSessionName: String?
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

    var isSSOProfile: Bool {
        ssoStartUrl != nil || (ssoSessionName != nil && ssoAccountId != nil && ssoRoleName != nil)
    }

    var displayName: String {
        name
    }

    var accountInfo: String? {
        guard let accountId = ssoAccountId, let roleName = ssoRoleName else {
            return nil
        }
        return "\(accountId) - \(roleName)"
    }
}
