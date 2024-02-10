#!/bin/sh

#
# lHelo Wodrl
#
debug() {
  command="$1"
  version="$2"
  moodlepath="$(pwd)/moodle-$version"
  projectname="$(format_version_name "$version")"
  echo "version: $version"
  echo "command: $command"
  echo "moodlepath: $moodlepath"
  echo "projectname: $projectname"
}

#
# Prints helpful commands
#
help() {
  printf "Usage: ./moodoc.sh [COMMAND] [VERSION]\n\n"
  printf "Commands:\n"
  printf "  start          Start a Moodle container with the specified version.\n"
  printf "  stop           Stop the running Moodle container.\n\n"
  printf "Examples:\n"
  printf "  run 4.3.3      Start a Moodle container with version 4.3.3\n"
  printf "  stop           Stop the running Moodle container\n\n"
  printf "You can also run with NPM if installed:\n"
  printf  "  npm run moodoc start 4.1.3\n"
  printf  "  npm run moodoc stop 4.1.3\n\n"
}

#
# Docker compose names don't support "."s but we want to keep the 1.2.3 naming convention for dirs (len of 3 only)
#
format_version_name() {
    version="$1"
    result=""

    # Iterate over each character in the version string
    while [ -n "$version" ]; do
        char="${version%"${version#?}"}"
        version="${version#?}"

        # Skip the dot character
        if [ "$char" != "." ]; then
            result="${result}${char}"
        fi
    done

    # Trim or pad the version number to ensure it is 3 characters long.
    # We have to do this, or the port will be invalid. This creates potential collisions.
    length="${#result}"
    if [ "$length" -gt 3 ]; then
        result="${result%"${result#???}"}"
    elif [ "$length" -lt 3 ]; then
        result="$(printf "%03d" "$result")"
    fi

    echo "$result"
}

#
# Downloads moodle from moodle's github
#
download_moodle() {
    version="$1"
    moodlepath="$2"
    versionURI="https://codeload.github.com/moodle/moodle/zip/refs/tags/v$version"

    # Check if Moodle directory already exists
    if [ -d "$moodlepath" ]; then
        echo "Moodle version $version already exists in directory $moodlepath. Skipping download."
        return
    fi

    # No early return, onward!
    echo "Downloading Moodle version $version..."

    # Download Moodle zip file
    if curl -L --output "moodle-$version.zip" --silent --fail "$versionURI"; then
        echo "Moodle version $version zip file downloaded successfully."
    else
        echo "Failed to download Moodle version $version zip file from $versionURI."
        return
    fi

    # Check if the downloaded zip file exists
    if [ -f "moodle-$version.zip" ]; then
        echo "Downloaded moodle-$version.zip. Extracting..."

        if unzip -q "moodle-$version"; then
                echo "Moodle version $version zip file extracted to dir moodle-$version."
            else
                echo "Failed to extract Moodle version $version zip file, please unzip the file and try again."
                return
            fi
    else
        echo "Download failed, please check that the version exists."
        return
    fi

    # Check if the Moodle directory is created
    if [ -d "moodle-$version" ]; then
        echo "Moodle version $version directory created successfully."
        # Cleanup Moodle zip file
        rm "moodle-$version.zip"
        echo "Moodle version $version zip file cleaned up."
    else
        echo "Failed to create Moodle version $version directory. Please create the directory and run again."
        return
    fi
}

#
# Function to start Moodle with a specific version and wait for database
#
run_moodle() {
    version="$1"
    projectname="$2"
    moodlepath="$3"

    # Check if Moodle directory exists
    if [ ! -d "$moodlepath" ]; then
        echo "Moodle directory not found."
        download_moodle "$version" "$moodlepath"
    fi

    cp config.docker-template.php "$MOODLE_DOCKER_WWWROOT"/config.php
    bin/moodle-docker-compose -p "moodle$projectname" up -d
    bin/moodle-docker-wait-for-db
}

#
# Function to stop Moodle with a specific version
#
stop_moodle() {
    bin/moodle-docker-compose -p "moodle$projectname" down
}

#
# Sets environment variables
#
set_envs() {
  version=$1
  moodlepath="$(pwd)/moodle-$version"
  projectname="$(format_version_name "$version")"
  export COMPOSE_PROJECT_NAME="moodle$projectname"
  export MOODLE_DOCKER_WEB_PORT="50${projectname}"
  export MOODLE_DOCKER_WWWROOT=$moodlepath
  export MOODLE_DOCKER_DB=pgsql
}

#
# Main function to handle user input
#
main() {
    version=$2
    moodlepath="$(pwd)/moodle-$version"
    projectname="$(format_version_name "$version")"

    case "$1" in
        "start")
            set_envs "$version"
            run_moodle "$2" "$projectname" "$moodlepath"
            ;;
        "stop")
            set_envs "$version"
            stop_moodle "$projectname"
            ;;
        "help")
            help
            ;;
        "-help")
            help
            ;;
        "--help")
            help
            ;;
        "debug")
            debug "$1" "$2" "$version"
            ;;
        *)
            echo "Unknown command. ./moodoc.sh help for options"
            ;;
    esac
}

#
# Call the main function with the provided arguments
#
main "$@"