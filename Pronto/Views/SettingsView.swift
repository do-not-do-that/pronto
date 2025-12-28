import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("updateTerminals") private var updateTerminals = false

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

                Section("정보") {
                    LabeledContent("버전", value: "1.0.0")
                    LabeledContent("개발자", value: "Medistream")
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
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
