# 🐧 ubuntu-server-bootstrap

Ubuntu 서버 초기 설정을 자동화하기 위한 개인용 부트스트랩 스크립트 모음입니다.  
보안 기본 설정부터 SSH 로그인 배너, MOTD(서버 상태 메시지)까지  
**실사용 기준으로 안정적이고 반복 적용 가능한 구성**을 목표로 합니다.

---

## ✨ 주요 기능

- 기본 서버 초기 설정 자동화
- SSH 로그인 배너 (한글 경고 메시지)
- 로그인 후 MOTD (서버 상태 요약 한글 출력)
- 불필요한 기본 MOTD 메시지 비활성화
- 스크립트 단위 실행 가능 (필요한 것만 선택 적용)

---

## 🖥 SSH 로그인 배너 & MOTD (한글)

SSH 로그인 시 아래 정보가 표시됩니다.

### 적용 내용
- 🔐 **로그인 전 배너**: 접근 제한 경고 (`/etc/issue.net`)
- 👋 **로그인 후 메시지**: 환영 문구 (`/etc/motd`)
- 📊 **서버 상태 요약 (동적 MOTD)**
  - 현재 시간
  - 로그인 계정
  - 접속 IP
  - 업타임
  - 디스크 여유 공간
  - 메모리 여유
  - Fail2Ban 차단 상태
- ❌ 불필요한 영어 MOTD 메시지 비활성화

---

## 📁 템플릿 구조

```
templates/
├─ issue.net
├─ motd
└─ update-motd.d/
   └─ 99-custom
```

- `issue.net`  
  → SSH 로그인 **전** 경고 배너
- `motd`  
  → 로그인 **후** 고정 환영 메시지
- `99-custom`  
  → 로그인 시 서버 상태를 출력하는 동적 MOTD 스크립트  
  (Ubuntu `update-motd` 시스템 사용)

⚠️ `99-custom` 파일은 **확장자 없이** 사용해야 정상 동작합니다.

---

## 🚀 적용 방법

### 1️⃣ 레포 클론 후 실행 (권장)

```
git clone https://github.com/mikuchan1004/ubuntu-server-bootstrap.git
cd ubuntu-server-bootstrap
chmod +x scripts/40-motd-banner.sh
sudo bash scripts/40-motd-banner.sh
```

적용 후 SSH를 재접속하면 한글 메시지가 표시됩니다.

---

### 2️⃣ 실행 결과 확인

```
logout
```

다시 SSH 접속 후 다음을 확인하세요:

- 로그인 전: 한글 접근 제한 배너
- 로그인 후: 서버 상태 요약(MOTD)

---

## 🧪 문제 발생 시 점검

```
ls -l /etc/issue.net
ls -l /etc/motd
ls -l /etc/update-motd.d/99-custom
run-parts /etc/update-motd.d/
```

---

## ⚠️ 주의 사항

- Ubuntu 기준으로 작성되었습니다.
- `update-motd` 시스템을 사용하지 않는 배포판에서는 동작이 다를 수 있습니다.
- 실서버 적용 전 테스트 서버에서 실행을 권장합니다.

---

## 📌 목적

이 레포는  
“한 번 정리해두고, 서버를 새로 만들 때마다 그대로 가져다 쓰는 것”을 목표로 합니다.

과한 설정보다는  
**안전하고, 이해 가능하며, 유지보수 가능한 구성**을 지향합니다.

---

## 📄 라이선스

개인 학습 및 사용 목적에 한해 자유롭게 사용 가능합니다.
