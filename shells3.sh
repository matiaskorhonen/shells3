#!/usr/bin/env bash

# Try to read the configuration from:
#   1. the working directory
#   2. The user's home directory
# (in that order)
config_file=".shells3.conf"
if [ -f "$(pwd)/$config_file" ]; then
  source "$(pwd)/$config_file"
elif [ -f "$HOME/$config_file" ]; then
  source "$HOME/$config_file"
fi

function show_help {
  echo -e "Usage: shells3 [OPTION]... [FILE]..."
  echo -e "Send FILEs to the configured S3 bucket\n"

  echo -e "\tOPTIONS:"
  echo -e "\t-p\tpath[default: '/'], where you want the file to be saved in the bucket."
  echo -e "\t-a\tacl[default: 'public-read'], ACL for all the files. CF: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl.\n"
  echo "More info: https://github.com/matiaskorhonen/shells3"
}

OPTIND=1         # Reset in case getopts has been used previously in the shell.
aws_path="/"
acl_string="public-read"

while getopts "h?a:p:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 1
        ;;
    a)  acl_string=$OPTARG
        ;;
    p)  aws_path=$OPTARG
        ;;

    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift
# SHELLS3_BUCKET=""
# SHELLS3_AWS_ACCESS_KEY_ID=""
# SHELLS3_AWS_SECRET_ACCESS_KEY=""
# SHELLS3_BASE_URL=""
SHELLS3_AWS_REGION=${SHELLS3_AWS_REGION:-"us-east-1"}

bucket=$SHELLS3_BUCKET
key=$SHELLS3_AWS_ACCESS_KEY_ID
secret=$SHELLS3_AWS_SECRET_ACCESS_KEY

endpoint=""
case "$SHELLS3_AWS_REGION" in
us-east-1) endpoint="s3.amazonaws.com"
;;
*)  endpoint="s3-$SHELLS3_AWS_REGION.amazonaws.com"
;;
esac

base_url=${SHELLS3_BASE_URL:-"https://$endpoint/$bucket"}

mimepattern="[0-9a-zA-Z-]/[0-9a-zA-Z-]"

function timestamp {
  date +"%s"
}

function putS3
{
  path=$1
  file=$(basename "$path")

  filename=$file
  extension="${filename#*.}"
  filename="${filename%%.*}"
  filename="$filename-$(timestamp).$extension"

  content_type=$(file --mime-type -b "${path}")
  if [[ ! "$content_type" =~ $mimepattern ]]
  then
    content_type="application/octet-stream"
  fi

  date=$(date +"%a, %d %b %Y %T %z")
  acl="x-amz-acl:$acl_string"
  cache_control="public, max-age=315360000"

  string="PUT\n\n$content_type\n$date\n$acl\n/$bucket$aws_path$filename"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${secret}" -binary | base64)

  curl -X PUT -T "$path" \
    -H "Host: $endpoint" \
    -H "Date: $date" \
    -H "Cache-Control: $cache_control" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${key}:$signature" \
    "https://$endpoint/$bucket$aws_path$filename"

  case "$?" in
    0) echo "$base_url$aws_path$filename"
    ;;
    *) echo "Uh oh. Something went terribly wrong"
    ;;
  esac
}

if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]] ; then
    show_help
    exit 1
fi

for file in "$@"
do
  putS3 "$file"
done
