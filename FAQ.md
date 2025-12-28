# FAQ - 자주 묻는 질문

## 설치 관련

### Q: "확인되지 않은 개발자" 경고가 나타나요

**A:** 서명되지 않은 앱이므로 정상입니다.

```bash
# 해결 방법
xattr -cr /Applications/Pronto.app
open -a Pronto
```

또는 Finder에서 `Pronto.app` 우클릭 → "열기"

---

## Profile 관련

### Q: Profile이 안 보여요

**A:** `~/.aws/config` 파일을 확인하세요.

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

**체크리스트:**
- [ ] `~/.aws/config` 파일이 존재하는가?
- [ ] SSO Profile 설정이 있는가? (`sso_account_id`, `sso_role_name`)

---

### Q: SSO 로그인이 안돼요

**A:** AWS CLI 설치를 확인하세요.

```bash
# AWS CLI 버전 확인
aws --version

# 경로 확인
which aws
# Apple Silicon: /opt/homebrew/bin/aws
# Intel: /usr/local/bin/aws
```

**없다면:**
```bash
brew install awscli
```

---

## 환경변수 관련

### Q: 새 터미널에서 `$AWS_PROFILE`이 안 보여요

**A:** 새 터미널 **창/탭**을 열어야 합니다 (기존 창이 아닌).

```bash
# Shell 설정 확인
cat ~/.zshrc | grep pronto

# 출력 예시:
# [ -f ~/.pronto_profile ] && source ~/.pronto_profile
```

**없다면:**
- Pronto 재설치 또는
- 수동으로 추가:
```bash
echo '[ -f ~/.pronto_profile ] && source ~/.pronto_profile' >> ~/.zshrc
```

---

### Q: 기존 터미널 세션에서 Profile을 바로 적용하고 싶어요

**A:** 두 가지 방법이 있습니다.

**방법 1: 설정에서 활성화 (iTerm2/Terminal.app만)**
- Pronto 설정 → "터미널 세션 업데이트" 활성화

**방법 2: 수동 적용 (모든 터미널)**
```bash
source ~/.pronto_profile
```

---

## 기타

### Q: Pronto가 실행되지 않아요

**A:** 다음을 확인하세요:

```bash
# 1. 앱이 설치되어 있는지
ls -la /Applications/Pronto.app

# 2. quarantine 속성 제거
xattr -cr /Applications/Pronto.app

# 3. 다시 실행
open -a Pronto
```

---

### Q: Profile 전환 후 AWS 명령어가 안 먹혀요

**A:** 새 터미널을 열거나, 기존 터미널에서:

```bash
source ~/.pronto_profile
aws sts get-caller-identity
```

---

### Q: 여러 AWS 계정을 동시에 사용하고 싶어요

**A:** 각 터미널 세션마다 다른 Profile을 사용할 수 있습니다:

```bash
# 터미널 1
export AWS_PROFILE=account-a

# 터미널 2
export AWS_PROFILE=account-b
```

Pronto는 **새 터미널의 기본값**만 설정합니다.

---

## 문제가 해결되지 않나요?

[Issues에 버그 리포트](https://github.com/YOUR_USERNAME/pronto/issues)를 남겨주세요!
