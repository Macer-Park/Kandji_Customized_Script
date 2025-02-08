#!/bin/zsh
################################################################################################
# Created by Nicholas McDonald | se@kandji.io | Kandji, Inc. | Product Engineering
################################################################################################
# Created on 03/08/2022
################################################################################################
# Software Information
################################################################################################
# This script is designed to set a firmware password and force a restart
################################################################################################
# License Information
################################################################################################
# Copyright 2022 Kandji, Inc.
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

#Specify your desired firmware password
firmwarePasswd="FirmwarePasswordHere"

#Specify the number of seconds before the end user will be forced to restart (This interaction occurs via the Kandji menu bar app similar to other forced restarts) 
rebootDelayInSeconds="1800"

#Do not modify below this line

firmwarePasswdStatus=$(/usr/sbin/firmwarepasswd -check | /usr/bin/awk 'FNR == 1 {print $3}' )

if [ "${firmwarePasswdStatus}" = "Yes" ]; then
	echo "Firmware password is already enabled..."
	exit 0
fi

escapedFirmwarePasswd=$(echo ${firmwarePasswd} | /usr/bin/python -c "import re, sys; print(re.escape(sys.stdin.read().strip()))")

setCommand=$(/usr/bin/expect<<EOF
spawn /usr/sbin/firmwarepasswd -setpasswd
expect {
	"Enter new password:" {
		send "${escapedFirmwarePasswd}\r"
		exp_continue
	}

	"Re-enter new password:" {
		send "${escapedFirmwarePasswd}\r"
		exp_continue
	}
}
EOF
)

if [[ "${setCommand}" = *"Must restart before changes will take effect"* ]]; then 
	echo "Firmware Password set changes will take affect after reboot"
	/usr/local/bin/kandji reboot --delaySeconds ${rebootDelayInSeconds}
	exit 0
else
	echo "Firmware password was not set... an unknown error occured"
	exit 1
fi