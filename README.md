# Bash Script for download and set Bing Daily Wallpaper on all monitors for macOS

![alt text](https://raw.githubusercontent.com/lpikora/bing-wallpaper-daily-mac-multimonitor/images/example-bing-animation.gif)

## Usage (with npm)

(How install use script without npm see `Usage (without npm)` below)

First install Node.js https://nodejs.org/en/

Then in terminal

```
npx bing-wallpaper-daily-mac-multimonitor
```

OR

```
npm -g install bing-wallpaper-daily-mac-multimonitor
```

then run in terminal

```
bing-wallpaper-daily-mac-multimonitor
```

It will download current bing.com wallpaper to `~/Pictures/bing-wallpapers/` and set as wallpaper on all your monitors.

## Set wallpaper automatically every day

You need to edit crontab in order to run script periodically.

In terminal

```sh
export EDITOR=nano && crontab -e
```

copy and paste crontab script:

```
MAILTO=""
# min hour mday month wday command
*/30 * * * * bing-wallpaper-daily-mac-multimonitor
```

Press `control + x` then `y` and `enter`

This will run script every 30 minutes (but download new image only when it change).

## Download wallpaper in UHD resolution

Add `-r UHD` parameter after `bing-wallpaper-daily-mac-multimonitor` command:

```sh
bing-wallpaper-daily-mac-multimonitor -r UHD
```

## Usage (without npm)

First add execute rights to script file. Run `chmod +x bing-wallpaper.sh` in terminal.

Executing `./bing-wallpaper.sh` in terminal downloads today's Bing Wallpaper image to `your-home/Pictures/bing-wallpapers/` and sets it as a wallpaper on all your connected monitors.

## Set wallpaper automatically every day

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
