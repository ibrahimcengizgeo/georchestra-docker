# geOrchestra on Docker

## Quick Start

Grab a machine with a decent amount of RAM (at least 8Gb, better with 12 or 16Gb).

Install a recent [docker](https://docs.docker.com/engine/installation/) & [docker-compose](https://docs.docker.com/compose/install/) version (not from your distro, these packages are probably too old).

Clone this repo and its submodule using:
```
git clone https://github.com/georchestra/docker.git
cd docker && git submodule update --init --remote
```

Edit your `/etc/hosts` file with the following:
```
127.0.1.1	georchestra.mydomain.org
```

Choose which branch to run, eg for latest stable:
```
git checkout 20.0 && git submodule update
```

Run geOrchestra with
```
docker-compose up
```

Open [https://georchestra.mydomain.org/](https://georchestra.mydomain.org/) in your browser.

To login, use these credentials:
 * `testuser` / `testuser`
 * `testadmin` / `testadmin`

To upload data into the GeoServer data volume (`geoserver_geodata`), use rsync:
```
rsync -arv -e 'ssh -p 2222' /path/to/geodata/ geoserver@georchestra.mydomain.org:/mnt/geoserver_geodata/
```
(password is: `geoserver`)

Files uploaded into this volume will also be available to the geoserver instance in `/mnt/geoserver_geodata/`.

Emails sent by the SDI (eg when users request a new password) will not be relayed on the internet but trapped by a local SMTP service.  
These emails can be read on https://georchestra.mydomain.org/webmail/ (with login `smtp` and password `smtp`).

Stop geOrchestra with
```
docker-compose down
```

## SSL/TLS

This repo comes with a self signed cert which is _not_ valid. To test with a valid cert you can
install [mkcert](https://github.com/FiloSottile/mkcert) on your host and do the following:

* `mkcert -install`. Only do this once ! It'll install a fake root cert in system store (and some
  others see mkcert doc)
* `cd resources/ssl && mkcert georchestra.mydomain.org`
* `mv georchestra.mydomain.org.pem georchestra.mydomain.org.crt`
* `mv georchestra.mydomain.org-key.pem georchestra.mydomain.org.key`
* `docker-compose restart georchestra.mydomain.org`

## Geofence

If you want to run the Geofence enabled GeoServer, make sure the correct docker image is being used in `docker-compose.yml`:

```
image: georchestra/geoserver:20.0.x-geofence
```
(replace `20.0.x-geofence` by the appropriate version - use `latest-geofence` on master).

And change the `JAVA_OPTIONS` in the geoserver `environment` properties to indicate where the Geofence databaser configuration .properties file is:

```
    environment:
      - JAVA_OPTIONS=-Dgeofence-ovr=file:/etc/georchestra/geoserver/geofence/geofence-datasource-ovr.properties
```


Then, edit the file `config/geoserver/geofence/geofence-datasource-ovr.properties`, and change the line

```
#geofenceEntityManagerFactory.jpaPropertyMap[hibernate.hbm2ddl.auto]=validate
```
to 
```
geofenceEntityManagerFactory.jpaPropertyMap[hibernate.hbm2ddl.auto]=update
```

Finally, due to [this defect](https://github.com/georchestra/georchestra/issues/2620) , once you executed `docker-compose up` and the database is up and running, execute:

```
docker-compose exec database psql -U georchestra -c "create sequence if not exists hibernate_sequence;"
```


## Notes

These docker-compose files describe:
 * which images / webapps will run,
 * how they are linked together,
 * where the configuration and data volumes are

The `docker-compose.override.yml` file adds services to interact with your geOrchestra instance (they are not part of geOrchestra "core"):
 * reverse proxy / load balancer
 * ssh / rsync services,
 * smtp, webmail.

Feel free to comment out the apps you do not need.

The base docker composition does not include any standalone geowebcache instance, nor the atlas module.
If you need them, you have to include the corresponding complementary docker-compose file at run-time:
```
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.gwc.yml -f docker-compose.atlas.yml up
```

## Upgrading

Images and configuration are updated regularly.

To upgrade, we recommend you to:
 * update the configuration with `git submodule update --remote`
 * update the software with `docker-compose pull`


## Customising

Adjust the configuration in the `config` folder according to your needs.
Reading the [quick configuration guide](https://github.com/georchestra/datadir/blob/docker-master/README.md) might help !

Most changes will require a service restart, except maybe updating viewer contexts & addons (`F5` will do).

### How to install extension for GeoServer
#### ex: gDAL extention

In order to add the gdal extensions, the following volume is mounted

       - ./geoserver-webapp/WEB-INF/lib:/var/lib/jetty/webapps/geoserver/WEB-INF/lib
       
Afterthat, instead of throwing the relevant jars into the container, we follow below path:

1.Put the jars into `/home/geosolutions/docker/geoserver-webapp/WEB-INF/lib` folder on VM

2.Recreate|Restart the docker `docker-compose -f docker-compose.yml up -d geoserver `

3.Installed them successfully.       
       
To install libgdal-java and create a symbolic link, the entrypoint script was updated and mounted.

       - ./docker-entrypoint.sh:/docker-entrypoint.sh
   > apt-get update &&
apt-get install libgdal-java &&
ln -s /usr/lib/jni/libgdalalljni.so.20 /usr/lib/libgdalalljni.so    
       

## Building

Images used in the current composition are pulled from docker hub, which means they've been compiled by our CI.
In case you have to build these images by yourself (for instance, to rely on stable branches), please refer to the [docker images build instructions](https://github.com/georchestra/georchestra/blob/master/docker/README.md).
