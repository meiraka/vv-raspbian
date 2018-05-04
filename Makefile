ROOT = /
FSTAB = $(ROOT)etc/fstab
MPD_VERSION = 0.20.19
MPD_OPTIONS = "--disable-un --disable-fifo --disable-httpd-output --disable-recorder-output --disable-oss --disable-ipv6 --disable-dsd --disable-libmpdclient --disable-curl --with-systemdsystemunitdir=/lib/systemd/system"

.PHONY: help rmswap tmpfs
 
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

rmswap:  ## remove swap feature && files to reduce sd card r/w access
	swapoff --all
	apt purge -y --auto-remove dphys-swapfile
	rm -fr /var/swap

tmpfs:  ## make tmpfs for logs to reduce sd card r/w access
	mkdir -p $(ROOT)etc/tmpfiles.d
	touch $(FSTAB)
	grep "/tmp " $(FSTAB) || echo "tmpfs /tmp tmpfs defaults,size=32m,noatime,mode=1777 0 0" >> $(FSTAB)
	grep "/var/tmp " $(FSTAB) || echo "tmpfs /var/tmp tmpfs defaults,size=16m,noatime,mode=1777 0 0" >> $(FSTAB)
	grep "/var/log " $(FSTAB) || echo "tmpfs /var/log tmpfs defaults,size=32m,noatime,mode=0755 0 0" >> $(FSTAB)
	cp etc/tmpfiles.d/log.conf $(ROOT)etc/tmpfiles.d/log.conf

rmdesktop:  ## remove desktop daemon
	systemctl disable keyboard-setup
	systemctl disable triggerhappy
	systemctl disable bluetooth
	systemctl disable rpi-display-backlight


# mpd

mpd-build: mpd/MPD-$(MPD_VERSION)/src/mpd

.PHONY: mpd-install mpd-config
mpd-install: mpd-build mpd-config  ## install mpd
	cd mpd/MPD-$(MPD_VERSION) && make install

mpd-config: /etc/mpd.conf /var/lib/mpd

mpd/v$(MPD_VERSION).tar.gz:
	mkdir -p mpd
	cd mpd && wget https://github.com/MusicPlayerDaemon/MPD/archive/v$(MPD_VERSION).tar.gz

mpd/MPD-$(MPD_VERSION): mpd/v$(MPD_VERSION).tar.gz
	cd mpd && tar -xvzf v$(MPD_VERSION).tar.gz

mpd/MPD-$(MPD_VERSION)/src/mpd: mpd/MPD-$(MPD_VERSION)
	apt install -y build-essential automake libid3tag0-dev libflac-dev libvorbis-dev libsndfile1-dev libboost-dev libicu-dev libsqlite3-dev libsystemd-dev libglib2.0-dev libmms-dev libmpdclient-dev libpostproc-dev libavutil-dev libavcodec-dev libavformat-dev libnfs-dev libsmbclient-dev libsoxr-dev libasound2-dev libmpg123-dev
	cd mpd/MPD-$(MPD_VERSION) && ./autogen.sh
	cd mpd/MPD-$(MPD_VERSION) && ./configure $(MPD_OPTIONS)

/etc/mpd.conf:
	@- useradd -r -g audio -s /sbin/nologin mpd || true
	cp mpd/mpd.conf /etc/mpd.conf
	chown mpd:audio /etc/mpd.conf

/var/lib/mpd:
	@- useradd -r -g audio -s /sbin/nologin mpd || true
	mkdir -p /var/lib/mpd
	chown mpd:audio /var/lib/mpd
