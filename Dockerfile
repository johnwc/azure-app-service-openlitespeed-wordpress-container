FROM johnwcarew/azure-app-service-openlitespeed:latest

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
RUN chmod -x /usr/src/wordpress/.htaccess; \
	chown -R 1000:1000 /usr/src/wordpress

EXPOSE 2222 80 7080

COPY wordpress-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh

ENTRYPOINT ["wordpress-entrypoint.sh"]
CMD ["/entrypoint.sh"]