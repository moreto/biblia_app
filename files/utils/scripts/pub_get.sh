#!/bin/bash

#   Script
#   Executa flutter pub get em todos os modulos do projeto.
#   O flutter clean é opcional e roda antes do pub get quando informado.
#
#   Uso:
#     ./utils/scripts/pub_get.sh           -> apenas pub get
#     ./utils/scripts/pub_get.sh --clean   -> flutter clean + pub get (atalho: -c)

set -e

MODULES=(service components commons app)

CLEAN=false
for arg in "$@"; do
  case $arg in
    -c|--clean) CLEAN=true ;;
    -h|--help)
      echo "Uso: $0 [-c|--clean]"
      exit 0
      ;;
    *)
      echo "Argumento inválido: $arg"
      echo "Uso: $0 [-c|--clean]"
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for module in "${MODULES[@]}"; do
  echo " "
  echo "=> $module"
  cd "$ROOT_DIR/$module"

  if [ "$CLEAN" = true ]; then
    flutter clean
  fi

  flutter pub get
done

echo " "
echo "=> Execução finalizada..."
