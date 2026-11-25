#!/bin/bash
# ============================================================
# build.sh – Docker Build & Push dengan Versioning
# Format versi: YYYY.MM.DD-N (mis. 2026.11.17-1, 2026.11.17-2)
# Usage: ./build.sh [--push] [--no-cache]
# ============================================================

set -e

REPO="shabeuy/sumbertani-app"
VERSION_FILE=".docker-build-version"
HISTORY_FILE=".docker-build-history"

# ── Parse flags ───────────────────────────────────────────
AUTO_PUSH=false
NO_CACHE=""

for arg in "$@"; do
    case $arg in
        --push)     AUTO_PUSH=true ;;
        --no-cache) NO_CACHE="--no-cache" ;;
    esac
done

# ── Generate versi YYYY.MM.DD-N ──────────────────────────
DATE=$(date +%Y.%m.%d)

if [ -f "$VERSION_FILE" ]; then
    LAST=$(cat "$VERSION_FILE")
    LAST_DATE="${LAST%-*}"
    LAST_N="${LAST##*-}"
    if [ "$LAST_DATE" = "$DATE" ]; then
        N=$((LAST_N + 1))
    else
        N=1
    fi
else
    N=1
fi

VERSION="${DATE}-${N}"
IMAGE="${REPO}:${VERSION}"
LATEST="${REPO}:latest"

# ── Build ─────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🔨 Building  : ${IMAGE}"
echo " 🏷️  Also tags : ${LATEST}"
[ -n "$NO_CACHE" ] && echo " ⚠️  --no-cache aktif"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker build --network=host $NO_CACHE \
    -t "$IMAGE" \
    -t "$LATEST" \
    .

echo ""
echo "✅ Build sukses: ${IMAGE}"

# Simpan versi terakhir
echo "$VERSION" > "$VERSION_FILE"

# ── Push ─────────────────────────────────────────────────
if [ "$AUTO_PUSH" = true ]; then
    PUSH="y"
else
    echo ""
    read -p "🚀 Push ke Docker Hub? (y/N) " PUSH
fi

if [[ "$PUSH" =~ ^[Yy]$ ]]; then
    echo ""
    docker push "$IMAGE"
    docker push "$LATEST"

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${TIMESTAMP} | ${VERSION} | pushed" >> "$HISTORY_FILE"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " ✅ Pushed : ${IMAGE}"
    echo " ✅ Pushed : ${LATEST}"
    echo ""
    echo " 🔄 Rollback di VPS (jika perlu):"
    echo "    docker compose down"
    echo "    APP_IMAGE=${IMAGE} docker compose up -d"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    echo "⏭️  Skip push. Jalankan manual:"
    echo "   docker push ${IMAGE}"
    echo "   docker push ${LATEST}"
fi
