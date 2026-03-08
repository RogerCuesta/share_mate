#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SQL_AUDIT_FILE="${SCRIPT_DIR}/rls_policy_audit.sql"
PHASE1_MIGRATION="${REPO_ROOT}/supabase/migrations/20260308_phase1_rls_hardening.sql"
PAYMENT_MIGRATION="${REPO_ROOT}/supabase/migrations/20251225_payment_history_enhancements.sql"

MODE="auto"
if [[ "${1:-}" == "--mode=static" ]]; then
  MODE="static"
elif [[ "${1:-}" == "--mode=db" ]]; then
  MODE="db"
fi

FAILURES=0

pass() {
  echo "✅ [SECU-03] $1"
}

fail() {
  echo "❌ [SECU-03] $1"
  FAILURES=$((FAILURES + 1))
}

assert_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"

  if rg -Fq "${needle}" "${file}"; then
    pass "${label}"
  else
    fail "${label} (missing: ${needle})"
  fi
}

echo "== SECU-03 static policy audit =="

for table in subscriptions subscription_members payment_history contacts; do
  assert_contains \
    "${PHASE1_MIGRATION}" \
    "ALTER TABLE IF EXISTS public.${table} ENABLE ROW LEVEL SECURITY;" \
    "RLS enabled for ${table} in migration source"
done

for policy in \
  p1_subscriptions_select_own \
  p1_subscriptions_insert_own \
  p1_subscriptions_update_own \
  p1_subscriptions_delete_own \
  p1_subscription_members_select_owner_scope \
  p1_subscription_members_insert_owner_scope \
  p1_subscription_members_update_owner_scope \
  p1_subscription_members_delete_owner_scope \
  p1_payment_history_select_owner_scope \
  p1_payment_history_insert_owner_scope \
  p1_payment_history_update_owner_scope \
  p1_payment_history_delete_owner_scope \
  p1_contacts_select_own \
  p1_contacts_insert_own \
  p1_contacts_update_own \
  p1_contacts_delete_own; do
  assert_contains "${PHASE1_MIGRATION}" "CREATE POLICY \"${policy}\"" "Canonical policy ${policy} declared"
done

for file in "${PAYMENT_MIGRATION}" "${PHASE1_MIGRATION}"; do
  assert_contains "${file}" "CREATE OR REPLACE FUNCTION mark_payment_as_paid_atomic(" "mark_payment_as_paid_atomic present in $(basename "${file}")"
  assert_contains "${file}" "CREATE OR REPLACE FUNCTION unmark_payment_atomic(" "unmark_payment_atomic present in $(basename "${file}")"
  assert_contains "${file}" "CREATE OR REPLACE FUNCTION get_payment_history_stats(" "get_payment_history_stats present in $(basename "${file}")"
  assert_contains "${file}" "SECURITY DEFINER" "SECURITY DEFINER present in $(basename "${file}")"
  assert_contains "${file}" "SET search_path = public, auth" "Deterministic search_path present in $(basename "${file}")"
  assert_contains "${file}" "auth.uid()" "auth.uid guard present in $(basename "${file}")"
done

if [[ ${FAILURES} -gt 0 ]]; then
  echo "SECU-03 audit failed in static mode with ${FAILURES} issue(s)."
  exit 1
fi

echo "✅ SECU-03 static audit passed."

if [[ "${MODE}" == "static" ]]; then
  echo "SECU-03 audit passed."
  exit 0
fi

DB_URL="${SUPABASE_DB_URL:-${DATABASE_URL:-}}"
HAS_PSQL="false"
if command -v psql >/dev/null 2>&1; then
  HAS_PSQL="true"
fi

if [[ "${MODE}" == "db" ]]; then
  if [[ -z "${DB_URL}" ]]; then
    echo "❌ [SECU-03] DB mode requested but SUPABASE_DB_URL/DATABASE_URL is not set."
    exit 1
  fi
  if [[ "${HAS_PSQL}" != "true" ]]; then
    echo "❌ [SECU-03] DB mode requested but psql is not installed."
    exit 1
  fi
fi

if [[ -n "${DB_URL}" && "${HAS_PSQL}" == "true" ]]; then
  echo "== SECU-03 database audit =="
  psql "${DB_URL}" -v ON_ERROR_STOP=1 -f "${SQL_AUDIT_FILE}"
  echo "✅ SECU-03 database audit passed."
else
  echo "ℹ️  Skipping database audit (set SUPABASE_DB_URL and install psql to enable runtime checks)."
fi

echo "SECU-03 audit passed."
