# Pronto

> AWS SSO 멀티 계정을 한 번의 클릭으로 전환하는 macOS 메뉴바 앱

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 무엇을 해결하나요?

개발 중 여러 AWS 계정을 자주 전환해야 한다면...

**Before Pronto**
```bash
# 매번 반복...
aws sso login --profile dev-account-a
export AWS_PROFILE=dev-account-a
```

**After Pronto**
```
메뉴바 아이콘 클릭 → Profile 선택 → 완료!
```

---

## 주요 기능

- 원클릭 전환: 메뉴바에서 Profile 클릭 한 번으로 전환
- 자동 SSO 로그인: Profile 전환 시 브라우저에서 자동 로그인
- 만료 알림: Credential 만료 5분 전 자동 알림 (배터리 효율적)
- 만료 시간 표시: 남은 시간 실시간 표시
- 전역 적용: DataGrip, VSCode, 터미널 등 모든 도구에 자동 반영
- 터미널 세션 자동 업데이트: iTerm2/Terminal.app의 열린 세션 즉시 반영
- Apple Silicon 지원: M1/M2/M3 Mac 완벽 지원

---

## 설치

### 요구사항

- macOS 13.0 (Ventura) 이상
- AWS CLI v2
- AWS SSO 설정 (`.aws/config`)

### 설치 방법

#### Homebrew (권장)

```bash
# Tap 추가 및 설치
brew tap donotdothat/pronto
brew install --cask pronto

# Gatekeeper 경고 제거 후 실행
xattr -cr /Applications/Pronto.app
open -a Pronto
```

#### 수동 설치

1. [Releases](https://github.com/YOUR_USERNAME/pronto/releases)에서 최신 버전 다운로드
2. `Pronto.app`을 Applications 폴더로 이동
3. Gatekeeper 경고 제거:
```bash
xattr -cr /Applications/Pronto.app
open -a Pronto
```

> **참고:** 서명되지 않은 앱이므로 "확인되지 않은 개발자" 경고가 나타날 수 있습니다. 자세한 내용은 [FAQ](FAQ.md)를 확인하세요.

---

## 사용 방법

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

## FAQ

문제가 있나요? [FAQ 문서](FAQ.md)를 확인해보세요.

---

## 피드백

버그 리포트나 기능 제안은 언제든 환영합니다!

[Issues](https://github.com/YOUR_USERNAME/pronto/issues)

---

## 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.
