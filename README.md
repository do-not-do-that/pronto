# Pronto

> AWS SSO 멀티 계정을 한 번의 클릭으로 전환하는 macOS 메뉴바 앱

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 무엇을 해결하나요?

개발 중 여러 AWS 계정을 자주 전환해야 한다면...

**Before Pronto** 😓
```bash
# 매번 반복...
aws sso login --profile dev-account-a
export AWS_PROFILE=dev-account-a
```

**After Pronto** 😎
```
메뉴바 아이콘 클릭 → Profile 선택 → 완료!
```

---

## ✨ 주요 기능

- 🚀 **원클릭 전환**: 메뉴바에서 Profile 클릭 한 번으로 전환
- 🔐 **자동 SSO 로그인**: Profile 전환 시 브라우저에서 자동 로그인
- 🔔 **만료 알림**: Credential 만료 5분 전 자동 알림 (배터리 효율적)
- ⏱️ **만료 시간 표시**: 남은 시간 실시간 표시
- 🌍 **전역 적용**: DataGrip, VSCode, 터미널 등 모든 도구에 자동 반영
- 🔄 **터미널 세션 자동 업데이트**: iTerm2/Terminal.app의 열린 세션 즉시 반영
- ⚡ **빠른 실행**: 메뉴바에 상주하는 가벼운 앱
- 🔄 **자동 구성**: 첫 실행 시 Shell 설정 자동 완료
- 🍎 **Apple Silicon 지원**: M1/M2/M3 Mac 완벽 지원

---

## 📦 설치

### 요구사항

- macOS 13.0 (Ventura) 이상
- AWS CLI v2
- AWS SSO 설정 (`.aws/config`)

### 설치 방법

#### Homebrew (권장)

```bash
# Tap 추가
brew tap donotdothat/pronto

# 설치
brew install --cask pronto

# 실행
open -a Pronto
```

#### 수동 설치

1. [Releases](https://github.com/YOUR_USERNAME/pronto/releases)에서 최신 버전 다운로드
2. `Pronto.app`을 Applications 폴더로 이동
3. 실행: `open /Applications/Pronto.app`

#### ⚠️ 처음 실행 시 경고

**"확인되지 않은 개발자" 경고가 나타납니다.** 이것은 정상입니다.

**해결 방법:**
1. Finder에서 `Pronto.app` 우클릭
2. "열기" 클릭 → "열기" 버튼 클릭

또는 터미널에서:
```bash
xattr -cr /Applications/Pronto.app
open -a Pronto
```

**이유:**
- 오픈소스 프로젝트로 Apple Developer Program 미가입
- 코드는 GitHub에 공개되어 투명하게 검증 가능
- Homebrew 커뮤니티를 통한 배포

---

## 🚀 사용 방법

### 첫 실행

1. Pronto 실행
2. 메뉴바에서 ☁️ 아이콘 확인
3. 아이콘 클릭 → Profile 목록 확인

### Profile 전환

1. 메뉴바 아이콘 클릭
2. 원하는 Profile 선택
3. 브라우저에서 SSO 로그인 (자동으로 열림)
4. **완료!** 새 터미널에서 바로 사용 가능

### 확인

```bash
# 새 터미널에서
echo $AWS_PROFILE
# -> 선택한 profile 이름 출력

# 기존 터미널에서 (필요시)
source ~/.pronto_profile
```

### 터미널 세션 자동 업데이트

설정에서 "터미널 세션 업데이트"를 활성화하면, Profile 전환 시 **열려있는 터미널 세션**도 즉시 업데이트됩니다.

**지원 터미널:**
- ✅ **iTerm2**: 모든 창과 탭 자동 업데이트
- ✅ **Terminal.app**: macOS 기본 터미널 자동 업데이트

**미지원 터미널:**
- ❌ **IDE 통합 터미널** (Cursor, VS Code, etc.): 새 터미널만 자동 적용
- ❌ **Termius, Warp 등**: 새 터미널만 자동 적용

**동작 방식:**

| 터미널 | 기존 세션 | 새 세션 |
|--------|----------|---------|
| iTerm2 | ✅ 즉시 반영 | ✅ 자동 적용 |
| Terminal.app | ✅ 즉시 반영 | ✅ 자동 적용 |
| Cursor, VS Code | ❌ 수동 (`source ~/.pronto_profile`) | ✅ 자동 적용 |
| Termius, Warp | ❌ 수동 (`source ~/.pronto_profile`) | ✅ 자동 적용 |

**권장 설정:**
- iTerm2/Terminal.app 사용자: **ON** (즉시 반영)
- IDE 터미널 사용자: **OFF** (새 터미널로 전환)

---

## 🔧 문제 해결

### Profile이 안 보여요

- `~/.aws/config` 파일이 있는지 확인
- SSO Profile 설정이 있는지 확인 (`sso_account_id`, `sso_role_name` 등)

```bash
# AWS Config 확인
cat ~/.aws/config

# SSO Profile 예시
[profile dev-account]
sso_session = my-sso
sso_account_id = 123456789012
sso_role_name = Developer
region = ap-northeast-2
```

### SSO 로그인이 안돼요

```bash
# AWS CLI 설치 확인
aws --version

# 경로 확인
which aws
# Apple Silicon: /opt/homebrew/bin/aws
# Intel: /usr/local/bin/aws
```

### 환경변수가 안 보여요

**새 터미널 세션:**
- **새 터미널 창/탭**을 열었는지 확인 (기존 창 X)
- Shell 설정 확인:

```bash
# Pronto 설정이 추가되었는지 확인
cat ~/.zshrc | grep pronto

# 출력 예시:
# [ -f ~/.pronto_profile ] && source ~/.pronto_profile
```

**기존 터미널 세션:**
- iTerm2/Terminal.app: 설정에서 "터미널 세션 업데이트" 활성화
- 기타 터미널: 수동으로 `source ~/.pronto_profile` 실행

---

## 🏗️ 개발

### 프로젝트 구조

```
Pronto/
├── ProntoApp.swift              # 앱 진입점
├── Models/
│   ├── AWSProfile.swift         # Profile 데이터 모델
│   └── AppState.swift           # 전역 상태 관리
├── Services/
│   ├── AWSConfigParser.swift    # ~/.aws/config 파싱
│   ├── ProfileManager.swift     # Profile 관리 + SSO 로그인
│   ├── EnvironmentManager.swift # 환경변수 관리
│   ├── TerminalController.swift # 터미널 세션 업데이트
│   └── CredentialMonitor.swift  # Credential 만료 모니터링
├── Views/
│   ├── MenuBarView.swift        # 메뉴바 UI
│   └── SettingsView.swift       # 설정 창
└── Resources/
    └── Assets.xcassets          # 아이콘
```

### 빌드

```bash
# Xcode에서 빌드
open Pronto.xcodeproj

# 또는 xcodebuild
xcodebuild -scheme Pronto -configuration Release
```

### 기술 스택

- **SwiftUI**: 현대적인 UI 프레임워크
- **MenuBarExtra**: macOS 13+ 메뉴바 앱 API
- **Combine**: 반응형 상태 관리
- **Foundation**: 파일 시스템, 프로세스 실행

---

## 🤝 기여

버그 리포트나 기능 제안은 언제든 환영합니다!

### 개발 환경 설정

```bash
# 1. Repository clone
git clone https://github.com/YOUR_USERNAME/pronto.git
cd pronto

# 2. Xcode에서 열기
open Pronto.xcodeproj

# 3. 빌드 및 실행 (⌘+R)
```

### 커밋 컨벤션

- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서
- `chore`: 기타

---

## 📝 로드맵

### v1.0 (완료) ✅
- [x] Credential 만료 시간 표시
- [x] 만료 5분 전 알림
- [x] 터미널 세션 자동 업데이트
- [x] 배터리 효율적인 알림 시스템
- [x] Homebrew Cask 배포

### v1.1 (예정)
- [ ] 현재 Account ID 표시
- [ ] Profile 그룹화 기능
- [ ] 검색 기능

### v1.2 (예정)
- [ ] 키보드 단축키
- [ ] 다크 모드 커스터마이징
- [ ] 더 많은 터미널 지원 (Warp, Alacritty 등)

---

## 📄 라이선스

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## ℹ️ 프로젝트 정보

- **개발 기간**: 2025-12-24 ~ 2025-12-28 (5일)
- **상태**: MVP 완료
- **개발**: Claude Code와 함께 개발
- **버전**: 1.0.0

---

## 🙏 감사의 말

이 프로젝트는 AWS SSO를 사용하는 모든 개발자들의 생산성 향상을 위해 만들어졌습니다.

특별히 다음을 참고했습니다:
- [SwiftUI MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [AWS CLI SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)

---

**Made with ❤️ and Claude Code**
