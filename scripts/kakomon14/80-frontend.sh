#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

ISUREN_HOME="/home/${ISUREN_USER}"
MISE_BIN="${ISUREN_HOME}/.local/bin/mise"
FRONTEND_DIR="${ISUREN_HOME}/isucon14/frontend"
WEBAPP_PUBLIC_DIR="${ISUREN_HOME}/webapp/public"

# 対応: frontend-buildタスクの「やること」1点目。
# ビルドのたびに最新化する必要があるため、changed/already判定はせず常に実行する。
# runuser経由では.bashrcを経由せずmise/pnpmがPATHに乗らないため、mise本体はフルパスで呼ぶ。
# pnpm 10以降はesbuild/@swc/core等のpostinstallスクリプトをデフォルトでブロックする(strictDepBuilds)。
# 未承認の状態だと1回目のpnpm installがERR_PNPM_IGNORED_BUILDSでexit 1になるため失敗を許容し、
# pnpm approve-builds --all(非対話で全承認)を挟んでから再度installしてscriptを実行させる。
build_frontend() {
  # shellcheck disable=SC2016 # env経由で渡したFRONTEND_DIR/MISE_BINをsh -c内で展開させる
  runuser -u "${ISUREN_USER}" -- env FRONTEND_DIR="${FRONTEND_DIR}" MISE_BIN="${MISE_BIN}" \
    sh -c 'cd "${FRONTEND_DIR}" &&
      ("${MISE_BIN}" exec -- pnpm install --frozen-lockfile || true) &&
      "${MISE_BIN}" exec -- pnpm approve-builds --all &&
      "${MISE_BIN}" exec -- pnpm install --frozen-lockfile &&
      "${MISE_BIN}" exec -- pnpm run build'
  log "frontend: built"
}

# webapp/publicはisucon14の.gitignoreに入っているため、cloneしたツリー内でビルドしてもツリーは汚れない。
# rsync --deleteで、前回ビルドの古いファイル(ハッシュ付きファイル名が変わったもの等)を確実に除去する。
# isurenユーザーで実行し、所有者を揃える(chownでの後追い修正を避ける)。
sync_public() {
  # shellcheck disable=SC2016 # env経由で渡したFRONTEND_DIR/WEBAPP_PUBLIC_DIRをsh -c内で展開させる
  runuser -u "${ISUREN_USER}" -- env FRONTEND_DIR="${FRONTEND_DIR}" WEBAPP_PUBLIC_DIR="${WEBAPP_PUBLIC_DIR}" \
    sh -c 'mkdir -p "${WEBAPP_PUBLIC_DIR}" && rsync -a --delete "${FRONTEND_DIR}/build/client/" "${WEBAPP_PUBLIC_DIR}/"'
  log "webapp/public: synced"
}

build_frontend
sync_public

log "80-frontend.sh: done"
