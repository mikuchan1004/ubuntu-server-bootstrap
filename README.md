cat > README.md <<'EOF'
# Ubuntu Server Bootstrap (Template)

Ubuntu 서버를 “운영 가능한 기본 상태”로 빠르게 맞추는 스크립트 모음입니다.  
이 레포는 **Template repository**로 사용하도록 구성되어 있습니다.

## What it does

### 1) Base init (`init-ubuntu-server.sh`)
- Timezone: `Asia/Seoul`
- Locale: `ko_KR.UTF-8` (단, 메시지는 영문 유지: `LC_MESSAGES=C`)
- SSH hardening (키 인증 강제 ❌ / 비밀번호 로그인 유지 ✅ / root 로그인 차단 ✅)
- Swap 생성(기본 2G) + 메모리 튜닝 (`vm.swappiness=10`, `vm.vfs_cache_pressure=50`)
- journald 로그 크기 제한
- UFW + Fail2ban 활성화

### 2) SSH pre-login banner (`setup-login-banner.sh`)
- `/etc/issue.net` 배너 적용
- sshd `Banner` 설정

### 3) MOTD (`setup-motd.sh`)
- `/etc/update-motd.d/99-custom` 설치
- 로그인 시 서버 상태 요약 출력

### 4) Admin user (`create-admin-user.sh`)
- Ubuntu 친화적으로 사용자 생성(동명 그룹 존재 시 재사용)
- `sudo` 그룹 추가
- (옵션) SSH 공개키 주입

---

## Quick start (recommended)

서버에서 아래 순서대로 실행합니다.

```bash
# 1) repo clone
sudo apt update && sudo apt install -y git
git clone https://github.com/<YOU>/<REPO>.git
cd <REPO>

# 2) make scripts executable
chmod +x scripts/*.sh

# 3) base init
sudo bash scripts/init-ubuntu-server.sh

# 4) banner + motd
sudo bash scripts/setup-login-banner.sh
sudo bash scripts/setup-motd.sh

# 5) (optional) create admin user
sudo bash scripts/create-admin-user.sh admin
