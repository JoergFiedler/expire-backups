#!/bin/sh

current_dir=`pwd`
keyfile="./${HOST}.key"

if [ -z "${HOST}" ]; then
  echo "HOST env var needs to be set"
  exit 1
fi

if [ ! -f "${keyfile}.enc" ]; then
  echo "Encrypted key file ${keyfile} does not exist"
  exit 1
fi

echo "Expiring backups for: ${HOST}"
cache_dir="${current_dir}/${HOST}/cache"

echo "Decrypting key …"
openssl aes-256-cbc \
  -K $encrypted_0a6446eb3ae3_key \
  -iv $encrypted_0a6446eb3ae3_iv \
  -in ${keyfile}.enc \
  -out ${keyfile} \
  -d

echo "Copying tarsnap config …"
scp -rq ${HOST}:/usr/local/etc/tarsnapp\* ${HOST}/
sed -i '' \
  "s|/usr/local/etc|${current_dir}/${HOST}|g" \
  ./${HOST}/tarsnapper.yml

echo "Running fsck …"
/usr/local/bin/tarsnap \
  --fsck \
  --keyfile ${keyfile} \
  --cachedir ${cache_dir}

echo "Expiring backups …"
tarsnapper \
  -o keyfile=${keyfile} \
  -o cachedir=${cache_dir} \
  --config ${HOST}/tarsnapper.yml \
  expire

echo "Deleting temporary data …"
rm -rf ${keyfile}
rm -rf ${cache_dir}
