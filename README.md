# Bash Script for download and set Bing Daily Wallpaper on all monitors for macOS

![alt text](https://raw.githubusercontent.com/lpikora/bing-wallpaper-daily-mac-multimonitor/images/example-bing-animation.gif)

## Run script

First add execute rights to script file. Run `chmod +x bing-wallpaper.sh` in terminal.

Executing `./bing-wallpaper.sh` in terminal downloads today's Bing Wallpaper image to `your-home/Pictures/bing-wallpapers/` and sets it as a wallpaper on all your connected monitors.

## Set wallpaper automaticly every day

You can periodically run the script using cron.

Place script in `your-home/bin/bing-wallpaper-daily-mac-multimonitor/bing-wallpaper.sh`

In terminal:

```sh
crontab -e
```

or use nano for editing crontab

In terminal:

```sh
export EDITOR=nano && crontab -e
```

and paste crontab script:

```
MAILTO=""
# min hour mday month wday command
*/30 * * * * cd ~/bin/bing-wallpaper-daily-mac-multimonitor && ./bing-wallpaper.sh
```

This will run script every 30 minutes (but download new image only when it change).

## Download wallpaper in UHD resolution

Add `-r UHD` parameter after `./bing-wallpaper.sh`

```sh
./bing-wallpaper.sh -r UHD
```
