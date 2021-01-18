# WordPress on Azure App Service for Containers using OpenLiteSpeed
[![docker pulls](https://img.shields.io/docker/pulls/johnwcarew/azure-app-service-openlitespeed-wordpress?style=flat&color=blue)](https://hub.docker.com/r/johnwcarew/azure-app-service-openlitespeed-wordpress)

This repository contains Docker images for WordPress running on Azure App Service Linux container using OpenLiteSpeed web server.

## Image Repository
https://hub.docker.com/r/johnwcarew/azure-app-service-openlitespeed-wordpress

## Known issues
None.

## Build Components

| Component     | Version      |
| ------------- | ------------ |
| Linux         | [Ubuntu](https://ubuntu.com/) 18.04 |
| [OpenLiteSpeed](https://openlitespeed.org/) | 1.6.18       |
| [PHP](https://www.php.net/)           | 7.4          |
| [WordPress](https://wordpress.org/)     | 5.6          |
| [LiteSpeed Cache](https://wordpress.org/plugins/litespeed-cache/) | latest-stable |
| [Google XML Sitemaps](https://wordpress.org/plugins/google-sitemap-generator/) | latest-stable |

* SSH has been enabled on port 2222 to be able to SSH to the container in Azure App Service.
* WP-Cron is setup to run via task/cron scheduler every 10 minutes. Set `PHP_CRON` environment variable to a valid [cron formated](https://en.wikipedia.org/wiki/Cron) schedule to change from the default execute interval. Be sure to apply the `define('DISABLE_WP_CRON', true);` setting in wp-config.php, so that WP-Cron does not slowdown your page loads. The last WP-Cron task run is logged to `/home/site/cron.log` 
  * Run `setup-wp-cron` from SSH shell to copy `cron.sh` to `/home/site` directory, if it does not exist already.

## Container storage for site

With the update to v1.2 of this container, the web server now serves the site from a local copy of the site that is synchronized from the durable storage. The container runs a synchronization service that will synchronize the `/home/site/` with `/var/www/vhosts/site-local/` bidirectionally. It monitors the `/home/site` directory for changes, if it detects changes it runs the synchronization. If it does not detect any changes, it will run a synchronization every two hours.

### Commands

These are supported commands that you can manually execute from the Azure App Service's SSH shell.

* `sync-now` - Start a synchronization task immediately.
* `clean-sync` - Initiates a fresh clean copy from durable to local
  * Clears out local site's wwwroot directory 
  * Clears folder's synchronization state
  * Copies sync maintenance template to local site
  * Copies site content from `/home/site/wwwroot` to `/var/www/vhosts/site-local/wwwroot`

### Maintenance template

When a fresh container is deployed or a container is regenerated from an updated docker image, the initial local site's wwwroot directory is empty. To minimize showing a *404* or *500* error while the site copies from durable to local storage, a `sync_maintenance.html` template file is copied to the root of the local site. If this file and the maintenance `.htaccess` exists, it will always be displayed to any browser accessing the site.

#### Custom maintenance template

You can place a `sync_maintenance.html` file with your own custom HTML within the `/home/site` directory in the durable storage. This would be the `/site` directory if uploading from FTP.

## Deployment

### Database

1. Create a managed [Azure Database for MySQL](https://azure.microsoft.com/en-us/services/mysql/).
   * [Quickstart: Create an Azure Database for MySQL server by using the Azure portal](https://docs.microsoft.com/en-us/azure/mysql/quickstart-create-mysql-server-database-using-azure-portal)
2. Follow WordPress's [quick install guide](https://wordpress.org/support/article/how-to-install-wordpress/#step-2-create-the-database-and-a-user) to setup the DB & user.

### ARM Template
A sample Azure arm template is available in the [github repo](https://github.com/johnwc/azure-app-service-openlitespeed-wordpress-container/blob/master/infra.arm.json). 

* The app plan must be an Azure App Service Linux plan.
* Use the MySQL server's FQDN, database name, and user created in the Database section to fill in the following parameters in the ARM template.
  * wordpressDbHost
  * wordpressDbName
  * wordpressDbUser
  * wordpressDbPassword
* After deployment, be sure to configure the [LiteSpeed Cache](https://wordpress.org/plugins/litespeed-cache/) plug-in in WordPress for best performance.
* Activate the [Google XML Sitemaps](https://wordpress.org/plugins/google-sitemap-generator/) plug-in, and use it as sitemap url in LiteSpeed Cache's crawler options.