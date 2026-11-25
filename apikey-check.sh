#!/bin/sh
# apikey-check.sh -- taruh di repo (rayzxova/rayz), jalankan PALING AWAL sebelum sshd/layanan lain nyala.
#
# Cara pasang:
#   1. Dockerfile:      COPY apikey-check.sh /apikey-check.sh
#   2. Skrip start/entrypoint, baris paling atas:   sh /apikey-check.sh || exit 1
#
# Bot ngisi dua variabel Railway tiap VPS baru: RAYZ_APIKEY (kunci acak) dan RAYZ_CHECK (alamat cek di Firebase).
# Yang dicek ke Firebase cuma HASH sha256 dari kunci, bukan kuncinya.
# Nggak ada kunci / hash nggak terdaftar / dicabut -> container berhenti. Orang yang deploy repo ini langsung dari GitHub
# nggak punya kunci yang terdaftar di bot kamu, jadi nggak bisa dipakai.

INTERVAL="${RAYZ_CHECK_EVERY:-300}"   # detik, cek ulang berkala

need_tool() {
  command -v curl >/dev/null 2>&1 && return 0
  command -v wget >/dev/null 2>&1 && return 0
  (apt-get update -qq && apt-get install -y -qq curl ca-certificates) >/dev/null 2>&1
  command -v curl >/dev/null 2>&1
}

fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fsS -m 15 "$1" 2>/dev/null
  else wget -q -T 15 -O - "$1" 2>/dev/null; fi
}

# return: 0 = kunci sah, 1 = kunci nggak ada/nggak terdaftar/dicabut, 2 = gagal nyambung (bukan salah kunci)
check() {
  [ -n "$RAYZ_APIKEY" ] && [ -n "$RAYZ_CHECK" ] || return 1
  H=$(printf %s "$RAYZ_APIKEY" | sha256sum | cut -d' ' -f1)
  R=$(fetch "$RAYZ_CHECK/$H.json") || return 2
  case "$R" in
    *'"on":true'*) return 0 ;;
    *) return 1 ;;
  esac
}

need_tool || { echo "[apikey] curl/wget nggak tersedia"; exit 1; }

# saat nyala: coba sampai 4x kalau jaringan lagi bermasalah
n=0
while :; do
  check; rc=$?
  [ "$rc" -eq 0 ] && break
  [ "$rc" -eq 1 ] && { echo "[apikey] kunci nggak valid / belum terdaftar / dicabut. Container berhenti."; exit 1; }
  n=$((n+1)); [ "$n" -ge 4 ] && { echo "[apikey] server cek nggak bisa dihubungi. Container berhenti."; exit 1; }
  sleep 5
done
echo "[apikey] kunci sah"

# cek ulang berkala di latar belakang; kalau kunci dicabut, matikan container (PID 1)
(
  while :; do
    sleep "$INTERVAL"
    check; rc=$?
    [ "$rc" -eq 1 ] && { echo "[apikey] kunci dicabut, container dimatikan"; kill -TERM 1; exit 0; }
  done
) &
exit 0
