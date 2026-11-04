# prisma-arch-build

Script para compilar e instalar Prism Launcher Beta en Arch Linux (equivalente de `build.cmd` en Windows).

## Uso

```bash
export PRISM_ROOT="/mnt/g/Proyectos/Prisma launcher"   # opcional; por defecto esa ruta
export PRISM_MSA_CLIENT_ID=...                          # identificador propio, no se guarda aquí
bash build-tools/build.sh deps
bash build-tools/build.sh configure
bash build-tools/build.sh build
bash build-tools/build.sh install
```

Comandos: `deps`, `configure`, `build` (por defecto) e `install`.
Variables opcionales: `PREFIX`, `BUILD_DIR`, `JOBS`, `QT_PREFIX`.

El código fuente debe estar en `$PRISM_ROOT/source`.
