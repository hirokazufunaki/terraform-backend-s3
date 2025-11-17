#!/usr/bin/env bash
# ============================================================
# tfstate 管理用の S3 バケットを作成
# ============================================================
set -euo pipefail

# 共通関数を読み込み
source ./common_functions.sh

# ヘルプメッセージを表示
show_help() {
  cat <<EOF
使い方:
  $ ./create_backend_s3.sh [オプション]

オプション:
  -e <ENV>               必須: 環境
  -a <APPLICATION_NAME>  必須: アプリケーション名
  -p <AWS_PROFILE>       必須: AWSプロファイル名
  -r <AWS_REGION>        必須: AWSリージョン名

実行例:
  $ ./create_backend_s3.sh -e test -a <アプリケーション名> -p <AWSプロファイル名> -r ap-northeast-1

説明:
  このスクリプトは tfstate 管理用の S3 バケットを作成し、.tfbackend ファイルと backend.tf ファイルを生成します。

EOF
}

# コマンドライン引数を変数に格納
while getopts "e:a:p:r:h" opt; do
  case "$opt" in
    e) readonly ENV="$OPTARG" ;;
    a) readonly APPLICATION_NAME="$OPTARG" ;;
    p) readonly AWS_PROFILE="$OPTARG" ;;
    r) readonly AWS_REGION="$OPTARG" ;;
    h) show_help; exit 0 ;;
    *) show_help; exit 1 ;;
  esac
done

# 都市コードの取得
readonly CITY_CODE=$(get_city_code "${AWS_REGION}")

# S3 バケット名の生成
readonly BUCKET_NAME="tfstate-${ENV}-${APPLICATION_NAME}-${CITY_CODE}"

# AWS アカウントのユーザーIDを取得
readonly AWS_USER_ID=$(aws sts get-caller-identity --profile "${AWS_PROFILE}" | jq ".UserId" | tr -d '"')

# 情報表示
echo "----------"
echo "Information"
echo "----------"
printf "%-25s %s\n" "ENV:" "${ENV:-<undefined>}"
printf "%-25s %s\n" "APPLICATION_NAME:" "${APPLICATION_NAME:-<undefined>}"
printf "%-25s %s\n" "AWS_PROFILE:" "${AWS_PROFILE:-<undefined>}"
printf "%-25s %s\n" "AWS_REGION:" "${AWS_REGION:-<undefined>}"
printf "%-25s %s\n" "CITY_CODE:" "${CITY_CODE:-<undefined>}"
printf "%-25s %s\n" "BUCKET_NAME:" "${BUCKET_NAME:-<undefined>}"
printf "%-25s %s\n" "AWS_USER_ID:" "${AWS_USER_ID:-<undefined>}"
echo "=========="

#msg "S3 バケットを作成しています。"
#aws s3 mb s3://"${BUCKET_NAME}" --profile "${AWS_PROFILE}" --region "${AWS_REGION}"
#
#msg "S3 バケットのバージョニングを設定しています。"
#aws s3api put-bucket-versioning --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
#  --bucket "${BUCKET_NAME}" \
#  --versioning-configuration Status=Enabled

msg "S3 バケットにタグを設定しています。"
aws s3api put-bucket-tagging --profile "${AWS_PROFILE}" \
  --bucket "${BUCKET_NAME}" \
  --tagging 'TagSet=[
    {Key=Env,Value='"$ENV"'},
    {Key=ApplicationName,Value='"$APPLICATION_NAME"'},
    {Key=Owner,Value='"$AWS_USER_ID"'}
  ]'

msg ".tfbackend ファイルを作成しています。"
tfbackend_file_name="${ENV}-${APPLICATION_NAME}.tfbackend"
cat <<EOS > "${tfbackend_file_name}"
profile      = "${AWS_PROFILE}"
region       = "${AWS_REGION}"
bucket       = "${BUCKET_NAME}"
key          = "xxxx.tfstate"
use_lockfile = true
encrypt      = true
EOS

msg "backend.tf ファイルを作成しています。"
cat <<EOS > backend.tf
terraform {
  backend "s3" {
    region       = "${AWS_REGION}"
    bucket       = "${BUCKET_NAME}"
    key          = "xxxx.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
EOS

echo "=== 終了しました。"
