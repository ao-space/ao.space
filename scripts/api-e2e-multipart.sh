#!/usr/bin/env bash
set -euo pipefail

AOFS_BASE="${AOFS_BASE:-http://127.0.0.1:2001}"
USER_ID="${USER_ID:-1}"
PART_SIZE=$((4*1024*1024))
FILE_SIZE=$((8*1024*1024))

fail() {
  echo "[FAIL] $*"
  exit 1
}

md5_hex_file() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$1"
  else
    md5sum "$1" | awk '{print $1}'
  fi
}

md5_hex_stdin() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q
  else
    md5sum | awk '{print $1}'
  fi
}

size_flag() {
  local size="$1"
  local n=0
  while (( size / 2 >= 1 )); do
    n=$((n+1))
    size=$((size/2))
  done
  echo "$n"
}

api_get() {
  curl -sS "$1"
}

api_post_json() {
  local url="$1"
  local body="$2"
  curl -sS -X POST "$url" -H 'Content-Type: application/json' -d "$body"
}

api_post_bin() {
  local url="$1"
  local file="$2"
  curl -sS -X POST "$url" --data-binary "@$file"
}

json_code() {
  jq -r '.code // empty' <<<"$1"
}

echo "[INFO] multipart e2e base=$AOFS_BASE userId=$USER_ID"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

src_file="$workdir/src.bin"
part1="$workdir/part1.bin"
part2="$workdir/part2.bin"
download_file="$workdir/download.bin"

dd if=/dev/urandom of="$src_file" bs=1 count="$FILE_SIZE" 2>/dev/null

dd if="$src_file" of="$part1" bs=1 count="$PART_SIZE" 2>/dev/null
dd if="$src_file" of="$part2" bs=1 skip="$PART_SIZE" count="$PART_SIZE" 2>/dev/null

md5_part1="$(md5_hex_file "$part1")"
md5_part2="$(md5_hex_file "$part2")"
sha_all="$(printf '%s%s' "$md5_part1" "$md5_part2" | xxd -r -p | md5_hex_stdin)"
flag_hex="$(printf '%02x' "$(size_flag "$FILE_SIZE")")"
betag="${flag_hex}${sha_all}"

file_name="api-e2e-multipart-$(date +%s).bin"
create_body="{\"fileName\":\"$file_name\",\"size\":$FILE_SIZE,\"folderPath\":\"/\",\"betag\":\"$betag\",\"mime\":\"application/octet-stream\"}"

create_rsp="$(api_post_json "$AOFS_BASE/space/v1/api/multipart/create?userId=$USER_ID" "$create_body")"
[[ "$(json_code "$create_rsp")" == "200" ]] || fail "create multipart task failed: $create_rsp"
upload_id="$(jq -r '.results.succInfo.uploadId // empty' <<<"$create_rsp")"
[[ -n "$upload_id" ]] || fail "missing uploadId in create response"
echo "[PASS] multipart create uploadId=$upload_id"

# out-of-order upload: upload part2 first, then part1
u2_rsp="$(api_post_bin "$AOFS_BASE/space/v1/api/multipart/upload?userId=$USER_ID&uploadId=$upload_id&start=$PART_SIZE&end=$FILE_SIZE&md5sum=$md5_part2" "$part2")"
[[ "$(json_code "$u2_rsp")" == "200" ]] || fail "upload part2 failed: $u2_rsp"

u1_rsp="$(api_post_bin "$AOFS_BASE/space/v1/api/multipart/upload?userId=$USER_ID&uploadId=$upload_id&start=0&end=$PART_SIZE&md5sum=$md5_part1" "$part1")"
[[ "$(json_code "$u1_rsp")" == "200" ]] || fail "upload part1 failed: $u1_rsp"

echo "[PASS] multipart out-of-order upload"

# duplicate part upload should be rejected
udup_rsp="$(api_post_bin "$AOFS_BASE/space/v1/api/multipart/upload?userId=$USER_ID&uploadId=$upload_id&start=0&end=$PART_SIZE&md5sum=$md5_part1" "$part1")"
[[ "$(json_code "$udup_rsp")" == "1037" ]] || fail "duplicate part upload expected code=1037, got: $udup_rsp"
echo "[PASS] multipart duplicate part rejected code=1037"

list_rsp="$(api_get "$AOFS_BASE/space/v1/api/multipart/list?userId=$USER_ID&uploadId=$upload_id")"
[[ "$(json_code "$list_rsp")" == "200" ]] || fail "multipart list failed: $list_rsp"
echo "[PASS] multipart list"

complete_rsp="$(api_post_json "$AOFS_BASE/space/v1/api/multipart/complete?userId=$USER_ID" "{\"uploadId\":\"$upload_id\"}")"
[[ "$(json_code "$complete_rsp")" == "200" ]] || fail "multipart complete failed: $complete_rsp"
file_uuid="$(jq -r '.results.uuid // empty' <<<"$complete_rsp")"
[[ -n "$file_uuid" ]] || fail "missing file uuid after complete"
echo "[PASS] multipart complete fileUuid=$file_uuid"

curl -sS "$AOFS_BASE/space/v1/api/file/download?userId=$USER_ID&uuid=$file_uuid" -o "$download_file"
orig_md5="$(md5_hex_file "$src_file")"
dl_md5="$(md5_hex_file "$download_file")"
[[ "$orig_md5" == "$dl_md5" ]] || fail "download hash mismatch: orig=$orig_md5 dl=$dl_md5"
echo "[PASS] download hash match"

# validate multipart delete endpoint on a fresh task
file_name2="api-e2e-multipart-delete-$(date +%s)-$RANDOM.bin"
small_file="$workdir/small.bin"
dd if=/dev/urandom of="$small_file" bs=1 count=1024 2>/dev/null
small_md5="$(md5_hex_file "$small_file")"
small_flag_hex="$(printf '%02x' "$(size_flag 1024)")"
small_betag="${small_flag_hex}${small_md5}"
create_body2="{\"fileName\":\"$file_name2\",\"size\":1024,\"folderPath\":\"/\",\"betag\":\"$small_betag\",\"mime\":\"application/octet-stream\"}"
create2_rsp="$(api_post_json "$AOFS_BASE/space/v1/api/multipart/create?userId=$USER_ID" "$create_body2")"
[[ "$(json_code "$create2_rsp")" == "200" ]] || fail "create second multipart task failed: $create2_rsp"
upload_id2="$(jq -r '.results.succInfo.uploadId // .results.conflictInfo.uploadId // empty' <<<"$create2_rsp")"
[[ -n "$upload_id2" ]] || fail "missing second uploadId"

del_task_rsp="$(api_post_json "$AOFS_BASE/space/v1/api/multipart/delete?userId=$USER_ID" "{\"uploadId\":\"$upload_id2\"}")"
[[ "$(json_code "$del_task_rsp")" == "200" ]] || fail "multipart delete failed: $del_task_rsp"
echo "[PASS] multipart delete"

# cleanup uploaded file
cleanup_del_rsp="$(api_post_json "$AOFS_BASE/space/v1/api/file/delete?userId=$USER_ID" "{\"uuids\":[\"$file_uuid\"]}")"
if [[ "$(json_code "$cleanup_del_rsp")" == "200" ]]; then
  sleep 1
  api_post_json "$AOFS_BASE/space/v1/api/recycled/clear?userId=$USER_ID" "{\"uuids\":[\"$file_uuid\"]}" >/dev/null || true
fi

echo "[DONE] multipart e2e passed"
