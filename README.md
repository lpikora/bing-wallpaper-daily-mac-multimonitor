# Bash Script for download and set current Bing Daily Wallpaper automatically on all monitors for macOS

![alt text](https://raw.githubusercontent.com/lpikora/bing-wallpaper-daily-mac-multimonitor/images/example-bing-animation.gif)

## How it works?

Script downloads current Bing Daily Wallpaper to `~/Pictures/bing-wallpapers/` and sets it as wallpaper on all your monitors.

## Set wallpaper (dekstop picture) automatically every day

### Using launchd (recommended way)

1. Copy `com.bing-wallpaper-daily-mac-multimonitor.plist` to `~/Library/LaunchAgents/`

2. Copy `bing-wallpaper.sh` to `~/bing-wallpaper.sh`

3. Run `launchctl load -w ~/Library/LaunchAgents/com.bing-wallpaper-daily-mac-multimonitor.plist` in terminal (it can ask for permitions for the first time)

Tip: use `com.bing-wallpaper-daily-mac-multimonitor-uhd.plist`for UHD 4K images

#### How it works?

Script `bing-wallpaper.sh` is run every 30 minutes and checks if there is a new image on Bing.com. New image is downloaded and set as desktop picture on your all monitors.

Optionally you can edit `com.bing-wallpaper-daily-mac-multimonitor.plist` file to run script in different interval or schedule runs on specific time of day. (run `launchctl unload -w ~/Library/LaunchAgents/com.bing-wallpaper-daily-mac-multimonitor.plist` edit plist file and again load it)

For More info about launchd see https://www.launchd.info/ Configuration section.

## Set current Bing.com wallpaper manually

### with npm

(How install use script without npm see `Usage (without npm)` below)

1. First install Node.js https://nodejs.org/en/

2. For getting current Bing Daily Wallpaper to your desktop run in terminal:

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

3. For automatic setup of wallpaper every day contine with instructions below

### without npm

Run `./bing-wallpaper.sh` terminal for a single download of current Bing image.

## Download wallpaper in UHD resolution

Add `-r UHD` parameter after `bing-wallpaper-daily-mac-multimonitor` or `./bing-wallpaper.sh` command:

```sh
bing-wallpaper-daily-mac-multimonitor -r UHD
```

OR

```sh
./bing-wallpaper.sh -r UHD
```

### Daily download of wallpaper using cron

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

