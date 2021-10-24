# vv-raspbian

Ansible playbook to deploy mpd, vv to Raspberry Pi OS.

Usage:
```sh
ansible-playbook  -i hosts -K mpd.yaml
```

mpd, vv version is defined in hosts file.

## mpd.yaml

Installs mpd to /usr/local.
Installed mpd uses /etc/mpd.conf.

* install mpd dependencies
* fetch mpd src
* configure mpd
* build mpd
* install mpd
* create mpd user
* start mpd

## vv.yaml

Installs vv to /usr/local.

* fetch vv
* install vv
* start vv

## tmpfs.yaml

Creates tmpfs to extend the life of the sd card.

* create tmpfs /tmp, /var/tmp, /var/log
* setup tmp mpd dir /var/log/mpd


## rpi.yaml

Setups SB32+PRO DoP i2s dac.

* disable onboard audio
* disable other hardware
* enable hifiberry-dacplus
* setup mpd output settings

