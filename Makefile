ROOT = /
FSTAB = $(ROOT)etc/fstab

rmswap:
	swapoff --all
	apt purge -y --auto-remove dphys-swapfile
	rm -fr /var/swap

tmpfs:
	mkdir -p $(ROOT)etc/tmpfiles.d
	touch $(FSTAB)
	grep "/tmp " $(FSTAB) || echo "tmpfs /tmp tmpfs defaults,size=32m,noatime,mode=1777 0 0" >> $(FSTAB)
	grep "/var/tmp " $(FSTAB) || echo "tmpfs /var/tmp tmpfs defaults,size=16m,noatime,mode=1777 0 0" >> $(FSTAB)
	grep "/var/log " $(FSTAB) || echo "tmpfs /var/log tmpfs defaults,size=32m,noatime,mode=0755 0 0" >> $(FSTAB)
	cp etc/tmpfiles.d/log.conf $(ROOT)etc/tmpfiles.d/log.conf
