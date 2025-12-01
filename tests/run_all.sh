#!/bin/bash
#
# PudimWeb Test Runner
# ====================
#
# Executa todos os testes do PudimWeb.
#
# Uso: ./tests/run_all.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Configura o LUA_PATH para encontrar os módulos do projeto
export LUA_PATH="./?.lua;./?/init.lua;${LUA_PATH:-}"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║               🍮 PudimWeb - Test Runner                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0

run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .lua)"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Executando: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if lua "$test_file"; then
        echo "✓ $test_name passou!"
    else
        echo "✗ $test_name falhou!"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
}

# Executar todos os testes
for test_file in "$SCRIPT_DIR"/*_test.lua; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
    fi
done

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                     Resumo Final                          ║"
echo "╠═══════════════════════════════════════════════════════════╣"

if [ $TOTAL_FAILED -eq 0 ]; then
    echo "║  ✓ Todos os testes passaram!                              ║"
else
    echo "║  ✗ $TOTAL_FAILED arquivo(s) de teste falharam             ║"
fi

echo "╚═══════════════════════════════════════════════════════════╝"

exit $TOTAL_FAILED
