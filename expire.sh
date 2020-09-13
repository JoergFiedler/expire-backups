#!/bin/sh

set -ex

current_dir=`pwd`
keyfile="./${HOST}.key"

if [ -z "${HOST}" ]; then
  echo "HOST env var needs to be set"
  exit 1
fi

if [ ! -f "${keyfile}" ]; then
  echo "Key file ${keyfile} does not exist"
  exit 1
fi

chmod 600 ${keyfile}

echo "Expiring backups for: ${HOST}"
cache_dir="${current_dir}/${HOST}/cache"

echo "Copying tarsnap config …"
scp \
  -F ssh-config \
  -i travis.ssh-key \
  -rq ${HOST}:/usr/local/etc/tarsnapp\* \
  ${HOST}/
sed -i '' \
  "s|/usr/local/etc|${current_dir}/${HOST}|g" \
  ./${HOST}/tarsnapper.yml

echo "Running fsck …"
tarsnap \
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
rm -rf ${cache_dir}
