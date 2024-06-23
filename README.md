# GenesisWatch

Welcome to GenesisWatch, a monitoring tool designed to keep track of file creation times. The script, `genwatch`, manages and sets extended attributes for files and directories, ensuring that each entity's earliest known timestamp (birth or modification) is accurately recorded and maintained. This was created out of my frustration with Linux handling the creation timestamp of files.

## ⚠️ Caution

**Important:** This script is primarily designed for personal use and has not been extensively tested in other environments. It has not been throughly tested on different environments, so I'm unsure how much overhead this script creates on large I/O operations or large amounts of files and directories. Please use it at your own risk.

## Features

- **Real-Time Monitoring**: Tracks file creations and movements within specified directories.
- **Attribute Management**: Sets and updates the `user.creation_time` attribute based on the earliest timestamp of the file (birth time or modified time).
- **Flexible Scanning Options**: Allows optional full directory scans at startup to update all files and directories with accurate timestamps.
- **Concurrent Processing**: Capable of performing initial scans in the background for enhanced performance.

## Prerequisites

Before installing and running GenesisWatch, ensure your system meets the following requirements:
- A Unix-like operating system (tested on Arch Linux)
- Bash shell environment
- Tools: `stat`, `xattr`, `inotify-tools` must be installed

## Installation
1. Install `inotify-tools` package
    ```
    pacman -S inotify-tools
    ```
1. Clone the GenesisWatch repository:
   ```
   git clone https://github.com/Floresce/GenesisWatch.git
   ```
2. Change to the GenesisWatch directory:
    ```
    cd GenesisWatch
    ```
3. Make the `genwatch` script executable:
    ```
    chmod +x genwatch.sh
    ```

## Usage

To start monitoring a directory, you can run the `genwatch` script with or without the initial scan option:
```
./genwatch.sh [-s] <directory_to_monitor>
```

### Command Line Options
- `-s`: Conducts a full scan of the specified directory upon startup, setitng the creation time attribute for all existing fiels and directories

### Example Commands
- Monitor a directory without an initial scan:
```
./genwatch.sh /path/to/directory
```
- Monitor a directory with an initial scan:
```
./genwatch.sh -s /path/to/directory
```
- Get the `user.creation_time` attribute in a readable date format
```
date -d @$(getfattr -n user.creation_time --only-values <file>)
```
- Remove the `user.creation_time`
```
setfattr -x user.creation_time <file>
```