#!/bin/bash

claimMe() 
{
cat<<EOF
██████╗  █████╗ ██████╗  ██████╗ ██╗      █████╗     ██╗███████╗ ██████╗     ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗ 
██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║     ██╔══██╗    ██║██╔════╝██╔═══██╗    ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
██████╔╝███████║██║  ██║██║   ██║██║     ███████║    ██║███████╗██║   ██║    ██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝
██╔══██╗██╔══██║██║  ██║██║   ██║██║     ██╔══██║    ██║╚════██║██║   ██║    ██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
██████╔╝██║  ██║██████╔╝╚██████╔╝███████╗██║  ██║    ██║███████║╚██████╔╝    ██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║
╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝╚══════╝ ╚═════╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                                                                        
EOF
}

# Get architecture
get-architecture()
{
	read -ep $'\e[44mWhat bit version of OS? [i386(32 bit), amd64 (64 bit)] [Default: amd64]\e[0m: ' -i "amd64" osarch
	osarch=${osarch:-"amd64"}
	echo $osarch
}

# Get Ubuntu release URL
ubuntu-release()
{
	rel=http://releases.ubuntu.com/$2
	echo $rel/$(curl --silent $rel/MD5SUMS | \grep -o 'ubuntu-.*-server-'$1'.iso')
}

build-iso() {

	claimMe

	while [ -n "$1" ]
 	# while loop starts
	do
		case "$1" in
		-osarch) osarch="$2"
			shift;;
		-osver) osver="$2"
			shift;;
		-seedfile) seed_file="$2"
			shift;;
		-hostname) hostname="$2"
			shift;;
		-domain) domain="$2"
			shift;;
		-timezone) timezone="$2"
			shift;;
		-username) username="$2"
			shift;;
		-password) password="$2"
			shift;;

		# The double dash makes them parameters
		--) shift
		break;;
		*) echo "Option $1 not recognized"
		esac
			shift
	done

	# get os architecture
	if [ -z $osarch ]; then
		osarch=($(get-architecture))
	fi

	# get ubuntu releases
	if [ -z $osver ]; then
		all=($(wget -O- releases.ubuntu.com -q | perl -ne '/Ubuntu (\d+.\d+)/ && print "$1\n"' | sort -Vu))

		# choose and check release
		if [ "$2" == latest ]; then
			iso_url=$(ubuntu-release $osarch ${all[-1]})
		else if [ -z "$*" ]; then
			echo releases.ubuntu.com $osarch has ${all[*]}
			read -p $'\e[44mChoose version\e[0m: ' -e -i "${all[-1]}" v
			[ "$v" ] || v=${all[-1]}
			iso_url=$(ubuntu-release $osarch $v)
		else if expr match "${2}" "^http" > /dev/null; then
			iso_url="$2"
		else if expr match "$2" "[0-9]\+.[0-9]\+$" > /dev/null; then
				iso_url=$(ubuntu-release $1 $2)
			else
				iso_url="$2"
			fi
		fi
		fi
		fi
	else
		iso_url=$(ubuntu-release $osarch $osver)
	fi

	# ask the user questions about preferences
	if [ -z $seed_file ]; then
		read -ep $'\e[44mEnter your preferred seed file\e[0m: ' -i "autoinstall.cfg" seed_file
	fi

	if [ -z $hostname ]; then
		read -ep $'\e[44mEnter your preferred hostname\e[0m: ' -i "ubuntu" hostname
	fi

	if [ -z $domain ]; then
		read -ep $'\e[44mEnter your preferred domain\e[0m: ' -i "ubuntu.local" domain
	fi

	if [ -z $timezone ]; then
		read -ep $'\e[44mEnter your preferred timezone\e[0m: ' -i "Etc/UTC" timezone
	fi

	if [ -z $username ]; then
		read -ep $'\e[44mEnter your preferred username\e[0m: ' -i "develop" username
	fi

	if [ -z $password ]; then
		read -sp $'\e[44mEnter your preferred password\e[0m: ' password
		printf "\n"
		read -sp $'\e[44mConfirm your preferred password\e[0m: ' password2

		# check if the passwords match to prevent headaches
		if [[ "$password" != "$password2" ]]; then
			echo -e "\e[41mPasswords do not match; please restart the script and try again\e[0m"
			echo
			exit
		fi
	fi

	# summary
	echo "> os architecture: $osarch"
	echo "> os version: $osver"
	echo "> iso url: $iso_url"
	echo "> seed_file: $seed_file"
	echo "> hostname: $hostname"
	echo "> domain: $domain"
	echo "> timezone: $timezone"
	echo "> username: $username"
	echo "> password: $password"

	# generate the password hash
	pwdhash=$(mkpasswd -s -m sha-512 $password)

	
	# check if iso is exists or it must be downloaded
	iso_base=$(basename $iso_url)
	base=$(basename $iso_url .iso)
	iso=$(find $PWD/.iso/ -name "$iso_base")
	echo 
	
	if [ ! -e "$iso" ]; then
		echo -e "\e[44mISO download to $PWD/.iso/$iso_base\e[0m"
		wget -nc $iso_url -P ./.iso || return
		iso=./.iso/$iso_base
	else
		echo -e "\e[42mISO exists into $PWD/.iso/$iso_base\e[0m"
	fi

	# check if iso is exists or it must be downloaded
	iso_files_path="$PWD/.iso_files"
	if [ -d "$iso_files_path" ]; then
		echo -e "\e[44mRemove files into $iso_files_path\e[0m"
		chmod -R 777 "$iso_files_path"
		rm -r "$iso_files_path"
	else
		echo -e "\e[42mCreating directory $iso_files_path\e[0m"
		mkdir $iso_files_path
	fi

	# extract iso files
	echo -e "\e[44mExtract .iso/$iso_base in $iso_files_path\e[0m"
	xorriso -osirrox on -indev .iso/$iso_base -extract / $iso_files_path

	# add preseed file
	echo -e "\e[44mAdd preseed file\e[0m"
	cp -rf "$PWD/conf/ubuntu/preseed/$seed_file" "$iso_files_path/preseed/"

	# update the seed file to reflect the users' choices
	# the normal separator for sed is /, but both the password and the timezone may contain it
	# so instead, I am using @
	
	sed -i "s@{{hostname}}@$hostname@g" "$iso_files_path/preseed/$seed_file"
	sed -i "s@{{domain}}@$domain@g" "$iso_files_path/preseed/$seed_file"
	sed -i "s@{{timezone}}@$timezone@g" "$iso_files_path/preseed/$seed_file"
	sed -i "s@{{username}}@$username@g" "$iso_files_path/preseed/$seed_file"
	sed -i "s@{{pwdhash}}@$pwdhash@g" "$iso_files_path/preseed/$seed_file"
	
	# replace grub.cfg
	echo -e "\e[44mReplace grub.cfg\e[0m"
	cp -rf "$PWD/conf/ubuntu/boot/grub/grub.cfg" "$iso_files_path/boot/grub/"

	# update grub.cfg
	sed -i "s@{{hostname}}@$hostname@g" "$iso_files_path/boot/grub/grub.cfg"
	sed -i "s@{{seed_file}}@$seed_file@g" "$iso_files_path/boot/grub/grub.cfg"

	# replace isolinux/txt.cfg
	echo -e "\e[44mReplace isolinux/txt.cfg for legacy support\e[0m"
	cp -rf "$PWD/conf/ubuntu/isolinux/txt.cfg" "$iso_files_path/isolinux/"

	# update isolinux/txt.cfg
	sed -i "s@{{seed_file}}@$seed_file@g" "$iso_files_path/isolinux/txt.cfg"

	# obtain isohdpfx.bin for hybrid ISO
	echo -e "\e[44mObtain isohdpfx.bin for hybrid ISO\e[0m"
	dd if="$PWD/.iso/$iso_base" bs=512 count=1 of="$iso_files_path/isolinux/isohdpfx.bin"

	# build image
	iso_files_path="$PWD/output"
	if [ -d "$iso_files_path" ]; then
		chmod -R 777 "$iso_files_path"
		rm -r "$iso_files_path/*"
	else
		mkdir "$iso_files_path"
		chmod -R 777 "$iso_files_path"
	fi
	
	isolinux_mbr="isolinux/isohdpfx.bin"
	isolinux_cat="isolinux/boot.cat"
	isolinux_bin="isolinux/isolinux.bin"
	boot_efi_img="boot/grub/efi.img"
	target_iso_path="../output/custom-ubuntu.iso"
	source_iso_path="."

	cd "$PWD/.iso_files" \
	 && xorriso -as mkisofs \
	 -isohybrid-mbr "$isolinux_mbr" \
	 -c "$isolinux_cat" \
	 -b "$isolinux_bin" \
	 -no-emul-boot \
	 -boot-load-size 4 \
	 -boot-info-table \
	 -eltorito-alt-boot \
	 -e "$boot_efi_img" \
	 -no-emul-boot \
	 -isohybrid-gpt-basdat \
	 -o "$target_iso_path" "$source_iso_path"
 
	# print info to user
	echo "-----"
	echo "Summary"
	echo "Username is: $username"
	echo "Password is: $password"
	echo "Hostname is: $hostname"
	echo "Timezone is: $timezone"
	echo "-----"

	# unset vars
	unset username
	unset password
	unset hostname
	unset timezone
	unset pwdhash
	unset seed_file

}

build-iso "$@"
exit
if expr match "${1}" "^http"; then
	build-iso "$@"
else

	if [ -n "$*" ]; then
		eval "$*" # execute arguments
	else
		if [ `which "$0"` = "$SHELL" ]; then
			echo Function build-iso is loaded into the shell environment
		fi
	fi
fi