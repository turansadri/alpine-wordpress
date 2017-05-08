FROM evild/alpine-php:7.0.8

ARG WORDPRESS_VERSION=4.7.4
ARG WORDPRESS_SHA1=153592ccbb838cafa1220de9174ec965df2e9e1a

RUN apk add --no-cache --virtual .build-deps \
                autoconf gcc libc-dev make \
                libpng-dev libjpeg-turbo-dev \
        && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install gd mysqli opcache \
        && find /usr/local/lib/php/extensions -name '*.a' -delete \
        && find /usr/local/lib/php/extensions -name '*.so' -exec strip --strip-all '{}' \; \
        && runDeps="$( \
                scanelf --needed --nobanner --recursive \
                        /usr/local/lib/php/extensions \
                        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                        | sort -u \
                        | xargs -r apk info --installed \
                        | sort -u \
        )" \
        && apk add --virtual .phpext-rundeps $runDeps \
        && apk del .build-deps

RUN rm -rf /usr/local/etc/php/conf.d/opcache-recommended.ini


VOLUME /var/www/html

RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
        && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
        && tar -xzf wordpress.tar.gz -C /usr/src/ \
        && rm wordpress.tar.gz \
        && chown -R www-data:www-data /usr/src/wordpress

ADD root /
