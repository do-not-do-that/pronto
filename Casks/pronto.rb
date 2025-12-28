cask "pronto" do
  version "1.0.0"
  sha256 "713650873239d10da8e84048d4a0ed99da890d836a59ef2ea74b7a15ef4a0192"

  url "https://github.com/YOUR_USERNAME/pronto/releases/download/v#{version}/Pronto.app.zip"
  name "Pronto"
  desc "AWS SSO profile switcher for macOS menu bar"
  homepage "https://github.com/YOUR_USERNAME/pronto"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "Pronto.app"

  zap trash: [
    "~/.pronto_profile",
    "~/.pronto_initialized",
    "~/Library/Preferences/com.donotdothat.pronto.Pronto.plist",
  ]

  caveats <<~EOS
    Pronto가 설치되었습니다!

    ⚠️  처음 실행 시 "확인되지 않은 개발자" 경고가 나타납니다.
    이것은 정상입니다. 오픈소스 프로젝트로 Apple 서명이 없습니다.

    해결 방법:
    1. Finder에서 /Applications/Pronto.app 우클릭
    2. "열기" 클릭 → "열기" 버튼 클릭

    또는 터미널에서:
       $ xattr -cr /Applications/Pronto.app
       $ open -a Pronto

    사용 방법:
    1. AWS CLI v2가 설치되어 있는지 확인하세요
       $ aws --version

    2. ~/.aws/config에 SSO 설정이 있는지 확인하세요

    3. 메뉴바에서 ☁️ 아이콘을 클릭하고 Profile을 선택하세요

    문제 해결:
    - Profile이 보이지 않으면: ~/.aws/config 파일을 확인하세요
    - SSO 로그인이 안 되면: AWS CLI 설치를 확인하세요

    더 자세한 정보:
    https://github.com/YOUR_USERNAME/pronto#readme
  EOS
end
