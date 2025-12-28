import Foundation
import Combine
import UserNotifications

struct CredentialInfo: Codable {
    let startUrl: String?
    let region: String?
    let accessToken: String?
    let expiresAt: String

    var expirationDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: expiresAt)
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return true }
        return Date() >= expiration
    }

    var timeRemaining: TimeInterval? {
        guard let expiration = expirationDate else { return nil }
        return expiration.timeIntervalSince(Date())
    }
}

@MainActor
class CredentialMonitor: ObservableObject {
    @Published var currentCredential: CredentialInfo?
    @Published var timeRemaining: String?

    private var notificationIdentifier: String?

    private var ssoCachePath: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".aws/sso/cache")
    }

    init() {
        requestNotificationPermission()
    }

    func startMonitoring(for profile: AWSProfile) {
        stopMonitoring()

        Task {
            await loadCredential(for: profile)
            updateTimeRemaining()
            await scheduleExpirationNotification()
        }
    }

    func stopMonitoring() {
        if let identifier = notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [identifier]
            )
        }
        notificationIdentifier = nil
        currentCredential = nil
        timeRemaining = nil
    }

    private func scheduleExpirationNotification() async {
        guard let credential = currentCredential,
              let remaining = credential.timeRemaining else {
            return
        }

        if remaining <= 0 {
            return
        }

        if remaining <= 300 {
            await sendImmediateNotification()
            return
        }

        let notificationDelay = remaining - 300

        let content = UNMutableNotificationContent()
        content.title = "AWS 인증 만료 임박"
        content.body = "AWS SSO 인증이 5분 후 만료됩니다. Profile을 다시 전환해주세요."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: notificationDelay,
            repeats: false
        )

        let identifier = UUID().uuidString
        self.notificationIdentifier = identifier

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silently fail
        }
    }

    private func sendImmediateNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "AWS 인증 만료 임박"
        content.body = "AWS SSO 인증이 곧 만료됩니다. Profile을 다시 전환해주세요."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silently fail
        }
    }

    func updateTimeRemaining() {
        guard let credential = currentCredential else {
            timeRemaining = nil
            return
        }

        if credential.isExpired {
            timeRemaining = "만료됨"
            return
        }

        guard let remaining = credential.timeRemaining else {
            timeRemaining = nil
            return
        }

        timeRemaining = formatTimeRemaining(remaining)
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 남음"
        } else if minutes > 0 {
            return "\(minutes)분 남음"
        } else {
            return "1분 미만 남음"
        }
    }

    private func loadCredential(for profile: AWSProfile) async {
        guard FileManager.default.fileExists(atPath: ssoCachePath.path) else {
            return
        }

        do {
            let cacheFiles = try FileManager.default.contentsOfDirectory(
                at: ssoCachePath,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            let jsonFiles = cacheFiles.filter { $0.pathExtension == "json" }

            for file in jsonFiles.sorted(by: { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return date1 > date2
            }) {
                if let credential = try? loadCredentialFile(at: file) {
                    if !credential.isExpired {
                        self.currentCredential = credential
                        return
                    }
                }
            }
        } catch {
            return
        }
    }

    private func loadCredentialFile(at url: URL) throws -> CredentialInfo? {
        let data = try Data(contentsOf: url)
        let credential = try JSONDecoder().decode(CredentialInfo.self, from: data)
        return credential
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
