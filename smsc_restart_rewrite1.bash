#!/bin/env bash

set -o errexit
set -o nounset
set -eu -o pipefail

#set -x
#trap read debug

#################################################################################
#
#Run example: ./smsc_restart.bash t -f
#File:        ./smsc_restart.bash
#Date:        2022APR26
#Author:      Fabrizio Regalli with input from William Blair
#Contact:     williamblair333@gmail.com
#Tested on:   Debian 10

#This script is intended to do the following:
#
# This script covers following errors cases:

# [CER]-[TER] smsc error: pool_timeout
# [CER]-[TER] cer-smsc-0x: TCAP VM ACULAB PROCESS is CRITICAL
# [CER]-[TER] SMSC error: link_not_available

# It has been created with this schema:
# cer-smsc-01 -> cer-smsc-05 - cer-aculab-01
# cer-smsc-02 -> cer-smsc-06 - cer-aculab-02
# ter-smsc-01 -> ter-smsc-03 -> ter-aculab-01
# ter-smsc-02  -> ter-smsc-04 -> ter-aculab-02
# Additional info: https://kaleyra.atlassian.net/wiki/spaces/INFOPS/pages/1242333229/SMSC+ACULAB#SMSC-TCAP-ERRORS%3A

# In order to work, from your user <name.surname> generate the ssh key on the following servers:
# cer-smsc-05, cer-smsc-06, ter-smsc-03, and ter-smsc-04 with the command
# ssh-keygen -t rsa
# and copy it (id_rsa.pub) into root@{ter,cer}-aculab-0{1,2} inside root/.ssh/authorized_keys
#################################################################################

function Help() 
{
    # Display Help
    echo "SMSC Restart Script"
    echo
    echo "usage: $0 <env> [-f]" 
    echo "  env: C for CER or T for TER"
	echo "       -f (force): restart without any check"
	echo
}
#################################################################################

function cer_service_restart() 
{
    echo "Found timeout, fail or wrong number of tcapsrv processes or -f" \
    "option has been specified. Stopping $cer_smsc_server1."

    echo cd /etc/sv/smsc/; echo sv stop smsc
    cd /etc/sv/smsc/ ; sudo sv stop smsc
    echo "Connecting to $cer_acu_server1 and killing tcapsrv"
    
    # Connect directly aculab machine on port 2200
    ssh root@"$cer_smsc_server2" -p 2200 "killall -9 tcapsrv"
    
        echo "Start smsc services.."
        echo cd /etc/sv/smsc/ ; echo sv start smsc
                cd /etc/sv/smsc/ ; sudo sv start smsc
        echo "Restart completed on $cer_smsc_server1"
}
#################################################################################

function cer_error_check() 
{
    cer_smsc_server1=$1
    cer_smsc_server2=$2
    cer_acu_server1=$3

    echo "Executing restart of CER smsc..."
    
    ssh "$cer_smsc_server1"
    
    PC=$(ssh root@"$cer_smsc_server2" -p 2200 ps ax | grep tcapsrv | grep -v grep |wc -l)
    PC=2
    if ([[ $(sudo tail -50 /etc/sv/smsc/log/main/current | \
    grep -P "fail | \[error\] CRASH REPORT Process") == "" ]] && \
    [[ $PC -eq 2 ]]); then
    
        echo "No fail or timeout found on $cer_smsc_server1. Processes on aculab are" \
        "two. Not restarted. Exiting"
        exit 1
    
    else
        cer_service_restart
    fi
}
#################################################################################

function main() 
{
    while getopts ":c:t:f:h" option;
      do
          case "$option" in
              c)  cer_error_check cer-smsc-05 cer-smsc-01 cer-aculab-01
                  cer_error_check cer-smsc-06 cer-smsc-02 cer-aculab-02 ;;
                  
              t)  cer_error_check ter-smsc-03 ter-smsc-01 ter-aculab-01
                  cer_error_check ter-smsc-04 ter-smsc-02 ter-aculab-02 ;;
                  
              f)  cer_service_restart ter-smsc-03 ter-smsc-01 ter-aculab-01
                  cer_service_restart ter-smsc-04 ter-smsc-02 ter-aculab-02 ;;
                  
              h)  Help  ;;
              *)  echo "No valid answer, exiting.."
                  exit 2
         esac
    done
}
#################################################################################

main "$@"
#################################################################################
