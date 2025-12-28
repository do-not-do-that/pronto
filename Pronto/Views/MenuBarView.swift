import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var profileManager = ProfileManager()

    var body: some View {
        VStack(spacing: 0) {
            if let activeProfile = profileManager.activeProfile {
                CurrentProfileHeader(profile: activeProfile)
                Divider()
            } else if !profileManager.profiles.isEmpty {
                NoActiveProfileHeader()
                Divider()
            }

            if profileManager.isLoading {
                ProgressView("로딩 중...")
                    .frame(height: 100)
            } else if let errorMessage = profileManager.errorMessage {
                ErrorView(message: errorMessage) {
                    Task {
                        await profileManager.loadProfiles()
                    }
                }
            } else if profileManager.profiles.isEmpty {
                EmptyProfilesView()
            } else {
                ProfileListView(profileManager: profileManager)
            }

            Divider()

            BottomActionsView(profileManager: profileManager)
        }
        .frame(width: 320)
    }
}

struct CurrentProfileHeader: View {
    let profile: AWSProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("현재 활성")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text(profile.displayName)
                .font(.headline)

            if let accountInfo = profile.accountInfo {
                Text(accountInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
    }
}

struct NoActiveProfileHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.orange)
                Text("활성 Profile 없음")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
    }
}

struct ProfileListView: View {
    @ObservedObject var profileManager: ProfileManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(profileManager.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == profileManager.activeProfile?.id
                    ) {
                        Task {
                            try? await profileManager.switchProfile(profile)
                        }
                    }
                    Divider()
                }
            }
        }
        .frame(height: 300)
    }
}

struct ProfileRow: View {
    let profile: AWSProfile
    let isActive: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    if let accountInfo = profile.accountInfo {
                        Text(accountInfo)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if profile.isSSOProfile {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovering ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("다시 시도") {
                onRetry()
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

struct EmptyProfilesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("AWS Profile이 없습니다")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("~/.aws/config 파일을 확인해주세요")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

struct BottomActionsView: View {
    @ObservedObject var profileManager: ProfileManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    await profileManager.refreshProfiles()
                }
            } label: {
                Label("새로고침", systemImage: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .disabled(profileManager.isLoading)

            Spacer()

            Button {
                appState.showSettings = true
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("설정", systemImage: "gear")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)

            Button {
                NSApp.terminate(nil)
            } label: {
                Text("종료")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
        }
        .padding(8)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
}
