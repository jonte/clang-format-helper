#!/bin/bash

# Wrapper around clang-format, which allows specifying a GLOB expression for
# the files to operate on, as well as show a patch of the changes which would
# be made to the files by applying the clang-format formatting rules

# Add known-good versions here
CLANG_FORMAT_VERSIONS=( "3.5" "3.6" "3.7" )

# No need to change anything below here
CLANG_FORMAT="NOTFOUND"
INPLACE="no"
DIFF="no"
GLOBEXP=

function find_clang_format_command {
    for VERSION in "${CLANG_FORMAT_VERSIONS[@]}"
    do
        COMMAND_NAME="clang-format-$VERSION"
        TMP_CLANG_FORMAT="$(which $COMMAND_NAME)"
        if [ "$TMP_CLANG_FORMAT" != "" ]; then
            echo "Found $COMMAND_NAME"
            CLANG_FORMAT="$TMP_CLANG_FORMAT"
            break
        fi
    done
}

function process_file_in_place {
    local FILE=$1
    local COMMAND="$COMMAND -i $FILE"

    echo "$COMMAND $FILE"
}

function show_diff_of_file {
    local FILE=$1
    local TMP_FILE=$(mktemp)

    $COMMAND $FILE > $TMP_FILE
    diff -Naur $FILE $TMP_FILE

    rm "$TMP_FILE"
}

function process_files_matching_glob {
    local FILES_GLOB=$1
    local COMMAND="$CLANG_FORMAT"


    for FILE in ./$FILES_GLOB
    do
        if [ "$INPLACE" == "yes" ]; then
            process_file_in_place "$FILE"
        fi

        if [ "$DIFF" == "yes" ]; then
            show_diff_of_file "$FILE"
        fi
    done
}

function usage {
    echo "$0 [OPTION] <glob expression>"
    echo ""
    echo "These are the available options:"
    echo "  -i      Edit files in place"
    echo "  -d      Show a diff of the changes made if -i is invoked"
    exit 1
}

while getopts ":id" opt; do
    case $opt in
        i)
            INPLACE="yes"
            ;;
        d)
            DIFF="yes"
            ;;
    esac
done

GLOBEXP=${@:$OPTIND:1}

if [ "$INPLACE" == "yes" ] && [ "$DIFF" == "yes" ]; then
    echo "-i and -d can not be combined"
    usage
fi

if [ -z "${GLOBEXP}" ]; then
    usage
fi

find_clang_format_command
process_files_matching_glob "$GLOBEXP"

if [ "$CLANG_FORMAT" == "NOTFOUND" ]; then
    echo "Could not find clang-format command, is it installed?"
    exit 1
fi
