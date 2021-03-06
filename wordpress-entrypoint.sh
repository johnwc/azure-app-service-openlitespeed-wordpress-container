#!/bin/bash
cat >/etc/motd <<EOL 
   _____                               
  /  _  \ __________ _________   ____  
 /  /_\  \\___   /  |  \_  __ \_/ __ \ 
/    |    \/    /|  |  /|  | \/\  ___/ 
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/ 
A P P   S E R V I C E   O N   L I N U X
Documentation: http://aka.ms/webapp-linux
WordPress support: https://wordpress.org/support/
WP Container Version : `cat /etc/wp-container-version`
PHP Container Version : `cat /etc/php-container-version`
PHP version : `php -v | head -n 1 | cut -d ' ' -f 2`
#################################################

EOL
cat /etc/motd

echo >&2 "Initializing PHP environment..."
init-php-env
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

user="1000"
group="1000"

if ! [ -e index.php -a -e wp-includes/version.php ]; then
	echo >&2 "WordPress not found in $PWD - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 3 )
	fi
	tar --create \
		--file - \
		--one-file-system \
		--directory /usr/src/wordpress \
		--owner "$user" --group "$group" \
		. | tar --extract --file -
	echo >&2 "Copied cron.sh to the parent directory of $PWD"
	cp /usr/src/php/cron.sh ../
	echo >&2 "Complete! WordPress has been successfully copied to $PWD"
fi


# Install BaltimoreCyberTrustRoot.crt.pem
if [ ! -e BaltimoreCyberTrustRoot.crt.pem ]; then
	echo "Downloading BaltimoreCyberTrustroot.crt.pem"
	curl -o BaltimoreCyberTrustRoot.crt.pem -fsL "https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem"
fi

# Install Redis Cache WordPress Plugin
if [ ! -e wp-content/plugins/redis-cache ]; then
	echo "Downloading https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip"
	curl -o redis-cache.zip -fsL "https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip"

	echo "Unzipping redis-cache.zip to wp-content/plugins/"
	unzip -q redis-cache.zip -d ./wp-content/plugins/

	echo "Removing redis-cache.zip"
	rm redis-cache.zip
		
	echo "Changing owner of all files in redis-cache plugin"
	chown -R "$user:$group" ./wp-content/plugins/redis-cache/
fi

# Install LiteSpeed Cache WordPress Plugin
if [ ! -e wp-content/plugins/litespeed-cache ]; then
	echo "Downloading https://downloads.wordpress.org/plugin/litespeed-cache.latest-stable.zip"
	curl -o litespeed-cache.zip -fsL "https://downloads.wordpress.org/plugin/litespeed-cache.latest-stable.zip"

	echo "Unzipping litespeed-cache.zip to wp-content/plugins/"
	unzip -q litespeed-cache.zip -d ./wp-content/plugins/

	echo "Removing litespeed-cache.zip"
	rm litespeed-cache.zip
		
	echo "Changing owner of all files in litespeed-cache plugin"
	chown -R "$user:$group" ./wp-content/plugins/litespeed-cache/
fi

# Install Google XML Sitemaps WordPress Plugin
if [ ! -e wp-content/plugins/google-sitemap-generator ]; then
	echo "Downloading https://downloads.wordpress.org/plugin/google-sitemap-generator.latest-stable.zip"
	curl -o google-sitemap-generator.zip -fsL "https://downloads.wordpress.org/plugin/google-sitemap-generator.latest-stable.zip"

	echo "Unzipping google-sitemap-generator.zip to wp-content/plugins/"
	unzip -q google-sitemap-generator.zip -d ./wp-content/plugins/

	echo "Removing google-sitemap-generator.zip"
	rm google-sitemap-generator.zip
		
	echo "Changing owner of all files in google-sitemap-generator plugin"
	chown -R "$user:$group" ./wp-content/plugins/google-sitemap-generator/
fi

# TODO handle WordPress upgrades magically in the same way, but only if wp-includes/version.php's $wp_version is less than /usr/src/wordpress/wp-includes/version.php's $wp_version

# allow any of these "Authentication Unique Keys and Salts." to be specified via
# environment variables with a "WORDPRESS_" prefix (ie, "WORDPRESS_AUTH_KEY")
uniqueEnvs=(
	AUTH_KEY
	SECURE_AUTH_KEY
	LOGGED_IN_KEY
	NONCE_KEY
	AUTH_SALT
	SECURE_AUTH_SALT
	LOGGED_IN_SALT
	NONCE_SALT
)
envs=(
	WORDPRESS_DB_HOST
	WORDPRESS_DB_USER
	WORDPRESS_DB_PASSWORD
	WORDPRESS_DB_NAME
	"${uniqueEnvs[@]/#/WORDPRESS_}"
	WORDPRESS_TABLE_PREFIX
	WORDPRESS_DEBUG
)
haveConfig=
for e in "${envs[@]}"; do
	file_env "$e"
	if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
		haveConfig=1
	fi
done

# linking backwards-compatibility
if [ -n "${!MYSQL_ENV_MYSQL_*}" ]; then
	haveConfig=1
	# host defaults to "mysql" below if unspecified
	: "${WORDPRESS_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}"
	if [ "$WORDPRESS_DB_USER" = 'root' ]; then
		: "${WORDPRESS_DB_PASSWORD:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-}}"
	else
		: "${WORDPRESS_DB_PASSWORD:=${MYSQL_ENV_MYSQL_PASSWORD:-}}"
	fi
	: "${WORDPRESS_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-}}"
fi

# only touch "wp-config.php" if we have environment-supplied configuration values
if [ "$haveConfig" ]; then
	: "${WORDPRESS_DB_HOST:=mysql}"
	: "${WORDPRESS_DB_USER:=root}"
	: "${WORDPRESS_DB_PASSWORD:=}"
	: "${WORDPRESS_DB_NAME:=wordpress}"

	# version 4.4.1 decided to switch to windows line endings, that breaks our seds and awks
	# https://github.com/docker-library/wordpress/issues/116
	# https://github.com/WordPress/WordPress/commit/1acedc542fba2482bab88ec70d4bea4b997a92e4
	sed -ri -e 's/\r$//' wp-config*

	if [ ! -e wp-config.php ]; then
		awk '/^\/\*.*stop editing.*\*\/$/ && c == 0 { c = 1; system("cat") } { print }' wp-config-sample.php > wp-config.php <<'EOPHP'

define('DISABLE_WP_CRON', true);
define('WP_REDIS_HOST', getenv('WP_REDIS_HOST'));
define('MYSQL_SSL_CA', getenv('MYSQL_SSL_CA'));
define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT);
#define('WP_HOME', 'http://'. $_SERVER['HTTP_HOST']);
#define('WP_SITEURL', 'http://'. $_SERVER['HTTP_HOST']);
#define('DOMAIN_CURRENT_SITE', $_SERVER['HTTP_HOST']);

// If we're behind a proxy server and using HTTPS, we need to alert Wordpress of that fact
// see also http://codex.wordpress.org/Administration_Over_SSL#Using_a_Reverse_Proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
$_SERVER['HTTPS'] = 'on';
}

EOPHP
		chown "$user:$group" wp-config.php
		cp wp-config.php wp-config-appsvc-sample.php
	fi

	# see http://stackoverflow.com/a/2705678/433558
	sed_escape_lhs() {
		echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
	}
	sed_escape_rhs() {
		echo "$@" | sed -e 's/[\/&]/\\&/g'
	}
	php_escape() {
		local escaped="$(php -r 'var_export(('"$2"') $argv[1]);' -- "$1")"
		if [ "$2" = 'string' ] && [ "${escaped:0:1}" = "'" ]; then
			escaped="${escaped//$'\n'/"' + \"\\n\" + '"}"
		fi
		echo "$escaped"
	}
	set_config() {
		key="$1"
		value="$2"
		var_type="${3:-string}"
		start="(['\"])$(sed_escape_lhs "$key")\2\s*,"
		end="\);"
		if [ "${key:0:1}" = '$' ]; then
			start="^(\s*)$(sed_escape_lhs "$key")\s*="
			end=";"
		fi
		sed -ri -e "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" wp-config.php
	}

	set_config 'DB_HOST' "$WORDPRESS_DB_HOST"
	set_config 'DB_USER' "$WORDPRESS_DB_USER"
	set_config 'DB_PASSWORD' "$WORDPRESS_DB_PASSWORD"
	set_config 'DB_NAME' "$WORDPRESS_DB_NAME"

	for unique in "${uniqueEnvs[@]}"; do
		uniqVar="WORDPRESS_$unique"
		if [ -n "${!uniqVar}" ]; then
			set_config "$unique" "${!uniqVar}"
		else
			# if not specified, let's generate a random value
			currentVal="$(sed -rn -e "s/define\((([\'\"])$unique\2\s*,\s*)(['\"])(.*)\3\);/\4/p" wp-config.php)"
			if [ "$currentVal" = 'put your unique phrase here' ]; then
				set_config "$unique" "$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)"
			fi
		fi
	done

	if [ "$WORDPRESS_TABLE_PREFIX" ]; then
		set_config '$table_prefix' "$WORDPRESS_TABLE_PREFIX"
	fi

	if [ "$WORDPRESS_DEBUG" ]; then
		set_config 'WP_DEBUG' 1 boolean
	fi

fi

# now that we're definitely done writing configuration, let's clear out the relevant environment variables (so that stray "phpinfo()" calls don't leak secrets from our code)
for e in "${envs[@]}"; do
	unset "$e"
done

# Sync site-local with site
sync-now &

service ssh start
service cron start

exec "$@"