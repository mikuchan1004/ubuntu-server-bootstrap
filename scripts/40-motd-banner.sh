#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_40_motd_banner() {
  local root_dir tpl_dir
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  tpl_dir="${root_dir}/templates"

  echo "[40] MOTD/Banner (Korean) 적용 시작"

  # 1) SSH 배너 파일 배포: /etc/issue.net
  if [[ -f "${tpl_dir}/issue.net" ]]; then
    install -m 0644 "${tpl_dir}/issue.net" /etc/issue.net
    echo " - /etc/issue.net 배포 완료"
  else
    echo " ! templates/issue.net 없음 (스킵)"
  fi

  # 2) 고정 MOTD 배포: /etc/motd
  if [[ -f "${tpl_dir}/motd" ]]; then
    install -m 0644 "${tpl_dir}/motd" /etc/motd
    echo " - /etc/motd 배포 완료"
  else
    echo " ! templates/motd 없음 (스킵)"
  fi

  # 3) update-motd 커스텀 상태 출력 스크립트 배포
  install -d -m 0755 /etc/update-motd.d
  if [[ -f "${tpl_dir}/update-motd.d/99-custom" ]]; then
    install -m 0755 "${tpl_dir}/update-motd.d/99-custom" /etc/update-motd.d/99-custom

    # CRLF/BOM 방어
    if command -v perl >/dev/null 2>&1; then
      perl -i -pe 's/\r$//; s/^\xEF\xBB\xBF//' /etc/update-motd.d/99-custom || true
    fi

    echo " - /etc/update-motd.d/99-custom 배포 완료"
  else
    echo " ! templates/update-motd.d/99-custom 없음 (스킵)"
  fi

  # 4) (선택) 영어 뉴스/업데이트 메시지 끄기 (있으면 실행권한 제거)
  for f in /etc/update-motd.d/50-motd-news /etc/update-motd.d/90-updates-available; do
    if [[ -e "$f" ]]; then
      chmod -x "$f" || true
      echo " - $(basename "$f") 실행 비활성화"
    fi
  done

  echo "[40] 완료. 다음 로그인에서 한글 메시지/상태가 표시됩니다."
}
