# Ubuntu Server Bootstrap

Ubuntu 서버를 **실운영 가능한 기본 상태**로 빠르게 세팅하기 위한  
Bootstrap 스크립트 모음입니다.

이 레포는 **GitHub Template repository**로 사용하도록 설계되었으며,  
새 서버를 만들 때마다 동일한 환경을 손쉽게 재현할 수 있습니다.

---

## Features

### Base Initialization
- Timezone: Asia/Seoul  
- Locale: ko_KR.UTF-8  
  - 시스템 메시지는 영문 유지 (LC_MESSAGES=C)
- SSH Hardening  
  - root 로그인 차단  
  - 비밀번호 로그인 유지 (키 인증 강제하지 않음)
- Swap 생성 (기본 2GB)
- 메모리 튜닝 (vm.swappiness, vm.vfs_cache_pressure)
- journald 로그 크기 제한
- UFW + Fail2ban 활성화

### Login / Security UX
- SSH Pre-login Banner (/etc/issue.net)
- Login MOTD  
  - Uptime / Load  
  - Disk / Memory / Swap 상태 요약

### User Management
- Ubuntu 친화적 관리자 계정 생성  
  - 동일 이름 그룹 존재 시 재사용
- sudo 권한 자동 부여
- (선택) SSH 공개키 주입

---

## Repository Structure

ubuntu-server-bootstrap/
- scripts/
  - init-ubuntu-server.sh
  - setup-login-banner.sh
  - setup-motd.sh
  - create-admin-user.sh
- templates/
  - issue.net
  - motd-99-custom.sh
- README.md
- LICENSE

---

## Quick Start

sudo apt update && sudo apt install -y git  
git clone https://github.com/mikuchan1004/ubuntu-server-bootstrap.git  
cd ubuntu-server-bootstrap  
chmod +x scripts/*.sh  
sudo bash scripts/init-ubuntu-server.sh  
sudo bash scripts/setup-login-banner.sh  
sudo bash scripts/setup-motd.sh  
sudo bash scripts/create-admin-user.sh admin  

재부팅은 필요 없으며 **SSH 재접속만 권장**합니다.

---

## Template Repository Usage

- GitHub에서 “Use this template” 클릭
- 새 서버용 레포 생성
- 클론 후 스크립트 실행만으로 동일 환경 구성

---

## Design Policy

- SSH 키 인증을 강제하지 않음  
  (키 유실 시 복구 불가 상황 방지)
- Fail2ban / UFW / SSH 하드닝으로 실질 보안 확보
- 실운영 기준의 현실적인 보안과 편의성 균형을 목표로 설계

---

## Notes

- Ubuntu Server 기준 테스트
- root 권한 필요
- 재실행해도 대부분 안전하게 동작하도록 설계됨

---

## License

MIT License
