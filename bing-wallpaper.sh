#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

# Defaults
SCRIPT=$(basename "$0")
readonly SCRIPT
readonly VERSION='1.4.0'
PICTURE_DIR="$HOME/Pictures/bing-wallpapers/"
RESOLUTIONS=(1920x1200 1920x1080 1024x768 1280x720 1366x768 UHD)
MONITOR="0" # 0 means all monitors
PLIST_FILE="$HOME/Library/LaunchAgents/com.bing-wallpaper-daily-mac-multimonitor"
AUTO_UPDATE_NAME="default"
ARGS=$@
DAY='0'
PROTO='http'

usage() {
cat <<EOF
Usage:
  $SCRIPT [options]
  $SCRIPT -h | --help
  $SCRIPT --version

Options:
  enable-auto-update             Enable automatic update of wallpapers every day
                                 the picture if the filename already exists.
  disable-auto-update            Disable automatic update of wallpapers every day
                                 the picture if the filename already exists.
  info                           Show description of current wallpaper.
  --auto-update-name <name>      Name of your auto update when enabling/disabling
                                 Using custom name enables setting multiple automatic update configurations.
                                 Eg. Set on monitor 1 todays wallpaper and on monitor 2 wallpaper from yesterday
  -f --force                     Force download of picture. This will overwrite
                                 the picture if the filename already exists.
  -s --ssl                       Communicate with bing.com over SSL.
  -q --quiet                     Do not display log messages.
  -c --country <coutry-tag>      Specify market country/region eg. en-US, cs-CZ
                                 Pictures may be different for markets on some days.
                                 See full list of countries on https://learn.microsoft.com/en-us/previous-versions/bing/search/dd251064(v=msdn.10)
  -d --day <number>              Day for which you want to get the picture.
                                 0 is current day, 1 is yesterday etc.
                                 Default is 0.
  -n --filename <file name>      The name of the downloaded picture. Defaults to
                                 the upstream name.
  -p --picturedir <picture dir>  The full path to the picture download dir.
                                 Will be created if it does not exist.
                                 [default: $HOME/Pictures/bing-wallpapers/]
  -r --resolution <resolution>   The resolution of the image to retrieve.
                                 Supported resolutions: ${RESOLUTIONS[*]}
  --resolutions <resolutions>    The resolutions of the image try to retrieve.
                                 eg.: --resolutions "1920x1200 1920x1080 UHD"
  -m --monitor <num>             Set wallpaper only on certain monitor (1,2,3...)
  --all-desktops-experimental    Set wallpaper on all desktops
                                 Fixing osascript bug when wallpaper is not set for Desktop 2.
                                 Known issue: Minimized apps are removed from Dock.
                                 If something goes wrong delete Library/Application Support/Dock/desktoppicture.db
                                 and restart your Mac.
  -h --help                      Show this screen.
  --version                      Show version.
EOF
}

create_plist_in_users_agents_folder() {
    local SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/$(basename "${BASH_SOURCE:-$0}")
    local REST_ARGS=$(echo "$ARGS" | sed -e "s/enable-auto-update//")

    if [ $RUN_USING_NPX ]; then
        local COMMANDS="<string>source ~/.bashrc && npx --yes bing-wallpaper-daily-mac-multimonitor@latest $REST_ARGS</string>"
    else
        local COMMANDS="<string>$SCRIPT_PATH $REST_ARGS</string>"
    fi

    cat > $PLIST_FILE <<- EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.bing-wallpaper-daily-mac-multimonitor.plist</string>
    <key>OnDemand</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
		<string>-c</string>
        $COMMANDS
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardErrorPath</key>
    <string>/tmp/bing-wallpaper-daily-mac-multimonitor-plist.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/bing-wallpaper-daily-mac-multimonitor-plist.out</string>
    <key>StartInterval</key>
    <integer>1800</integer>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOM

    launchctl unload -w $PLIST_FILE 2>/dev/null
    launchctl load -w $PLIST_FILE
}

remove_plist_in_users_agents_folder() {
    launchctl unload -w "$PLIST_FILE" 2>/dev/null
    rm "$PLIST_FILE"
}

show_info_text() {
    # Parse HPImageArchive API and acquire picture BASE URL
COPYRIGHT=$(cat "$PICTURE_DIR/info.xml" | \
    grep -Eo "<copyright>.*<\/copyright>")
COPYRIGHT=$(echo "$COPYRIGHT" | sed -e "s/<copyright>//")
COPYRIGHT=$(echo "$COPYRIGHT" | sed -e "s/<\/copyright>//")
echo $COPYRIGHT
}

print_message() {
    if [ ! "$QUIET" ]; then
        printf "%s\n" "$(date): ${1}"
    fi
}

download_image_curl () {
    local RES=$1
    FILEURLWITHRES="${FILEURL}_${RES}.jpg"
    print_message "New file name is $FILEURLWITHRES"
    FILENAME=${FILEURLWITHRES/\/th\?id=/}
    FILENAME_LOCAL="${AUTO_UPDATE_NAME}-${FILENAME}"
    FILEWHOLEURL="$PROTO://bing.com/$FILEURLWITHRES"
    print_message "Final download URL is $FILEWHOLEURL"

    if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$FILENAME_LOCAL" ]; then
        find $PICTURE_DIR -type f -iname $AUTO_UPDATE_NAME-\*.jpg -delete
        print_message "Downloading: $FILENAME..."
        curl --fail $CURL_QUIET -Lo "$PICTURE_DIR/$FILENAME_LOCAL" "$FILEWHOLEURL"
        curl --fail $CURL_QUIET -Lo "$PICTURE_DIR/info.xml" "$BING_HP_IMAGE_ARCHIVE_URL"
        if [ "$?" == "0" ]; then
            FILEPATH="$PICTURE_DIR/$FILENAME_LOCAL"
            return
        fi

        FILEPATH=""
        return
    else
        print_message "Skipping download: $FILENAME_LOCAL..."
        FILEPATH="$PICTURE_DIR/$FILENAME_LOCAL"
        DOWNLOAD_SKIPPED=true
        return
    fi
}

set_wallpaper () {
    local FILEPATH=$1
    local MONITOR=$2

    if [ "$MONITOR" -ge 1 ] 2>/dev/null; then
        print_message "Setting wallpaper for monitor: $MONITOR"
        osascript - << EOF
            set tlst to {}
            tell application "System Events"
                set tlst to a reference to every desktop
                set picture of item $MONITOR of tlst to "$FILEPATH"
            end tell
EOF
    else
        print_message "Setting wallpaper for all monitors through System Events"
        osascript -e 'tell application "System Events" to tell every desktop to set picture to "'$FILEPATH'"'
    fi
}

set_wallpaper_experimental () {
    print_message "Setting wallpaper using experimental option: updating the Dock SQLite DB directly"
    local db_file="Library/Application Support/Dock/desktoppicture.db"
    local db_path="$HOME/$db_file"

    # Put the image path in the database
    local sql="insert into data values(\"$FILEPATH\"); "
    sqlite3 "$db_path" "$sql"

    # Get the index of the new entry
    local sql="select max(rowid) from data;"
    local new_entry=$(sqlite3 "$db_path" "$sql")
    local new_entry=$(echo $new_entry|tr -d '\n')

    # Get all picture ids (monitor/space pairs)
    local sql="select rowid from pictures;"
    local pictures_string=$(sqlite3 "$db_path" "$sql")

    local IFS=$'\n'
    local pictures=($pictures_string)

    # Clear all existing preferences
    local sql="select max(rowid) from data; delete from preferences; "

    for pic in "${pictures[@]}"
    do
        if [ "$pic" ]; then
            local sql+="insert into preferences (key, data_id, picture_id) "
            local sql+="values(1, $new_entry, $pic); "
        fi
    done

    sqlite3 "$db_path" "$sql"

    killall "Dock"
}

# Option parsing
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        enable-auto-update)
            ENABLE_AUTOMATIC_UPDATE=true
            ;;
        disable-auto-update)
            DISABLE_AUTOMATIC_UPDATE=true
            ;;
        info)
            INFO=true
            ;;
        --auto-update-name)
            AUTO_UPDATE_NAME="$2"
            shift
            ;;
        -r|--resolution)
            RESOLUTION="$2"
            shift
            ;;
        -p|--picturedir)
            PICTURE_DIR="$2"
            shift
            ;;
        -c|--country)
            COUNTRY="&mkt=$2"
            shift
            ;;
        -d|--day)
            DAY="$2"
            shift
            ;;
        -n|--filename)
            FILENAME="$2"
            shift
            ;;
        -m|--monitor)
            MONITOR="$2"
            shift
            ;;
        -f|--force)
            FORCE=true
            ;;
        -s|--ssl)
            PROTO='https'
            ;;
        -q|--quiet)
            QUIET=true
            CURL_QUIET='-s'
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --resolutions)
            RESOLUTIONS="$2"
            shift
            ;;
        --all-desktops-experimental)
            EXPERIMENTAL=true
            ;;
        --version)
            printf "%s\n" $VERSION
            exit 0
            ;;
        *)
            (>&2 printf "Unknown parameter: %s\n" "$1")
            usage
            exit 1
            ;;
    esac
    shift
done

# Set options
BING_HP_IMAGE_ARCHIVE_URL="https://www.bing.com/HPImageArchive.aspx?format=xml&idx=${DAY}&n=1${COUNTRY}"
PLIST_FILE="${PLIST_FILE}-${AUTO_UPDATE_NAME}.plist"

PARENT_COMMAND=$(ps -o comm= $PPID)
if [[ "$PARENT_COMMAND" == *"npm exec"* ]]; then
    RUN_USING_NPX=true
    print_message "Script detected that it is running by NPM or NPX"
fi

if [ "$ENABLE_AUTOMATIC_UPDATE" ]; then
# enable update
create_plist_in_users_agents_folder
print_message "Automatic wallpaper update enabled"
exit 1
fi

if [ "$DISABLE_AUTOMATIC_UPDATE" ]; then
# disable update
remove_plist_in_users_agents_folder
print_message "Automatic wallpaper update disabled"
exit 1
fi

if [ "$INFO" ]; then
show_info_text
exit 1
fi

# Create picture directory if it doesn't already exist
mkdir -p "${PICTURE_DIR}"

# Parse HPImageArchive API and acquire picture BASE URL
FILEURL=( $(curl -sL $BING_HP_IMAGE_ARCHIVE_URL | \
    grep -Eo "<urlBase>.*?</urlBase>") )
FILEURL=$(echo "$FILEURL" | sed -e "s/<urlBase>//")
FILEURL=$(echo "$FILEURL" | sed -e "s/<\/urlBase>//")

if [ $RESOLUTION ]; then
    download_image_curl $RESOLUTION
    if [ "$FILEPATH" ]; then
        if [ "$EXPERIMENTAL" ]; then
            if [ ! "$DOWNLOAD_SKIPPED" ]; then
                set_wallpaper_experimental $FILEPATH
            fi
        else
            set_wallpaper $FILEPATH $MONITOR
        fi
    fi
    exit 1
fi

for RESOLUTION in "${RESOLUTIONS[@]}"
    do
        download_image_curl $RESOLUTION
        if [ "$FILEPATH" ]; then
            if [ "$EXPERIMENTAL" ]; then
                if [ ! "$DOWNLOAD_SKIPPED" ]; then
                    set_wallpaper_experimental $
                fi
            else
                set_wallpaper $FILEPATH $MONITOR
            fi
            exit 1
        fi
    done
