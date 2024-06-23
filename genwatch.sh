#!/bin/bash

INITIAL_SCAN=false

# Check for the scan flag
while getopts ":s" option; do
    case $option in 
        s) INITIAL_SCAN=true ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
    esac
done

shift $((OPTIND-1))

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_to_monitor>"
    exit 1
fi

# Directory to monitor
WATCH_DIR=$1

# Ensure WATCH_DIR exists
if [ ! -d "$WATCH_DIR" ]; then
    echo "Directory $WATCH_DIR does not exist. Exiting."
    exit 1
fi

# Function to get the birth time of a file
get_birth_time() {
    local file=$1
    stat --format '%W' "$file"
}

# Function to get the modified time of a file
get_modified_time() {
    local file=$1
    stat --format '%Y' "$file"
}

# Function to GET the extended attribute creation time
get_xattr_creation_time() {
    local file=$1
    getfattr -n user.creation_time --only-values "$file" 2>/dev/null
}

# Function to SET the extended attribute creation time
set_xattr_creation_time() {
    local file=$1
    local birth_time=$2
    setfattr -n user.creation_time -v "$birth_time" "$file"
}

# Function to process new file or directory
process_new_file() {
    local NEW_FILE=$1
    xattr_exists=$(get_xattr_creation_time "$NEW_FILE")

    birth_time=$(get_birth_time "$NEW_FILE")
    modified_time=$(get_modified_time "$NEW_FILE")

    echo "Processing new file: $NEW_FILE"

    if [ -n "$xattr_exists" ]; then
        echo "NOTE: Creation time already set, skipping..."
        return
    fi

    # Check which is earlier between creation and modified time
    if [ "$modified_time" -lt "$birth_time" ]; then
        earliest_time="$modified_time"
        echo "NOTE: modified time is earlier than birth time"
    else
        earliest_time="$birth_time"
        echo "NOTE: birth time is earlier than modified time"
    fi

    # Check if the file already has the user.creation_time attribute
    xattr_creation_time=$(get_xattr_creation_time "$NEW_FILE")

    if [ -z "$xattr_creation_time" ]; then
        # If the attribute doesn't exist, set it
        set_xattr_creation_time "$NEW_FILE" "$earliest_time"
        echo "CREATE: set new creation time attribute"
    else
        # If the birth time is newer than the xattr, keep the xattr
        if [ "$earliest_time" -lt "$xattr_creation_time" ]; then
            # Update the xattr with the birth time
            set_xattr_creation_time "$NEW_FILE" "$earliest_time"
            echo "UPDATE: updated creation time attribute"
        else
            echo "NOTE: Birth time is newer than existing xattr. Keeping existing xattr."
        fi
    fi
}

export -f get_birth_time
export -f get_modified_time
export -f get_xattr_creation_time
export -f set_xattr_creation_time
export -f process_new_file

# Initial scan of the directory
if [ "$INITIAL_SCAN" = true ]; then
    echo "Performing initial scan of the directory..."
    find "$WATCH_DIR" -type f -o -type d | while read -r file; do
        process_new_file "$file" &
    done
else
    echo "Skipping initial scan."
fi

# Monitor the directory for file and directory creation
inotifywait -m -r -e create -e moved_to --format '%w%f' "$WATCH_DIR" | while read -r NEW_FILE
do
  process_new_file "$NEW_FILE"
done