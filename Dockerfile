FROM fluent/fluentd:v1.10-debian

USER root
RUN apt-get update \
    && apt-get upgrade -y -qq \
    && apt-get install \
        -y --no-install-recommends net-tools curl \
    && gem install \
        fluent-plugin-elasticsearch \
        fluent-plugin-s3 \
        fluent-plugin-record-modifier \
        fluent-plugin-rewrite-tag-filter \
        fluent-plugin-prometheus \
    && gem sources --clear-all

COPY conf/ /fluentd/etc/
COPY entrypoint.sh /bin/
