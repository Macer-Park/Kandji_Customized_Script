#!/usr/bin/env zsh

################################################################################################
# Created by Matt Wilson | support@kandji.io | Kandji, Inc.
################################################################################################
#
#   Created - 2022-04-28
#   Updated - 2022-11-23 - Matt Wilson
#   Updated - 2023-01-25 - Matt Wilson
#
################################################################################################
# Tested macOS Versions
################################################################################################
#
#   13.2
#   12.6
#   11.7.1
#
################################################################################################
# Software Information
################################################################################################
#
# This Audit and Enforce script is used to ensure that the Watchman Monitoring client
# is installed and running properly. This script is designed to be used as an Audit and
# Enforce script in a Custom App Library item. No modification needed.
#
# Instructions and dependency files can be found in the Kandji knowledge base and
# support github.
#
################################################################################################
# License Information
################################################################################################
#
# Copyright 2023 Kandji, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
################################################################################################

########################################################################################
###################################### VARIABLES #######################################
########################################################################################

# NOTE: this profile only contains managed backgroud settings for macOS 13+
# Change the PROFILE_ID_PREFIX variable to the profile prefix you want to wait on before
# running the installer. The profile prefix below is associated with the Notifications
# payload in the Kandji provided configuration profile.
PROFILE_ID_PREFIX="io.kandji.watchman-monitoring.service-management"

# Make sure that the app name matches the name of the app that will be installed. This
# script will dynamically search for the app in the Applications folder. So there is no
# need to define an app path. The app must install in the /Applications, "/System/
# Applications", or /Library up to 3 sub-directories deep.
APP_NAME="MonitoringClient"

########################################################################################
###################################### MAIN LOGIC ######################################
########################################################################################

# Get build year of OS for different workflows
build_year=$(/usr/bin/sw_vers -buildVersion | cut -c 1,2)

# macOS Ventura(13.0) or newer - this is for the managed background settings profile.
if [[ "${build_year}" -ge 22 ]]; then
    # The profiles variable will be set to an array of profiles that match the prefix in
    # the PROFILE_ID_PREFIX variable
    profiles=$(/usr/bin/profiles show | grep "$PROFILE_ID_PREFIX" | sed 's/.*\ //')

    # If matching profiles are found exit 1 so the installer will run, else exit 0 to
    # wait
    if [[ ${#profiles[@]} -eq 0 ]]; then
        /bin/echo "No profiles with ID $PROFILE_ID_PREFIX were found ..."
        /bin/echo "Will check again at the next Kandji agent check in before moving on ..."
        exit 0
    fi

    /bin/echo "Profile prefix $PROFILE_ID_PREFIX present ..."
fi

# This command looks in /Applications, /System/Applications, and /Library for the
# existance of the app defined in $APP_NAME
installed_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name "$APP_NAME" 2>/dev/null)"

# Validate the path returned in installed_path
if [[ ! -e "${installed_path}/RunClient" ]] || [[ "$APP_NAME" != "$(/usr/bin/basename "$installed_path")" ]]; then
    /bin/echo "$APP_NAME/RunClient not found. Starting installation process ..."
    exit 1
else

    # make sure the clientsettings file exists
    if [[ -f "$installed_path/ClientSettings.plist" ]]; then
        # Get the version of the installed watchman client.
        installed_version=$(/usr/bin/defaults read "$installed_path/ClientSettings.plist" Client_Version 2>/dev/null)

        # make sure we got a version number back
        if [[ $? -eq 0 ]]; then
            /bin/echo "$APP_NAME installed with version $installed_version ..."
            /bin/echo "Install path \"${installed_path}\""
        else
            /bin/echo "$APP_NAME is installed at \"$installed_path\"..."
        fi

        # Get the monitoring client status and report back.
        warning_status="$(/usr/bin/defaults read /Library/MonitoringClient/ClientData/UnifiedStatus.plist CurrentWarning)"

        # Report issue status
        if [[ "$warning_status" -eq 0 ]]; then
            /bin/echo "Monitoring client UnifiedStatus: No issues"
        else
            /bin/echo "Monitoring client UnifiedStatus reported an issue..."
            /bin/echo" UnifiedStatus: $warning_status"
        fi

    else
        /bin/echo "Unable to find Monitoring client settings file..."
    fi
fi

exit 0
