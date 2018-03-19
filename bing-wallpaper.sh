#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

readonly SCRIPT=$(basename "$0")
readonly VERSION='1.0.0'
readonly RESOLUTIONS=(1920x1200 1920x1080 800x480 400x240)

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
  -n --filename <file name>      The name of the downloaded picture. Defaults to
                                 the upstream name.
  -p --picturedir <picture dir>  The full path to the picture download dir.
                                 Will be created if it does not exist.
                                 [default: $HOME/Pictures/bing-wallpapers/]
  -r --resolution <resolution>   The resolution of the image to retrieve.
                                 Supported resolutions: ${RESOLUTIONS[*]}
  -h --help                      Show this screen.
  --version                      Show version.
EOF
}

print_message() {
    if [ ! "$QUIET" ]; then
        printf "%s\n" "${1}"
    fi
}

# Defaults
PICTURE_DIR="$HOME/Pictures/bing-wallpapers/"
RESOLUTION="1920x1200"

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
        -n|--filename)
            FILENAME="$2"
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

# Create picture directory if it doesn't already exist
mkdir -p "${PICTURE_DIR}"

wget -q --spider http://google.com
if [ $? -eq 0 ]; then
    # Parse bing.com and acquire picture URL(s)
    urls=( $(curl -sL $PROTO://www.bing.com | \
        grep -Eo "url:'.*?'" | \
        sed -e "s/url:'\([^']*\)'.*/$PROTO:\/\/bing.com\1/" | \
        sed -e "s/\\\//g" | \
        sed -e "s/\([[:digit:]][[:digit:]]*x[[:digit:]][[:digit:]]*\)/$RESOLUTION/") )

    for p in "${urls[@]}"; do
        filename=$(echo "$p"|sed -e "s/.*\/\(.*\)/\1/")
        if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$filename" ]; then
            find $PICTURE_DIR -type f -iname \*.jpg -delete
            print_message "Downloading: $filename..."
            curl -Lo "$PICTURE_DIR/$filename" "$p"
        else
            print_message "Skipping download: $filename..."
        fi
        osascript -e 'tell application "System Events" to tell every desktop to set picture to "'$PICTURE_DIR/$filename'"'
    done

else
    print_message "No internet connection..."
fi


