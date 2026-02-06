#!/usr/bin/env bash
set -euo pipefail

AOFS_BASE="${AOFS_BASE:-http://127.0.0.1:2001}"
USER_ID="${USER_ID:-1}"

fail() {
  echo "[FAIL] $*"
  exit 1
}

json_code() {
  jq -r '.code // empty' <<<"$1"
}

wait_until() {
  local name="$1"
  local max_try="$2"
  local sleep_sec="$3"
  local check_cmd="$4"
  local i
  for ((i=1; i<=max_try; i++)); do
    if eval "$check_cmd"; then
      echo "[PASS] $name"
      return 0
    fi
    sleep "$sleep_sec"
  done
  fail "$name timeout"
}

api_get() {
  curl -sS "$1"
}

api_post() {
  local url="$1"
  local body="$2"
  curl -sS -X POST "$url" -H 'Content-Type: application/json' -d "$body"
}

echo "[INFO] write e2e base=$AOFS_BASE userId=$USER_ID"

run_id="$(date +%s)"
src_move_name="api-e2e-src-move-${run_id}"
src_copy_name="api-e2e-src-copy-${run_id}"
dst_name="api-e2e-dst-${run_id}"
renamed_name="api-e2e-src-move-renamed-${run_id}"

create_src_move_rsp="$(api_post "$AOFS_BASE/space/v1/api/folder/create?userId=$USER_ID" "{\"folderName\":\"$src_move_name\",\"currentDirUuid\":\"\"}")"
[[ "$(json_code "$create_src_move_rsp")" == "200" ]] || fail "create move-src folder failed: $create_src_move_rsp"
src_move_uuid="$(jq -r '.results.uuid // empty' <<<"$create_src_move_rsp")"
[[ -n "$src_move_uuid" ]] || fail "create move-src folder missing uuid"
echo "[PASS] create move-src folder uuid=$src_move_uuid"

create_src_copy_rsp="$(api_post "$AOFS_BASE/space/v1/api/folder/create?userId=$USER_ID" "{\"folderName\":\"$src_copy_name\",\"currentDirUuid\":\"\"}")"
[[ "$(json_code "$create_src_copy_rsp")" == "200" ]] || fail "create copy-src folder failed: $create_src_copy_rsp"
src_copy_uuid="$(jq -r '.results.uuid // empty' <<<"$create_src_copy_rsp")"
[[ -n "$src_copy_uuid" ]] || fail "create copy-src folder missing uuid"
echo "[PASS] create copy-src folder uuid=$src_copy_uuid"

create_dst_rsp="$(api_post "$AOFS_BASE/space/v1/api/folder/create?userId=$USER_ID" "{\"folderName\":\"$dst_name\",\"currentDirUuid\":\"\"}")"
[[ "$(json_code "$create_dst_rsp")" == "200" ]] || fail "create dst folder failed: $create_dst_rsp"
dst_uuid="$(jq -r '.results.uuid // empty' <<<"$create_dst_rsp")"
[[ -n "$dst_uuid" ]] || fail "create dst folder missing uuid"
echo "[PASS] create dst folder uuid=$dst_uuid"

rename_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/rename?userId=$USER_ID" "{\"uuid\":\"$src_move_uuid\",\"fileName\":\"$renamed_name\"}")"
[[ "$(json_code "$rename_rsp")" == "200" ]] || fail "rename folder failed: $rename_rsp"
echo "[PASS] rename move-src folder"

move_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/move?userId=$USER_ID" "{\"uuids\":[\"$src_move_uuid\"],\"destPath\":\"$dst_uuid\"}")"
[[ "$(json_code "$move_rsp")" == "200" ]] || fail "move folder failed: $move_rsp"
echo "[PASS] move folder move-src->dst"

wait_until "verify moved folder under dst" 10 1 "[[ \"\$(api_get '$AOFS_BASE/space/v1/api/file/list?userId=$USER_ID&uuid=$dst_uuid' | jq -r '.results.fileList[]? | select(.uuid==\"$src_move_uuid\") | .uuid')\" == '$src_move_uuid' ]]"

copy_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/copy?userId=$USER_ID" "{\"uuids\":[\"$src_copy_uuid\"],\"dstPath\":\"$dst_uuid\"}")"
[[ "$(json_code "$copy_rsp")" == "200" ]] || fail "copy folder failed: $copy_rsp"
copy_new_uuid="$(jq -r '.results.data[0].newId // .results.Data[0].newId // empty' <<<"$copy_rsp")"
[[ -n "$copy_new_uuid" ]] || fail "copy response missing newId: $copy_rsp"
echo "[PASS] copy folder copy-src->dst newUuid=$copy_new_uuid"

wait_until "verify copied folder under dst" 10 1 "[[ \"\$(api_get '$AOFS_BASE/space/v1/api/file/list?userId=$USER_ID&uuid=$dst_uuid' | jq -r '.results.fileList[]? | select(.uuid==\"$copy_new_uuid\") | .uuid')\" == '$copy_new_uuid' ]]"

delete_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/delete?userId=$USER_ID" "{\"uuids\":[\"$src_move_uuid\"]}")"
[[ "$(json_code "$delete_rsp")" == "200" ]] || fail "delete moved folder failed: $delete_rsp"
echo "[PASS] delete moved folder"

wait_until "verify folder in recycled" 10 1 "[[ \"\$(api_get '$AOFS_BASE/space/v1/api/recycled/list?userId=$USER_ID' | jq -r '.results.fileList[]? | select(.uuid==\"$src_move_uuid\") | .uuid')\" == '$src_move_uuid' ]]"

restore_rsp="$(api_post "$AOFS_BASE/space/v1/api/recycled/restore?userId=$USER_ID" "{\"uuids\":[\"$src_move_uuid\"]}")"
[[ "$(json_code "$restore_rsp")" == "200" ]] || fail "restore folder failed: $restore_rsp"
echo "[PASS] restore folder"

wait_until "verify restored folder under dst" 10 1 "[[ \"\$(api_get '$AOFS_BASE/space/v1/api/file/list?userId=$USER_ID&uuid=$dst_uuid' | jq -r '.results.fileList[]? | select(.uuid==\"$src_move_uuid\" and .trashed==0) | .uuid')\" == '$src_move_uuid' ]]"

# delete again and clear permanently
post_delete_again_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/delete?userId=$USER_ID" "{\"uuids\":[\"$src_move_uuid\"]}")"
[[ "$(json_code "$post_delete_again_rsp")" == "200" ]] || fail "delete again failed: $post_delete_again_rsp"
wait_until "verify folder in recycled (again)" 10 1 "[[ \"\$(api_get '$AOFS_BASE/space/v1/api/recycled/list?userId=$USER_ID' | jq -r '.results.fileList[]? | select(.uuid==\"$src_move_uuid\") | .uuid')\" == '$src_move_uuid' ]]"

clear_rsp="$(api_post "$AOFS_BASE/space/v1/api/recycled/clear?userId=$USER_ID" "{\"uuids\":[\"$src_move_uuid\"]}")"
[[ "$(json_code "$clear_rsp")" == "200" ]] || fail "clear recycled failed: $clear_rsp"
wait_until "verify folder removed from recycled" 10 1 "[[ -z \"\$(api_get '$AOFS_BASE/space/v1/api/recycled/list?userId=$USER_ID' | jq -r '.results.fileList[]? | select(.uuid==\"$src_move_uuid\") | .uuid')\" ]]"

# cleanup dst tree (contains copied folder)
delete_dst_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/delete?userId=$USER_ID" "{\"uuids\":[\"$dst_uuid\"]}")"
if [[ "$(json_code "$delete_dst_rsp")" == "200" ]]; then
  sleep 1
  api_post "$AOFS_BASE/space/v1/api/recycled/clear?userId=$USER_ID" "{\"uuids\":[\"$dst_uuid\"]}" >/dev/null || true
fi

# cleanup copy-src in root
delete_src_copy_rsp="$(api_post "$AOFS_BASE/space/v1/api/file/delete?userId=$USER_ID" "{\"uuids\":[\"$src_copy_uuid\"]}")"
if [[ "$(json_code "$delete_src_copy_rsp")" == "200" ]]; then
  sleep 1
  api_post "$AOFS_BASE/space/v1/api/recycled/clear?userId=$USER_ID" "{\"uuids\":[\"$src_copy_uuid\"]}" >/dev/null || true
fi

echo "[DONE] write e2e passed"
