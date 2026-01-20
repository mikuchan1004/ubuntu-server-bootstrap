#!/bin/bash
# Custom MOTD (Korean)

echo "========================================"
echo " 🖥  서버 상태 요약"
echo "----------------------------------------"
echo " 📅 현재 시간  : $(date '+%Y-%m-%d %H:%M:%S')"
echo " 👤 로그인 계정: $(whoami)"

# SSH 접속 IP (콘솔이면 비어있을 수 있음)
if [ -n "$SSH_CLIENT" ]; then
  echo " 🌐 접속 IP    : ${SSH_CLIENT%% *}"
else
  echo " 🌐 접속 IP    : (콘솔/로컬)"
fi

echo " ⏱  업타임     : $(uptime -p)"
echo " 💾 디스크(/)  : $(df -h / | awk 'NR==2 {print $4}') 여유"
echo " 🧠 메모리     : $(free -h | awk '/Mem:/ {print $4}') 여유"

# fail2ban (없거나 권한 문제면 N/A)
BANNED="$(fail2ban-client status sshd 2>/dev/null | awk -F': ' '/Currently banned/ {print $2}')"
if [ -n "$BANNED" ]; then
  echo " 🔐 Fail2Ban   : ${BANNED} IP 차단 중"
else
  echo " 🔐 Fail2Ban   : N/A"
fi

echo "========================================"
