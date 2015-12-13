#!/bin/sh

mkdir -p /var/lib/varnish/`hostname`
touch /var/lib/varnish/`hostname`/_.vsm
chown -R nobody /var/lib/varnish/`hostname`

sed "s@__BACKEND_ADDRESS__@${VARNISH_BACKEND_ADDRESS}@" </etc/varnish/default.vcl.source >/etc/varnish/default.vcl
sed -i "s@__BACKEND_PORT__@${VARNISH_BACKEND_PORT}@" /etc/varnish/default.vcl
sed -i "s@__BACKEND_HOSTNAME__@${VARNISH_BACKEND_HOSTNAME}@" /etc/varnish/default.vcl
sed -i "s@__PROBE_INTERVAL__@${VARNISH_PROBE_INTERVAL}@" /etc/varnish/default.vcl
sed -i "s@__PROBE_TIMEOUT__@${VARNISH_PROBE_TIMEOUT}@" /etc/varnish/default.vcl
sed -i "s@__GRACE_TIME__@${VARNISH_GRACE_TIME}@" /etc/varnish/default.vcl

varnishd -s malloc,${VARNISH_MEMORY} -a :80 -f $VARNISH_VCL_FILE
sleep 1
varnishlog