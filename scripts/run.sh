#!/bin/bash

# fix permissions due to netdata running as root
chown root:root /usr/share/netdata/web/ -R
echo -n "" > /usr/share/netdata/web/version.txt

# set up msmtp
if [[ $SMTP_TO ]]; then
cat << EOF > /etc/msmtprc
account default
aliases /etc/msmtp_aliases
from $SMTP_FROM
host $SMTP_SERVER
port $SMTP_PORT
tls $SMTP_TLS
tls_starttls $SMTP_STARTTLS
tls_certcheck off
EOF

cat << EOF > /etc/msmtp_aliases
netdata: $SMTP_TO
root: $SMTP_TO
EOF
fi

if [[ $SMTP_USER ]]; then
cat << EOF >> /etc/msmtprc
auth on
user $SMTP_USER
EOF
fi

if [[ $SMTP_PASS ]]; then
cat << EOF >> /etc/msmtprc
password $SMTP_PASS
EOF
fi

# copy conf from NETDATA_STOCK_CONFIG_DIR (normally under /usr/lib/netdata/conf.d) to NETDATA_USER_CONFIG_DIR (normally under /etc/netdata)
cp /usr/lib/netdata/conf.d/health_alarm_notify.conf /etc/netdata

# For EMAIL_SENDER, assuming the value comes from netDataInfo.data.smtp.sender
if [[ $SMTP_SENDER ]]; then
	sed -i -e "s@EMAIL_SENDER=\"\"@EMAIL_SENDER=\"${SMTP_SENDER}\"@" /etc/netdata/health_alarm_notify.conf
fi

# For DEFAULT_RECIPIENT_EMAIL, assuming the value comes from netDataInfo.data.smtp.to
if [[ $SMTP_TO ]]; then
	sed -i -e "s@DEFAULT_RECIPIENT_EMAIL=\"\"@DEFAULT_RECIPIENT_EMAIL=\"${SMTP_TO}\"@" /etc/netdata/health_alarm_notify.conf
fi

# For enabling email, set SEND_EMAIL to YES if both SMTP_SENDER and SMTP_TO are set
if [[ $SMTP_SENDER && $SMTP_TO ]]; then
	sed -i -e "s@SEND_EMAIL=\"NO\"@SEND_EMAIL=\"YES\"@" /etc/netdata/health_alarm_notify.conf
fi

if [[ $SLACK_WEBHOOK_URL ]]; then
	sed -i -e "s@SLACK_WEBHOOK_URL=\"\"@SLACK_WEBHOOK_URL=\"${SLACK_WEBHOOK_URL}\"@" /etc/netdata/health_alarm_notify.conf
fi

if [[ $SLACK_CHANNEL ]]; then
	sed -i -e "s@DEFAULT_RECIPIENT_SLACK=\"\"@DEFAULT_RECIPIENT_SLACK=\"${SLACK_CHANNEL}\"@" /etc/netdata/health_alarm_notify.conf
fi

# Add this part for the SEND_SLACK="YES"
if [[ $SLACK_WEBHOOK_URL && $SLACK_CHANNEL ]]; then
	sed -i -e "s@SEND_SLACK=\"NO\"@SEND_SLACK=\"YES\"@" /etc/netdata/health_alarm_notify.conf
fi

# if [[ $DISCORD_WEBHOOK_URL ]]; then
# 	sed -i -e "s@DISCORD_WEBHOOK_URL=\"\"@DISCORD_WEBHOOK_URL=\"${DISCORD_WEBHOOK_URL}\"@" /etc/netdata/health_alarm_notify.conf
# fi

# if [[ $DISCORD_RECIPIENT ]]; then
# 	sed -i -e "s@DEFAULT_RECIPIENT_DISCORD=\"\"@DEFAULT_RECIPIENT_DISCORD=\"${DISCORD_RECIPIENT}\"@" /etc/netdata/health_alarm_notify.conf
# fi
# # Add this part for the SEND_DISCORD="YES"
# if [[ $DISCORD_WEBHOOK_URL && $DISCORD_RECIPIENT ]]; then
# 	sed -i -e "s@SEND_DISCORD=\"NO\"@SEND_DISCORD=\"YES\"@" /etc/netdata/health_alarm_notify.conf
# fi

# For Telegram
if [[ $TELEGRAM_BOT_TOKEN ]]; then
	sed -i -e "s@TELEGRAM_BOT_TOKEN=\"\"@TELEGRAM_BOT_TOKEN=\"${TELEGRAM_BOT_TOKEN}\"@" /etc/netdata/health_alarm_notify.conf
fi

if [[ $TELEGRAM_CHAT_ID ]]; then
	sed -i -e "s@DEFAULT_RECIPIENT_TELEGRAM=\"\"@DEFAULT_RECIPIENT_TELEGRAM=\"${TELEGRAM_CHAT_ID}\"@" /etc/netdata/health_alarm_notify.conf
fi

# Add this part for the SEND_TELEGRAM="YES"
if [[ $TELEGRAM_BOT_TOKEN && $TELEGRAM_CHAT_ID ]]; then
	sed -i -e "s@SEND_TELEGRAM=\"NO\"@SEND_TELEGRAM=\"YES\"@" /etc/netdata/health_alarm_notify.conf
fi

# For PushBullet
if [[ $PUSHBULLET_ACCESS_TOKEN ]]; then
	sed -i -e "s@PUSHBULLET_ACCESS_TOKEN=\"\"@PUSHBULLET_ACCESS_TOKEN=\"${PUSHBULLET_ACCESS_TOKEN}\"@" /etc/netdata/health_alarm_notify.conf
fi

if [[ $PUSHBULLET_DEFAULT_EMAIL ]]; then
	sed -i -e "s#DEFAULT_RECIPIENT_PUSHBULLET=\"\"#DEFAULT_RECIPIENT_PUSHBULLET=\"${PUSHBULLET_DEFAULT_EMAIL}\"#" /etc/netdata/health_alarm_notify.conf
fi

# Add this part for the SEND_PUSHBULLET="YES"
if [[ $PUSHBULLET_ACCESS_TOKEN && $PUSHBULLET_DEFAULT_EMAIL ]]; then
	sed -i -e "s@SEND_PUSHBULLET=\"NO\"@SEND_PUSHBULLET=\"YES\"@" /etc/netdata/health_alarm_notify.conf
fi

if [[ $NETDATA_IP ]]; then
	NETDATA_ARGS="${NETDATA_ARGS} -i ${NETDATA_IP}"
fi

# on a client netdata set this destination to be the [PROTOCOL:]HOST[:PORT] of the
# central netdata, and give an API_KEY that is secret and only known internally
# to the netdata clients, and netdata central
if [[ $NETDATA_STREAM_DESTINATION ]] && [[ $NETDATA_STREAM_API_KEY ]]; then
	cat << EOF > /etc/netdata/stream.conf
[stream]
	enabled = yes
	destination = $NETDATA_STREAM_DESTINATION
	api key = $NETDATA_STREAM_API_KEY
EOF
fi

# set 1 or more NETADATA_API_KEY_ENABLE env variables, such as NETDATA_API_KEY_ENABLE_1h213ch12h3rc1289e=1
# that matches the API_KEY that you used on the client above, this will enable the netdata client
# node to communicate with the netdata central
if printenv | grep -q 'NETDATA_API_KEY_ENABLE_'; then
	printenv | grep -oe 'NETDATA_API_KEY_ENABLE_[^=]\+' | sed 's/NETDATA_API_KEY_ENABLE_//' | xargs -n1 -I{} echo '['{}$']\n\tenabled = yes' >> /etc/netdata/stream.conf
fi

# exec custom command
if [[ $# -gt 0 ]] ; then
        exec "$@"
        exit
fi

if [[ -d "/fakenet/" ]]; then
	echo "Running fakenet config reload in background"
	( sleep 10 ; curl -s http://localhost:${NETDATA_PORT}/netdata.conf | sed -e 's/# filename/filename/g' | sed -e 's/\/host\/proc\/net/\/fakenet\/proc\/net/g' > /etc/netdata/netdata.conf ; pkill -9 netdata ) &
	/usr/sbin/netdata -D -u root -s /host -p ${NETDATA_PORT}
	# add some artificial sleep because netdata might think it can't bind to $NETDATA_PORT
	# and report things like "netdata: FATAL: Cannot listen on any socket. Exiting..."
	sleep 1
fi

for f in /etc/netdata/override/*; do
  cp -a $f /etc/netdata/
done

# main entrypoint
touch /etc/netdata/python.d.conf
exec /usr/sbin/netdata -D -u root -s /host -p ${NETDATA_PORT} ${NETDATA_ARGS} "$@"