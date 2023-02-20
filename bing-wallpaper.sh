#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

readonly SCRIPT=$(basename "$0")
readonly VERSION='1.2.1'
RESOLUTIONS=(1920x1080 1920x1200 1024x768 1280x720 1366x768 UHD)
MONITOR="0" # 0 means all monitors

usage() {
cat <<EOF
Usage:
  $SCRIPT [options]
  $SCRIPT -h | --help
  $SCRIPT --version

Options:
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

print_message() {
    if [ ! "$QUIET" ]; then
        printf "%s\n" "$(date): ${1}"
    fi
}

download_image_curl () {
    local RES=$1
    FILEURLWITHRES="${FILEURL}_${RES}.jpg"
    echo $FILEURLWITHRES
    FILENAME=${FILEURLWITHRES/th\?id=/}
    FILEWHOLEURL="$PROTO://bing.com/$FILEURLWITHRES"

    if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$FILENAME" ]; then
        find $PICTURE_DIR -type f -iname \*.jpg -delete
        print_message "Downloading: $FILENAME..."
        curl --fail -Lo "$PICTURE_DIR/$FILENAME" "$FILEWHOLEURL"
        if [ "$?" == "0" ]; then
            FILEPATH="$PICTURE_DIR/$FILENAME"
            return
        fi

        FILEPATH=""
        return
    else
        print_message "Skipping download: $FILENAME..."
        FILEPATH="$PICTURE_DIR/$FILENAME"
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
        osascript -e 'tell application "System Events" to tell every desktop to set picture to "'$FILEPATH'"'
    fi
}

set_wallpaper_experimental () {
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

# Defaults
PICTURE_DIR="$HOME/Pictures/bing-wallpapers/"

# Option parsing
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -r|--resolution)
            RESOLUTION="$2"
            shift
            ;;
        -p|--picturedir)
            PICTURE_DIR="$2"
            shift
            ;;
        -c|--country)
            COUNTRY="$2"
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
            SSL=true
            ;;
        -q|--quiet)
            QUIET=true
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
            shift
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
[ $QUIET ] && CURL_QUIET='-s'
[ $SSL ]   && PROTO='https'   || PROTO='http'
[ $DAY ]   && IDX=$DAY   || IDX='0'
BING_HP_IMAGE_ARCHIVE_URL="https://www.bing.com/HPImageArchive.aspx?format=xml&idx=${IDX}&n=1"
[ $COUNTRY ]   && BING_HP_IMAGE_ARCHIVE_URL="${BING_HP_IMAGE_ARCHIVE_URL}&mkt=${COUNTRY}"

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
            set_wallpaper_experimental $FILEPATH
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
                set_wallpaper_experimental $FILEPATH
            else
                set_wallpaper $FILEPATH $MONITOR
            fi
            exit 1
        fi
    done
