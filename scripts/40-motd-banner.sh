#!/usr/bin/env bash
set -euo pipefail

# 현재 스크립트 위치 기준
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL_DIR="$ROOT_DIR/templates"

echo "[40] MOTD/Banner (Korean) 적용 시작"

# 1) SSH 배너: /etc/issue.net
if [[ -f "$TPL_DIR/issue.net" ]]; then
  install -m 0644 "$TPL_DIR/issue.net" /etc/issue.net
  echo " - /etc/issue.net 배포 완료"
else
  echo " ! templates/issue.net 없음 (스킵)"
fi

# 2) 고정 MOTD: /etc/motd (주의문구/환영문만 권장)
if [[ -f "$TPL_DIR/motd" ]]; then
  install -m 0644 "$TPL_DIR/motd" /etc/motd
  echo " - /etc/motd 배포 완료"
else
  echo " ! templates/motd 없음 (스킵)"
fi

# 3) update-motd 커스텀 스크립트: /etc/update-motd.d/99-custom
if [[ -f "$TPL_DIR/update-motd.d/99-custom" ]]; then
  install -m 0755 "$TPL_DIR/update-motd.d/99-custom" /etc/update-motd.d/99-custom
  echo " - /etc/update-motd.d/99-custom 배포 완료"
else
  echo " ! templates/update-motd.d/99-custom 없음 (스킵)"
fi

# 4) (선택) 영어 뉴스/업데이트 메시지 끄기
for f in /etc/update-motd.d/50-motd-news /etc/update-motd.d/90-updates-available; do
  if [[ -e "$f" ]]; then
    chmod -x "$f" || true
    echo " - $(basename "$f") 실행 비활성화"
  fi
done

echo "[40] 완료. 즉시 확인: run-parts /etc/update-motd.d/ | sed -n '1,40p'"
echo "[40] 다음 로그인부터 한글 메시지/상태가 표시됩니다."
