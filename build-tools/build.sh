#!/usr/bin/env bash
# Equivalente para Arch Linux de build.cmd (Windows).
#
# Uso (desde la raiz del proyecto, "Prisma launcher"):
#   ./build-tools/build.sh deps        instala las dependencias con pacman (pide sudo)
#   ./build-tools/build.sh configure   configura CMake
#   ./build-tools/build.sh build       compila (es la accion por defecto)
#   ./build-tools/build.sh install     instala en $PREFIX
#
# Variables opcionales:
#   PRISM_MSA_CLIENT_ID  identificador de cliente de Microsoft. No se guarda en el repo.
#                        Si no se define, se usa el de Prism (la documentacion del proyecto
#                        indica no usarlo).
#   PREFIX               carpeta de instalacion (por defecto: <raiz>/app-linux)
#   BUILD_DIR            carpeta de compilacion (por defecto: <raiz>/source/build-arch)
#   JOBS                 trabajos en paralelo (por defecto: nproc)
#   QT_PREFIX            prefijo de Qt 6 si no esta en la ruta estandar (opcional)

set -euo pipefail

ROOT="${PRISM_ROOT:-/mnt/g/Proyectos/Prisma launcher}"
SRC="$ROOT/source"
BLD="${BUILD_DIR:-$SRC/build-arch}"
PREFIX="${PREFIX:-$ROOT/app-linux}"
JOBS="${JOBS:-$(nproc)}"

# Paquetes de Arch Linux equivalentes a los que usa .github/actions/setup-dependencies/linux
PACKAGES=(
    base-devel
    cmake
    ninja
    extra-cmake-modules
    pkgconf
    scdoc
    qt6-base
    qt6-tools
    qt6-networkauth
    cmark
    libarchive
    libqrencode
    zlib
    tomlplusplus
    xcb-util-cursor
)

check_source() {
    if [[ ! -f "$SRC/CMakeLists.txt" ]]; then
        echo "ERROR: no se encuentra el codigo fuente en $SRC" >&2
        exit 1
    fi
}

install_deps() {
    # Usa sudo solo si no somos root (en WSL el usuario por defecto puede ser root)
    local pm=(pacman -S --needed --noconfirm)
    if [[ $EUID -ne 0 ]]; then
        pm=(sudo "${pm[@]}")
    fi
    "${pm[@]}" "${PACKAGES[@]}"
}

configure() {
    check_source

    local args=(
        -S "$SRC"
        -B "$BLD"
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="$PREFIX"
        -DENABLE_LTO=ON
        -DLauncher_QT_VERSION_MAJOR=6
        -DLauncher_BUILD_PLATFORM=archlinux
        -DLauncher_ENABLE_JAVA_DOWNLOADER=ON
    )

    if [[ -n "${QT_PREFIX:-}" ]]; then
        args+=(-DCMAKE_PREFIX_PATH="$QT_PREFIX")
    fi

    if [[ -n "${PRISM_MSA_CLIENT_ID:-}" ]]; then
        args+=(-DLauncher_MSA_CLIENT_ID="$PRISM_MSA_CLIENT_ID")
    else
        echo "AVISO: PRISM_MSA_CLIENT_ID no esta definido. Se usara el identificador de Prism" >&2
        echo "       (la documentacion del proyecto indica no usarlo en esta beta)." >&2
    fi

    cmake "${args[@]}"
}

ensure_configured() {
    if [[ ! -f "$BLD/CMakeCache.txt" ]]; then
        echo "Todavia no esta configurado. Configurando primero..."
        configure
    fi
}

build() {
    ensure_configured
    cmake --build "$BLD" --config Release --parallel "$JOBS"
}

install_app() {
    if [[ ! -f "$BLD/CMakeCache.txt" ]]; then
        echo "ERROR: no hay compilacion en $BLD. Ejecuta primero: build.sh build" >&2
        exit 1
    fi
    cmake --install "$BLD" --config Release
}

case "${1:-build}" in
    deps)       install_deps ;;
    configure)  configure ;;
    build)      build ;;
    install)    install_app ;;
    *)
        echo "Uso: $0 [deps|configure|build|install]" >&2
        exit 1
        ;;
esac
