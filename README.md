# ubuntu-server-bootstrap

Ubuntu 서버(특히 OCI/클라우드 VM)를 **안전하게/반복 가능하게** 초기 세팅하는 스크립트 묶음입니다.

- 멱등(idempotent): **몇 번 실행해도** 같은 결과
- SSH 설정은 **검증 후 적용** (`sshd -t` 통과 못하면 재시작 안 함)
- 설정 충돌 방지: `/etc/ssh/sshd_config.d/99-zz-bootstrap.conf` **한 파일로 오버라이드**
- 로그: `/var/log/ubuntu-server-bootstrap.log`

> ⚠️ `ssh: connect ... timed out` 는 대부분 **클라우드(NSG/Security List)에서 22 포트가 막힌 것**입니다.  
> 서버 스크립트로 해결 안 됩니다. 먼저 22가 열려있는지 테스트하세요.

---

## 빠른 사용법 (복붙용)

### 1) 레포 클론 + 설치 실행
```bash
git clone https://github.com/mikuchan1004/ubuntu-server-bootstrap.git
cd ubuntu-server-bootstrap

# 실행 권한(Windows에서 zip/복사해오면 권한이 날아갈 수 있음)
chmod +x install.sh scripts/*.sh

sudo bash install.sh
```

### 2) (권장) admin 계정 + 공개키까지 한 번에
공개키 파일이 있다면(예: `./keys/admin.pub`) 이렇게 실행하면 **authorized_keys까지 자동 등록**됩니다.

```bash
git clone https://github.com/mikuchan1004/ubuntu-server-bootstrap.git
cd ubuntu-server-bootstrap
chmod +x install.sh scripts/*.sh

sudo bash install.sh   --admin-user admin   --admin-pubkey "$(cat ./keys/admin.pub)"   --allow-password-ssh true
```

---

## 실행 전에 꼭 확인 (OCI/클라우드)

### 포트 22 먼저 체크 (윈도우 PowerShell)
```powershell
Test-NetConnection <PUBLIC_IP> -Port 22
```

- `TcpTestSucceeded : True` ✅ → 네트워크 OK, 이제 SSH 인증(키/계정)만 보면 됨
- `False` / Timeout ❌ → **OCI NSG / 보안 목록 / 라우팅**부터 해결해야 함

---

## 옵션

```bash
sudo bash install.sh --help
```

자주 쓰는 것만:
- `--admin-user <name>` (기본: admin)
- `--admin-pubkey "<ssh public key>"`  ← authorized_keys 자동 등록(실수 방지)
- `--allow-password-ssh true|false` (기본: true)
- `--timezone <TZ>` (기본: Asia/Seoul)
- `--swap-mb <MB>` (기본: 2048)

---

## 트러블슈팅

### 1) SSH가 타임아웃
- **거의 100% 클라우드 측 방화벽(NSG/Security List)** 문제입니다.
- 먼저 PowerShell에서 22 포트부터 확인하세요:
```powershell
Test-NetConnection <PUBLIC_IP> -Port 22
```

### 2) 포트 22는 열렸는데 Permission denied
서버에서 아래만 확인하면 됩니다.
```bash
sudo su - admin
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```
정답 권한:
- `~/.ssh` → `700`
- `authorized_keys` → `600`

---

## 로그
```bash
sudo tail -n 200 /var/log/ubuntu-server-bootstrap.log
```

---

## 라이선스
MIT (repo의 LICENSE 참고)
