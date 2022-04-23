# overview

script to update salt on linux and windows minions

# example calls

basically accepts the same parameter that you would normally provide to 'salt -C'

script automatically filters operations for windows and linux machines, so you can provide
a target that possibly includes both

```bash
sudo ./update_salt.sh 'myserver'
sudo ./update_salt.sh '*dev*'
sudo ./update_salt.sh 'G@osmajorrelease:8 and G@os:CentOS'
nohup sudo ./update_salt.sh 'N@NodeGroup1 and G@osmajorrelease:[7-8]' &
```

