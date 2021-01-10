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
| [LiteSpeed Cache](https://wordpress.org/plugins/litespeed-cache/) | 3.6.1      |

SSH has been enabled on port 2222 to be able to SSH to the container in Azure App Service.

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