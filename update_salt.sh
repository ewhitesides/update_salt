#!/bin/bash

#EXAMPLE CALLS
#sudo ./update_salt.sh 'myserver'
#sudo ./update_salt.sh '*dev*'
#sudo ./update_salt.sh 'G@osmajorrelease:8 and G@os:CentOS'
#nohup sudo ./update_salt.sh 'N@NodeGroup1 and G@osmajorrelease:[7-8]' &

get_minions_list () {
    #filter by Windows or Linux
    filter="$1"

    #get list of minions that are pingable and require updating
    readarray -t requires_update < <(
        salt-run manage.versions --out=json |
            jq -r '.["Minion requires update"] | keys[]'
    )

    #get list of minions that are not busy with an existing salt job
    readarray -t not_busy < <(
        salt -C "$target and $filter" saltutil.running --hide-timeout --out=json |
            jq -r 'to_entries[] | select(.value==[]) | .key'
    )

    #get intersection of the above two arrays to produce list of updateable minions
    comm -12 <(printf '%s\n' "${requires_update[@]}" | LC_ALL=C sort) <(printf '%s\n' "${not_busy[@]}" | LC_ALL=C sort) |
        awk 'NR > 1 { printf(", ") } {printf "%s",$0}'
}

#check if running as root user
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root\n"
   exit 1
fi

#variables
target="$1"

#windows
windows_list=$(get_minions_list 'G@kernel:Windows' 2>/dev/null)
if [ ! -z "$windows_list" ]; then
    #variables for windows install source/destination
    setup_exe='Salt-Minion-Latest-Py3-AMD64-Setup.exe'
    install_src="https://repo.saltstack.com/windows/$setup_exe"
    master_dst="/srv/salt/states/scripts/$setup_exe"
    master_dst_url="salt://scripts/$setup_exe"
    minion_dst="C:\\$setup_exe"

    #download setup.exe to master at scripts location
    wget --quiet "$install_src" -O "$master_dst"

    #copy setup.exe to minions
    salt --batch-size 5 -L "$windows_list" cp.get_file "$master_dst_url" "$minion_dst"

    #rm setup.exe after copying to minions
    rm "$master_dst"

    #update
    update_cmd="Start-Process -Wait -FilePath ${minion_dst} -ArgumentList '/S';"
    remove_cmd="Remove-Item -Path ${minion_dst}"
    salt --batch-size 5 -L "$windows_list" cmd.powershell "$update_cmd $remove_cmd"
fi

#linux
linux_list=$(get_minions_list 'G@kernel:Linux' 2>/dev/null)
if [ ! -z "$linux_list" ]; then
    salt --batch-size 5 -L "$linux_list" pkg.upgrade salt
fi
