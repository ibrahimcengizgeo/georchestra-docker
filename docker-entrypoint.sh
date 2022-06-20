#!/bin/bash

apt-get update
apt-get install libgdal-java -y
ln -s /usr/lib/jni/libgdalalljni.so.20 /usr/lib/libgdalalljni.so

echo "I am root" && id && whoami
su jetty
echo "whoami:" && id  &&  whoami

DIR=/docker-entrypoint.d

if [[ -d "$DIR" ]]
then
  /bin/run-parts --verbose "$DIR"
fi

exec "$@"
