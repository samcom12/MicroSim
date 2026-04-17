#!/bin/sh

cmake_checker()
{
    echo "**************************************************************"
    echo "Checking for CMake"
    echo "**************************************************************"
    echo ""
    echo "CMake Required version: $1"

    cmake_ver_current=$(cmake --version 2>/dev/null | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+')
    cmake_status=$?

    if [ "$cmake_status" -eq 0 ] && [ -n "$cmake_ver_current" ]; then
        # Compare versions using sort -V
        cmake_ver_min="$1"
        lower=$(printf '%s\n%s\n' "$cmake_ver_min" "$cmake_ver_current" | sort -V | head -1)
        if [ "$lower" = "$cmake_ver_min" ]; then
            echo "CMake version $cmake_ver_current found.  STATUS : OK"
        else
            echo "CMake version $cmake_ver_current found but required version is $1. Please upgrade.  STATUS : WRONG VERSION"
        fi
    else
        echo "CMake not found. Please install CMake $1 or later.  STATUS : NOT FOUND"
    fi
    echo ""
}
