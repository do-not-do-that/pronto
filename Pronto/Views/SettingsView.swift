import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("updateTerminals") private var updateTerminals = false
    @StateObject private var updateChecker = UpdateChecker()
    @State private var showUpdateAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("설정")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section {
                    Toggle("자동 새로고침", isOn: $autoRefresh)
                    Text("Profile 목록을 주기적으로 새로고침합니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("터미널 세션 업데이트", isOn: $updateTerminals)
                    Text("Profile 전환 시 열려있는 터미널 세션도 업데이트합니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("알림") {
                    Button("알림 권한 설정") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Text("만료 임박 알림을 받으려면 알림 권한이 필요합니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("정보") {
                    LabeledContent("버전", value: appVersion)
                    LabeledContent("개발자", value: "do-not-do-that")

                    Button(action: {
                        Task {
                            await updateChecker.checkForUpdates()
                            showUpdateAlert = true
                        }
                    }) {
                        if updateChecker.isChecking {
                            HStack {
                                Text("업데이트 확인 중...")
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        } else {
                            Text("업데이트 확인")
                        }
                    }
                    .disabled(updateChecker.isChecking)
                }
            }
            .formStyle(.grouped)

            Spacer()

            HStack {
                Button("GitHub에서 보기") {
                    if let url = URL(string: "https://github.com/do-not-do-that/pronto") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)

                Spacer()

                Button("닫기") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert(isPresented: $showUpdateAlert) {
            if let error = updateChecker.errorMessage {
                return Alert(
                    title: Text("오류"),
                    message: Text(error),
                    dismissButton: .default(Text("확인"))
                )
            } else if updateChecker.updateAvailable, let latest = updateChecker.latestVersion {
                return Alert(
                    title: Text("업데이트 사용 가능"),
                    message: Text("새 버전 \(latest)이(가) 사용 가능합니다.\n현재 버전: \(appVersion)\n\n터미널에서 Homebrew로 자동 업데이트하시겠습니까?"),
                    primaryButton: .default(Text("자동 업데이트")) {
                        updateChecker.startAutoUpdate()
                    },
                    secondaryButton: .cancel(Text("나중에"))
                )
            } else {
                return Alert(
                    title: Text("최신 버전"),
                    message: Text("현재 최신 버전(\(appVersion))을 사용 중입니다."),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
