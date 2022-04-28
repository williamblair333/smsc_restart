#!/bin/env bash
set -o errexit
set -o nounset
set -eu -o pipefail
#set -x
#trap read debug
#################################################################################
#
#Run example: ./smsc_restart.bash -c c
#Run example: ./smsc_restart.bash -c f
#Run example: ./smsc_restart.bash -t c
#Run example: ./smsc_restart.bash -t f
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
# Additional info: 
#https://kaleyra.atlassian.net/wiki/spaces/INFOPS/pages/1242333229/SMSC+ACULAB#SMSC-TCAP-ERRORS%3A
#
# In order to work, from your user <name.surname> generate the ssh key on the following servers:
# cer-smsc-05, cer-smsc-06, ter-smsc-03, and ter-smsc-04 with the command
# ssh-keygen -t rsa
# and copy it (id_rsa.pub) into root@{ter,cer}-aculab-0{1,2} inside root/.ssh/authorized_keys
#################################################################################
clear
touch $HOME/.hushlogin
flag=""

function Help() 
{
    # Display Help
    echo "SMSC Restart Script"
    echo
    echo "usage: $0 -c c"
    echo "usage: $0 -c f"
    echo "usage: $0 -t c"
    echo "usage: $0 -t f"
    echo "  env: c for CER or t for TER"
	echo "       argument c (check): check and restart if x errors in log"
	echo "       argument f (force): restart without any check"
	echo
}
#################################################################################

function cer_service_restart() 
{
    echo "Found timeout, fail or wrong number of tcapsrv processes or f option has been specified. Stopping $cer_smsc_server1."
    echo "cd /etc/sv/smsc/; echo sv stop smsc"
         cd /etc/sv/smsc/; echo "$ssh_pwd" | sudo -S sv stop smsc
    echo "Connecting to $cer_acu_server1 and killing tcapsrv"
    
    # Connect directly aculab machine on port 2200
    #ssh root@"$cer_smsc_server2" -p 2200 "killall -9 tcapsrv"
    sshpass -p $ssh_pwd ssh -tt -o "StrictHostKeyChecking no" ubuntu@"$cer_smsc_server2" -p 22 "killall -9 tcapsrv"
        echo "Start smsc services.."
        echo "cd /etc/sv/smsc/"; echo "sv start smsc"
              cd /etc/sv/smsc/;  echo "$ssh_pwd" | sudo -S sv start smsc
        echo "Restart completed on $cer_smsc_server1"
}
#################################################################################

function cer_error_check() 
{
    echo "Executing restart of CER smsc...";
####PC=$(ssh root@"$cer_smsc_server2" -p 2200 ps ax | grep tcapsrv | grep -v grep -c);
    PC=$(sshpass -p $ssh_pwd ssh -tt -o "StrictHostKeyChecking no" ubuntu@"$cer_smsc_server2" -p 22 ps ax | grep kworker | grep -v grep -c)
    PC=2

    sshpass -p $ssh_pwd ssh -tt -o "StrictHostKeyChecking no" ubuntu@"$cer_smsc_server2" -p 22 << EOT
        readonly ssh_pwd=\\$ssh_pwd
        touch $HOME/.hushlogin
        ####if [[ $(tail -50 /etc/sv/smsc/log/main/current | grep -P "fail | \[error\] CRASH REPORT Process") == "" ]] && [[ $PC -eq 2 ]]; then
        if ([[ $(tail -50 /etc/sv/smsc/log/main/current1 | grep -c "CRASH REPORT Process") -lt 1 ]] && [[ $PC -eq 2 ]]); then 
        
            {
                echo "No fail or timeout found on $cer_smsc_server1. Processes on aculab are two. Not restarted. Exiting"
                exit 1
            }
        else
            {   
                cer_smsc_server1=$cer_smsc_server1
                cer_smsc_server2=$cer_smsc_server2
                cer_acu_server1=$cer_acu_server1
                #$(typeset -f cer_service_restart)
                cer_service_restart;
                exit
            }
        fi
EOT
    exit
}
#################################################################################

function launchpad()
{
    cer_smsc_server1=$1
    cer_smsc_server2=$2
    cer_acu_server1=$3
    readonly ssh_pwd='!1qqaazz'
    echo "$ssh_pwd"
    
    if [[ "$flag" == 'f' ]]; then
    {
        ssh -q ubuntu@"$cer_smsc_server1" "$(typeset -f cer_service_restart); cer_service_restart"
    }
    fi
    
    if [[ "$flag" == 'c' ]]; then
    {
        #< "cer_smsc_server1=$cer_smsc_server1; cer_smsc_server2=$cer_smsc_server2; cer_acu_server1=$cer_acu_server1;"
        #-T -o SendEnv=$cer_smsc_server1 -o $cer_smsc_server2 -o $cer_acu_server1
        #ssh "$cer_smsc_server1" "$(typeset -f cer_error_check); cer_error_check"
        #sshpass -p $ssh_pwd ssh -tt -q ubuntu@"$cer_smsc_server1" << EOT
        sshpass -p $ssh_pwd ssh -tt -q ubuntu@"$cer_smsc_server1" << EOT
            readonly ssh_pwd=\\$ssh_pwd
            echo "$ssh_pwd"
            cer_smsc_server1=$cer_smsc_server1
            cer_smsc_server2=$cer_smsc_server2
            cer_acu_server1=$cer_acu_server1
            touch $HOME/.hushlogin
            $(typeset -f cer_service_restart)
            $(typeset -f cer_error_check)
            cer_error_check
EOT
    }
    fi
}
#################################################################################

function main() 
{
    while getopts ":c:t:x:h" option;
      do
          case "$option" in
              
              c)  flag="$OPTARG"
                  launchpad cer-smsc-05 cer-smsc-01 cer-aculab-01
                  launchpad cer-smsc-06 cer-smsc-02 cer-aculab-02 ;;
                  
              t)  flag="$OPTARG"  
                  launchpad ter-smsc-03 ter-smsc-01 ter-aculab-01
                  launchpad ter-smsc-04 ter-smsc-02 ter-aculab-02 ;;

              x)  flag="$OPTARG"  
                  launchpad 192.168.1.4 192.168.1.83 192.168.1.191 ;;                  

              h)  Help ;;

              #*)  echo "No valid answer, exiting.."
              #    exit 2
         esac
    done
    
    if [[ $# -lt 1 ]]; then
        Help
    fi
}
#################################################################################

main "$@"
#################################################################################
