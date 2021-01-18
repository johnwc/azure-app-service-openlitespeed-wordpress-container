docker build . -t johnwcarew/azure-app-service-openlitespeed-wordpress:latest
docker build . --build-arg PHP_VERSION=lsphp74 -t johnwcarew/azure-app-service-openlitespeed-wordpress:1.6.18-lsphp74
docker build . --build-arg PHP_VERSION=lsphp73 -t johnwcarew/azure-app-service-openlitespeed-wordpress:1.6.18-lsphp73

rem docker build . --build-arg LS_VERSION=dev --build-arg PHP_VERSION=sync -t johnwcarew/azure-app-service-openlitespeed-wordpress:dev-sync
rem --rm
rem docker run -it --name dev-sync-wp -p "80:80" -p "22:2222" -p "7080:7080" --env-file .env -v "C:\home:/home" johnwcarew/azure-app-service-openlitespeed-wordpress:dev-sync