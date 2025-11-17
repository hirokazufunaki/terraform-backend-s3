#!/usr/bin/env bash
# ============================================================
# 共通関数
# ============================================================

# メッセージ出力
msg() {
  echo
  echo "$1"
  echo
}

# リージョンから都市コードを取得
get_city_code() {
  local aws_region="$1"

  case "$aws_region" in
    ap-northeast-1) # 東京リージョン
      echo "tyo"
      ;;
    ap-northeast-3) # 大阪リージョン
      echo "osa"
      ;;
    *)
      echo "エラー: リージョンは ap-northeast-1 または ap-northeast-3 のみ指定可能です。"
      exit 1
      ;;
  esac
}
