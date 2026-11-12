#!/usr/bin/env bash
# ============================================================================
# build-stockfish-android.sh — Phase 14 (V4.2, portage Android checkmate-mate)
#
# Compile Stockfish officiel pour Android arm64-v8a avec le NDK et dépose le
# binaire dans android/app/src/main/jniLibs/arm64-v8a/libstockfish.so.
#
# Prérequis (Ubuntu) :
#   - Android NDK r28+ (installé via Android Studio > SDK Manager > NDK,
#     ou téléchargé sur https://developer.android.com/ndk)
#     ⚠️ r28 MINIMUM : depuis le 1er nov. 2025, Google Play exige que le code
#     natif des apps ciblant l'API 35+ supporte les pages mémoire de 16 Ko.
#     Le NDK r28 aligne les ELF en 16 Ko PAR DÉFAUT ; les r26/r27 non (le
#     binaire serait refusé ou signalé par la Play Console). Une vérification
#     automatique de l'alignement est faite en fin de script.
#   - git, make, curl (pour le téléchargement du réseau NNUE par le Makefile)
#
# Usage :
#   export ANDROID_NDK_HOME=~/Android/Sdk/ndk/26.3.11579264   # adapter
#   ./build-stockfish-android.sh
#
# Le réseau NNUE (gros + petit) est TÉLÉCHARGÉ par le Makefile officiel puis
# EMBARQUÉ dans le binaire (cible `make net` implicite) : rien d'autre à
# provisionner, le moteur est autonome et hors-ligne.
#
# Conformité GPLv3 : Stockfish est compilé NON MODIFIÉ depuis le tag épinglé
# ci-dessous. Conserver ce script et le tag = « scripts de contrôle de la
# compilation » exigés par la licence (cf. RAPPORT-ARCHITECTURE.md §Licence).
# ============================================================================
set -euo pipefail

# Tag officiel épinglé — mettre à jour ici pour suivre les versions Stockfish.
# Architecture : armv8 = compatible TOUS les arm64 (recommandé pour Play).
#   SF_ARCH=armv8-dotprod gagne ~20-30 % de NPS sur les SoC ≥ 2018
#   (Cortex-A75+/Snapdragon 845+) mais PLANTE (SIGILL) sur les plus anciens —
#   à réserver à un build perso pour TON appareil.
SF_TAG="${SF_TAG:-sf_18}"
SF_ARCH="${SF_ARCH:-armv8}"

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$HERE/android/app/src/main/jniLibs/arm64-v8a"
WORK_DIR="$HERE/.stockfish-build"

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  # Tentative de détection standard
  for c in "$HOME"/Android/Sdk/ndk/*/ ; do
    [[ -d "$c" ]] && ANDROID_NDK_HOME="${c%/}" && break
  done
fi
if [[ -z "${ANDROID_NDK_HOME:-}" || ! -d "$ANDROID_NDK_HOME" ]]; then
  echo "❌ ANDROID_NDK_HOME non défini ou introuvable." >&2
  echo "   export ANDROID_NDK_HOME=~/Android/Sdk/ndk/<version>" >&2
  exit 1
fi

TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
if [[ ! -d "$TOOLCHAIN" ]]; then
  echo "❌ Toolchain LLVM introuvable dans $TOOLCHAIN" >&2
  exit 1
fi

echo "→ NDK       : $ANDROID_NDK_HOME"
echo "→ Tag SF    : $SF_TAG"
echo "→ ARCH      : $SF_ARCH"

mkdir -p "$WORK_DIR"
if [[ ! -d "$WORK_DIR/Stockfish" ]]; then
  git clone --depth 1 --branch "$SF_TAG" https://github.com/official-stockfish/Stockfish.git "$WORK_DIR/Stockfish"
fi

cd "$WORK_DIR/Stockfish/src"

# COMP=ndk : chemin officiel du Makefile de Stockfish pour Android. Il attend
# le toolchain LLVM du NDK dans le PATH (clang cible aarch64-linux-android).
export PATH="$TOOLCHAIN/bin:$PATH"

# `build` (pas `profile-build` : impossible d'exécuter le binaire cible en
# cross-compilation). ARCH=armv8 = arm64-v8a avec NEON.
make clean
make -j"$(nproc)" build ARCH="$SF_ARCH" COMP=ndk

# Strip : divise la taille par ~2 sans effet sur les perfs.
"$TOOLCHAIN/bin/llvm-strip" stockfish

mkdir -p "$OUT_DIR"
cp stockfish "$OUT_DIR/libstockfish.so"
chmod 755 "$OUT_DIR/libstockfish.so"

# Vérification alignement 16 Ko (exigence Play, API 35+). Les segments LOAD
# de l'ELF doivent être alignés sur 0x4000 (16384). NDK r28+ : automatique.
ALIGN_MIN=""
while read -r hex; do
  val=$((hex))                     # bash convertit 0x... nativement
  [[ -z "$ALIGN_MIN" || "$val" -lt "$ALIGN_MIN" ]] && ALIGN_MIN=$val
done < <("$TOOLCHAIN/bin/llvm-readelf" -l "$OUT_DIR/libstockfish.so" | awk '/LOAD/ {print $NF}')
if [[ -n "$ALIGN_MIN" && "$ALIGN_MIN" -ge 16384 ]]; then
  echo "✅ Alignement 16 Ko OK (min LOAD align = $ALIGN_MIN)"
else
  echo "❌ ALIGNEMENT 16 Ko INSUFFISANT (min LOAD align = ${ALIGN_MIN:-inconnu})." >&2
  echo "   Utilise le NDK r28 ou plus récent, ou ajoute au link :" >&2
  echo "   -Wl,-z,max-page-size=16384 — sinon la Play Console refusera l'app." >&2
  exit 1
fi

echo ""
echo "✅ $(du -h "$OUT_DIR/libstockfish.so" | cut -f1) → $OUT_DIR/libstockfish.so"
echo "   Prochaine étape : cd android && ./gradlew assembleDebug (voir README-BUILD.md)"
