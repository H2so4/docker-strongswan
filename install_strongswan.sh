#/bin/bash

CWD=`pwd`

install_strongswan(){
	mkdir -p /conf
	apt-get update && apt-get install -y \
	  libgmp-dev \
	  iptables \
	  xl2tpd \
	  module-init-tools \
	  curl \
	  build-essential \
	  libssl-dev

	STRONGSWAN_VERSION=5.5.1
	GPG_KEY=948F158A4E76A27BF3D07532DF42C170B34DBA77

	mkdir -p /usr/src/strongswan \
		&& pushd /usr/src \
		&& curl -SOL "https://download.strongswan.org/strongswan-$STRONGSWAN_VERSION.tar.gz.sig" \
		&& curl -SOL "https://download.strongswan.org/strongswan-$STRONGSWAN_VERSION.tar.gz" \
		&& export GNUPGHOME="$(mktemp -d)" \
		&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
		&& gpg --batch --verify strongswan-$STRONGSWAN_VERSION.tar.gz.sig strongswan-$STRONGSWAN_VERSION.tar.gz \
		&& tar -zxf strongswan-$STRONGSWAN_VERSION.tar.gz -C /usr/src/strongswan --strip-components 1 \
		&& pushd /usr/src/strongswan \
		&& ./configure --prefix=/usr --sysconfdir=/etc \
			--enable-eap-radius \
			--enable-eap-mschapv2 \
			--enable-eap-identity \
			--enable-eap-md5 \
			--enable-eap-mschapv2 \
			--enable-eap-tls \
			--enable-eap-ttls \
			--enable-eap-peap \
			--enable-eap-tnc \
			--enable-eap-dynamic \
			--enable-xauth-eap \
			--enable-openssl \
		&& make -j \
		&& make install \
		&& rm -rf "/usr/src/strongswan*"
}
stat /usr/src/strongswan || install_strongswan

cd $CWD
# Strongswan Configuration
cp ./ipsec.conf /etc/ipsec.conf
cp ./strongswan.conf /etc/strongswan.conf

# XL2TPD Configuration
cp ./xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
cp ./options.xl2tpd /etc/ppp/options.xl2tpd

cp ./run.sh /run.sh
cp ./vpn_adduser /usr/local/bin/vpn_adduser
cp ./vpn_deluser /usr/local/bin/vpn_deluser
cp ./vpn_setpsk /usr/local/bin/vpn_setpsk
cp ./vpn_unsetpsk /usr/local/bin/vpn_unsetpsk
cp ./vpn_apply /usr/local/bin/vpn_apply
################ Configure stuff
# The password is later on replaced with a random string
VPN_USER=user
VPN_PASSWORD=password
VPN_PSK=password

if [ "$VPN_PASSWORD" = "password" ] || [ "$VPN_PASSWORD" = "" ]; then
	# Generate a random password
	P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	VPN_PASSWORD="$P1$P2$P3"
	echo "No VPN_PASSWORD set! Generated a random password: $VPN_PASSWORD"
fi

if [ "$VPN_PSK" = "password" ] || [ "$VPN_PSK" = "" ]; then
	# Generate a random password
	P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
	VPN_PSK="$P1$P2$P3"
	echo "No VPN_PSK set! Generated a random PSK key: $VPN_PSK"
fi

if [ "$VPN_PASSWORD" = "$VPN_PSK" ]; then
	echo "It is not recommended to use the same secret as password and PSK key!"
fi

cat > /etc/ppp/l2tp-secrets <<EOF
# This file holds secrets for L2TP authentication.
# Username  Server  Secret  Hosts
"$VPN_USER" "*" "$VPN_PASSWORD" "*"
EOF

cat > /etc/ipsec.secrets <<EOF
# This file holds shared secrets or RSA private keys for authentication.
# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".
: PSK "$VPN_PSK"
$VPN_USER : EAP "$VPN_PASSWORD"
$VPN_USER : XAUTH "$VPN_PASSWORD"
EOF

if [ -f "/etc/ipsec.d/l2tp-secrets" ]; then
	echo "Overwriting standard /etc/ppp/l2tp-secrets with /etc/ipsec.d/l2tp-secrets"
	cp -f /etc/ipsec.d/l2tp-secrets /etc/ppp/l2tp-secrets
fi

if [ -f "/etc/ipsec.d/ipsec.secrets" ]; then
	echo "Overwriting standard /etc/ipsec.secrets with /etc/ipsec.d/ipsec.secrets"
	cp -f /etc/ipsec.d/ipsec.secrets /etc/ipsec.secrets
fi

if [ -f "/etc/ipsec.d/ipsec.conf" ]; then
	echo "Overwriting standard /etc/ipsec.conf with /etc/ipsec.d/ipsec.conf"
	cp -f /etc/ipsec.d/ipsec.conf /etc/ipsec.conf
fi

if [ -f "/etc/ipsec.d/strongswan.conf" ]; then
	echo "Overwriting standard /etc/strongswan.conf with /etc/ipsec.d/strongswan.conf"
	cp -f /etc/ipsec.d/strongswan.conf /etc/strongswan.conf
fi

if [ -f "/etc/ipsec.d/xl2tpd.conf" ]; then
	echo "Overwriting standard /etc/xl2tpd/xl2tpd.conf with /etc/ipsec.d/xl2tpd.conf"
	cp -f /etc/ipsec.d/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
fi
