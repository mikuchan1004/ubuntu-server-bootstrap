# Ubuntu Server Bootstrap

Ubuntu 서버 최초 세팅을 **안전하고 반복 가능하게** 자동화하는 Bootstrap 스크립트 모음입니다.  
특히 **OCI(Oracle Cloud Infrastructure)** 환경에서 실제 삽질을 통해 검증된 구성을 포함합니다.

---

## 🎯 목적

- 새 Ubuntu 서버 생성 후 반복되는 초기 세팅 자동화
- SSH 접속 불가 / 키 인증 꼬임 / sshd 설정 충돌 방지
- admin 계정 표준화 + sudo 권한
- cloud-init / cloudimg SSH 설정 충돌 제거
- OCI 네트워크(NSG / Security List) 문제 명확히 분리

---

## ✅ 지원 환경

- Ubuntu 22.04 LTS
- OCI (Oracle Cloud Infrastructure)
- 일반 VPS / 로컬 VM

---

## 📁 디렉터리 구조

```text
ubuntu-server-bootstrap/
├─ install.sh
├─ scripts/
│  ├─ 00-common.sh
│  ├─ 10-init.sh
│  ├─ 20-admin-user.sh
│  ├─ 30-ssh.sh
│  └─ 40-motd-banner.sh
├─ keys/
│  └─ admin.pub
└─ README.md
```

---

## 🚀 빠른 사용법 (복붙용)

### 1) 서버에서 레포 클론

```bash
git clone https://github.com/mikuchan1004/ubuntu-server-bootstrap.git
cd ubuntu-server-bootstrap
```

### 2) 실행 권한 부여

```bash
chmod +x install.sh scripts/*.sh
```

### 3) admin 공개키 준비

```bash
mkdir -p keys
nano keys/admin.pub
# ssh-ed25519 또는 ssh-rsa 공개키 한 줄 그대로 붙여넣기
```

### 4) 설치 실행

```bash
sudo bash install.sh   --admin-user admin   --admin-pubkey "$(cat keys/admin.pub)"   --allow-password-ssh true
```

> 🔐 `--allow-password-ssh true`  
> 초기 접속 안전망용. 이후 false로 다시 실행 가능.

---

## 🔐 SSH 정책 요약

- 최종 오버라이드 파일:
  ```
  /etc/ssh/sshd_config.d/99-zz-bootstrap.conf
  ```
- cloudimg / 기존 설정과 충돌 방지
- sshd 설정 변경 전 `sshd -t` 검증 후 적용

확인:
```bash
sudo sshd -T | egrep 'passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication'

```
## 🖥 SSH 로그인 배너 & MOTD (한글)

Ubuntu 서버에서 SSH 로그인 시  
한글 경고 배너와 서버 상태 요약(MOTD)을 표시합니다.

### 적용 내용
- SSH 로그인 전 경고 배너 (`/etc/issue.net`)
- 로그인 후 환영 메시지 (`/etc/motd`)
- 로그인 시 서버 상태 요약 (업타임, 디스크, 메모리, Fail2Ban)
- 불필요한 영어 MOTD 메시지 비활성화

### 템플릿 구조
templates/
├─ issue.net
├─ motd
└─ update-motd.d/
└─ 99-custom

### 적용 방법 (서버에서 실행)

sudo bash scripts/40-motd-banner.sh

적용 후 SSH 재접속 시 한글 메시지가 표시됩니다.

참고
Ubuntu의 update-motd 시스템을 사용합니다.

99-custom 파일은 확장자 없이 배치해야 정상 실행됩니다.

---

## 🌐 OCI 네트워크 필수 체크 (중요)

### 1️⃣ Security List
- 인바운드
  - TCP
  - 포트 22
  - 소스: 0.0.0.0/0

### 2️⃣ NSG (사용 시)
- TCP 22 허용 규칙 추가
- **반드시 인스턴스 VNIC에 연결**

> ❗ NSG만 만들고 VNIC에 연결 안 하면 아무 효과 없음

### 3️⃣ 포트 테스트 (윈도우)

```powershell
Test-NetConnection <PUBLIC_IP> -Port 22
```

- True → 서버 설정 문제 아님
- False → OCI 네트워크 문제

---

## 🧪 트러블슈팅

### SSH timeout
- 서버 문제 아님
- OCI NSG / Security List / 라우팅 확인

### Permission denied (publickey)
```bash
sudo su - admin
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

권한:
- ~/.ssh → 700
- authorized_keys → 600

---

## 🧠 설계 원칙

- SSH 접속 최우선
- 복구 불가능한 설정 변경 금지
- 실서버 기준, 재현 가능한 실패 제거

---

## 📌 추천 운영 흐름

1. 서버 생성
2. bootstrap 실행
3. admin 계정 SSH 접속 확인
4. (선택) 패스워드 SSH 비활성화
5. 스냅샷

---

## 📄 라이선스

MIT License
