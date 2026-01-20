#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL_DIR="$ROOT_DIR/templates"

echo "[40] MOTD/Banner (Korean) 적용 시작"

if [[ ! -d "$TPL_DIR" ]]; then
  echo " ! templates/ 폴더를 찾을 수 없습니다: $TPL_DIR"
  exit 1
fi

# 1) SSH 배너 (/etc/issue.net)
if [[ -f "$TPL_DIR/issue.net" ]]; then
  install -m 0644 "$TPL_DIR/issue.net" /etc/issue.net
  echo " - /etc/issue.net 배포 완료"
else
  echo " ! templates/issue.net 없음 (스킵)"
fi

# 2) 고정 MOTD (/etc/motd)
if [[ -f "$TPL_DIR/motd" ]]; then
  install -m 0644 "$TPL_DIR/motd" /etc/motd
  echo " - /etc/motd 배포 완료"
else
  echo " ! templates/motd 없음 (스킵)"
fi

# 3) 동적 MOTD (/etc/update-motd.d/99-custom)
mkdir -p /etc/update-motd.d
if [[ -f "$TPL_DIR/update-motd.d/99-custom" ]]; then
  install -m 0755 "$TPL_DIR/update-motd.d/99-custom" /etc/update-motd.d/99-custom

  # CRLF/BOM 방어 (있으면 제거)
  if command -v perl >/dev/null 2>&1; then
    perl -i -pe 's/\r$//; s/^\xEF\xBB\xBF//' /etc/update-motd.d/99-custom || true
  fi

  echo " - /etc/update-motd.d/99-custom 배포 완료"
else
  echo " ! templates/update-motd.d/99-custom 없음 (스킵)"
fi

# 4) 기본 영어 MOTD 메시지 끄기 (있으면 실행권한 제거)
for f in /etc/update-motd.d/50-motd-news /etc/update-motd.d/90-updates-available; do
  if [[ -e "$f" ]]; then
    chmod -x "$f" || true
    echo " - $(basename "$f") 실행 비활성화"
  fi
done

echo "[40] 완료. 다음 로그인에서 한글 메시지/상태가 표시됩니다."
