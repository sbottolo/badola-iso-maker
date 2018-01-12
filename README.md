# Badola ISO Maker
> Unattended Ubuntu ISO remastering

- Automatic ISO download.
- Customize Architecture, Version, Hostname, Domain, Default User, Timezone and Preseed File. 
- User (with sudo) and Password (SHA-512 crypted).
- Hyper-V Compatible via EFI Boot.
- Runnable on Linux or Windows via Docker Compose.

## Installation

Linux / Windows:

```bash
git clone https://pmstar@bitbucket.org/starspa/bash-iso-maker.git
```

## Bash Usage

```bash
cd bash-iso-maker/src
./iso-maker
```

## Docker Usage (Linux/Windows)

```docker
cd bash-iso-maker
docker-compose run badola_isomaker bash

bash# sudo su
/app# ./badola-iso-maker.sh
```

## Run with parameters

```bash
./badola-iso-maker.sh \
 -seedfile autoinstall.cfg \
 -osarch amd64 \
 -osver 16.04 \
 -hostname unassigned-hostname \
 -domain unassigned-domain \
 -timezone Etc/UTC \
 -username develop \
 -password develop
```