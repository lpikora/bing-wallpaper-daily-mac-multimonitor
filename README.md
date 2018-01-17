# Bash Script for download and set Bing Daily Wallpaper on all monitors for macOS

## Run script
First add execute rights to script file. Run `chmod +x bing-wallpaper.sh` in terminal.

Executing `./bing-wallpaper.sh` in terminal downloads today's Bing Wallpaper image to `your-home/Pictures/bing-wallpapers/` and sets it as a wallpaper on all your connected monitors.

## Set wallpaper automaticly every day
You can periodically run the script using cron.

Place script in `your-home/bin/bing-wallpaper-daily-mac-multimonitor/bing-wallpaper.sh`

Run `crontab -e` in terminal and edit text to

```
MAILTO=""
# min hour mday month wday command
*/30 * * * * cd ~/bin/bing-wallpaper-daily-mac-multimonitor && ./bing-wallpaper.sh
```

This will run script every 30 minutes (but download new image only when it change).
