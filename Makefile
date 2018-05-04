MPD_VERSION = 0.20.19
MPD_OPTIONS = --disable-un --disable-fifo --disable-httpd-output --disable-recorder-output --disable-oss --disable-ipv6 --disable-dsd --disable-libmpdclient --disable-curl --with-systemdsystemunitdir=/lib/systemd/system
MPD_DEP = build-essential automake libid3tag0-dev libflac-dev libvorbis-dev libsndfile1-dev libboost-dev libicu-dev libsqlite3-dev libsystemd-dev libglib2.0-dev libmms-dev libmpdclient-dev libpostproc-dev libavutil-dev libavcodec-dev libavformat-dev libnfs-dev libsmbclient-dev libsoxr-dev libasound2-dev libmpg123-dev
VV_VERSION = v0.5.6
ARCH=armv6


.PHONY: help noswap nodesktop tmpfs
 
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: noswap nodesktop tmpfs install-mpd install-vv  ## execute all target

noswap:  ## remove swap feature && files to reduce sd card r/w access
	swapoff --all
	@- systemctl stop dphys-swapfile || true
	@- systemctl disable dphys-swapfile || true
	rm -fr /var/swap

nodesktop: /lib/systemd/system/nohdmi.service  ## remove desktop daemon
	systemctl disable keyboard-setup
	systemctl disable triggerhappy
	systemctl disable bluetooth
	systemctl disable rpi-display-backlight

/lib/systemd/system/nohdmi.service: lib/systemd/system/nohdmi.service
	cp lib/systemd/system/nohdmi.service /lib/systemd/system/nohdmi.service
	systemctl daemon-reload
	systemctl enable nohdmi

tmpfs: /etc/tmpfiles.d/log.conf  ## make tmpfs for logs to reduce sd card r/w access
	mkdir -p /etc/tmpfiles.d
	grep "/tmp " /etc/fstab || echo "tmpfs /tmp tmpfs defaults,size=32m,noatime,mode=1777 0 0" >> /etc/fstab
	grep "/var/tmp " /etc/fstab || echo "tmpfs /var/tmp tmpfs defaults,size=16m,noatime,mode=1777 0 0" >> /etc/fstab
	grep "/var/log " /etc/fstab || echo "tmpfs /var/log tmpfs defaults,size=32m,noatime,mode=0755 0 0" >> /etc/fstab

/etc/tmpfiles.d/log.conf: etc/tmpfiles.d/log.conf
	cp etc/tmpfiles.d/log.conf /etc/tmpfiles.d/log.conf

# mpd
install-mpd: /lib/systemd/system/mpd.service /usr/local/bin/mpd mpd-config ## install mpd
mpd-build: mpd/MPD-$(MPD_VERSION)/src/mpd
mpd-config: /etc/mpd.conf /var/lib/mpd /var/lib/mpd/tag_cache /var/lib/mpd/playlists /etc/tmpfiles.d/mpd.conf

/usr/local/bin/mpd: mpd/MPD-$(MPD_VERSION)/src/mpd
	cp mpd/MPD-$(MPD_VERSION)/src/mpd /usr/local/bin/mpd

mpd/v$(MPD_VERSION).tar.gz:
	mkdir -p mpd
	cd mpd && wget https://github.com/MusicPlayerDaemon/MPD/archive/v$(MPD_VERSION).tar.gz

mpd/MPD-$(MPD_VERSION): mpd/v$(MPD_VERSION).tar.gz
	cd mpd && tar -mxvzf v$(MPD_VERSION).tar.gz

mpd/MPD-$(MPD_VERSION)/src/mpd: mpd/MPD-$(MPD_VERSION)
	apt install -y $(MPD_DEP)
	cd mpd/MPD-$(MPD_VERSION) && ./autogen.sh
	cd mpd/MPD-$(MPD_VERSION) && ./configure $(MPD_OPTIONS)

/lib/systemd/system/mpd.service: lib/systemd/system/mpd.service
	cp lib/systemd/system/mpd.service /lib/systemd/system/mpd.service
	systemctl daemon-reload
	systemctl enable mpd

/etc/mpd.conf: etc/mpd.conf
	@- useradd -r -g audio -s /sbin/nologin mpd || true
	cp etc/mpd.conf /etc/mpd.conf
	chown mpd:audio /etc/mpd.conf

/var/lib/mpd:
	@- useradd -r -g audio -s /sbin/nologin mpd || true
	mkdir -p /var/lib/mpd
	chown mpd:audio /var/lib/mpd

/var/lib/mpd/playlists: /var/lib/mpd
	mkdir -p /var/lib/mpd/playlists
	chown mpd:audio /var/lib/mpd/tag_cache

/var/lib/mpd/tag_cache: /var/lib/mpd
	mkdir -p /var/lib/mpd/tag_cache
	chown mpd:audio /var/lib/mpd/tag_cache

/etc/tmpfiles.d/mpd.conf: etc/tmpfiles.d/mpd.conf
	cp etc/tmpfiles.d/mpd.conf /etc/tmpfiles.d/mpd.conf

# vv
.PHONY: install-vv
install-vv: /usr/local/bin/vv /lib/systemd/system/vv.service /etc/xdg/vv/config.yaml  ## install mpd web ui

vv/$(VV_VERSION)/vv-linux-$(ARCH).tar.gz:
	mkdir -p vv/$(VV_VERSION)
	curl -L https://github.com/meiraka/vv/releases/download/$(VV_VERSION)/vv-linux-$(ARCH).tar.gz -o vv/$(VV_VERSION)/vv-linux-$(ARCH).tar.gz

vv/$(VV_VERSION)/vv: vv/$(VV_VERSION)/vv-linux-$(ARCH).tar.gz
	tar -mxvzf vv/$(VV_VERSION)/vv-linux-$(ARCH).tar.gz -C vv/$(VV_VERSION)

/usr/local/bin/vv: vv/$(VV_VERSION)/vv
	@- systemctl stop vv || true
	cp vv/$(VV_VERSION)/vv /usr/local/bin/vv
	@- systemctl start vv || true

/lib/systemd/system/vv.service: lib/systemd/system/vv.service
	cp lib/systemd/system/vv.service /lib/systemd/system/vv.service
	systemctl daemon-reload
	systemctl enable vv

/etc/xdg/vv/config.yaml: etc/xdg/vv/config.yaml
	mkdir -p /etc/xdg/vv
	cp etc/xdg/vv/config.yaml /etc/xdg/vv/config.yaml
