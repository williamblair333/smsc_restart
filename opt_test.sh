#!/bin/env bash

set -o errexit
set -o nounset
set -eu -o pipefail

#set -x
#trap read debug
flag=""
##################################################################################

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

function option_f() 
{
    echo "function option_f force message goes here"
    echo "$cer_smsc_server1"
    echo "$cer_smsc_server2"
    echo "$cer_acu_server1"
}
#################################################################################

function option_c() 
{
    cer_smsc_server1=$1
    cer_smsc_server2=$2
    cer_acu_server1=$3

    if [[ "$flag" == 'f' ]]; then
        echo ""
        echo "##################################################################################"
        echo "function FORCE option_c message goes here"
        option_f
        echo "##################################################################################"
    
    elif [[ "$flag" == 'c' ]]; then
        echo ""
        echo "##################################################################################"
        echo "function option_c message goes here"
        echo "##################################################################################"

    else
        echo "No valid arguments passed, exiting.  "
        #exit 1
    fi
}
#################################################################################
function main() 
{
    while getopts ":c:t:fh" option;
      do
          case "$option" in
              
              f)  flag="f" ;;
              
              c)  flag="$OPTARG"
                  if [ -z "$flag" ]; then flag="x"; fi
                  option_c server1 server2 server3 
                  option_c server4 server5 server6 ;;
                  
              t)  flag="$OPTARG"  
                  option_c server7 server8 server9 
                  option_c server10 server11 server12 ;;

              h)  Help ;;

              #*)  echo "No valid answer, exiting.."
              #    exit 2
         esac
    done
}
#################################################################################

main "$@"
#################################################################################
    
