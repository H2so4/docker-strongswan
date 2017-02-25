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

	# The password is later on replaced with a random string
	VPN_USER=user
	VPN_PASSWORD=password
	VPN_PSK=password
}
stat /usr/src/strongswan || install_strongswan
/run.sh