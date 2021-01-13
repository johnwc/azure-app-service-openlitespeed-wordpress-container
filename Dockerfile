ARG OLS_VERSION=1.6.18
ARG PHP_VERSION=lsphp74
FROM johnwcarew/azure-app-service-openlitespeed-php:$OLS_VERSION-$PHP_VERSION

ENV WORDPRESS_VERSION 5.6
ENV WORDPRESS_SHA1 db8b75bfc9de27490434b365c12fd805ca6784ce

RUN set -ex; \
	apt-get update; \
	apt-get -y install \
	unzip; \
	rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz

COPY .htaccess /usr/src/wordpress
COPY cron.sh /usr/src/php/cron.sh
RUN chmod -x /usr/src/wordpress/.htaccess; \
	chmod +x /usr/src/php/cron.sh; \
	chown -R 1000:1000 /usr/src/wordpress

EXPOSE 2222 80 7080

COPY setup-wp-cron /usr/local/bin/
COPY wp-container-version /etc
COPY wordpress-entrypoint.sh /usr/local/bin/
RUN chmod 444 /etc/wp-container-version; \
	chmod +x /usr/local/bin/setup-wp-cron; \
	chmod +x /usr/local/bin/wordpress-entrypoint.sh

WORKDIR /home/site/wwwroot

ENTRYPOINT ["wordpress-entrypoint.sh"]
CMD ["/entrypoint.sh"]