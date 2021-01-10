docker build . -t johnwcarew/azure-app-service-openlitespeed-wordpress:latest
docker build . --build-arg PHP_VERSION=lsphp74 -t johnwcarew/azure-app-service-openlitespeed-wordpress:1.6.18-lsphp74
docker build . --build-arg PHP_VERSION=lsphp73 -t johnwcarew/azure-app-service-openlitespeed-wordpress:1.6.18-lsphp73