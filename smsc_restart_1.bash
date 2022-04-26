#!/bin/bash

#################################################################################

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
# The -f option is ignorned and seems to only work in the 2nd if statements.
# The -f option should only execute the else script
# $# is a special variable in bash, expands to number of arguments (positional
# parameters) passed to the script in quesiton or the shell in case of argument 
# directly passed to the shell
# ./smsc_restart.bash t -f
# ./smsc_restart.bash -f
# ./smsc_restart.bash c -f
# ./smsc_restart.bash -f
#################################################################################

if [[ $# -lt 1 ]];
then
	echo "usage: $0 <env> [-f]" 
        echo "env: C for CER or T for TER"
	echo "-f (force): restart without any check"
	exit
fi
#################################################################################

case ${1:0:1} in
    c|C )
        echo "Executing restart of CER smsc..."
#################################################################################

        ssh cer-smsc-05
#################################################################################

	   if [[ $2 != '-f' ]];
           then
	       # Count number of process on aculab	
               PC=$(ssh root@cer-smsc-01 -p 2200 ps ax |grep tcapsrv| grep -v grep |wc -l)
           fi
#################################################################################

	   if [[ $2 != '-f' ]] && ([[ $(sudo tail -50 /etc/sv/smsc/log/main/current |grep -P "fail | \[error\] CRASH REPORT Process") == "" ]] && [[ $PC -eq 2 ]]) ;
              then 
                echo "No fail or timeout found on cer-smsc-05. Processes on aculab are two. Not restarted. Exiting"
                exit 1
        else
        echo "Found timeout, fail or wrong number of tcapsrv processes or -f option has been specified. Stopping cer-sms-05."
        echo cd /etc/sv/smsc/ ; echo sv stop smsc
        cd /etc/sv/smsc/ ; sudo sv stop smsc
        echo "Connecting to cer-aculab-01 and killing tcapsrv"
        # Connect directly aculab machine on port 2200
		
		ssh root@cer-smsc-01 -p 2200 "killall -9 tcapsrv"
      		echo "Start smsc services.."
      		echo cd /etc/sv/smsc/ ; echo sv start smsc
                cd /etc/sv/smsc/ ; sudo sv start smsc   
      		echo "Restart completed on cer-smsc-05"
  	   fi
#################################################################################  	   

        ssh cer-smsc-06
#################################################################################

	   if [[ $2 != '-f' ]];
           then
	       # Count number of process on aculab
               PC=$(ssh root@cer-smsc-02 -p 2200 ps ax |grep tcapsrv| grep -v grep |wc -l)
           fi
#################################################################################           

           if [[ $2 != '-f' ]] && ([[ $(sudo tail -50 /etc/sv/smsc/log/main/current |grep -P "fail | \[error\] CRASH REPORT Process") == "" ]] && [[ $PC -eq 2 ]]) ;
              then        
                echo "No fail or timeout found on cer-smsc-06. Processes on aculab are two. Not restarted. Exiting"
                exit 1
           else   
                echo "Found timeout, fail or wrong number of tcapsrv processes or -f option has been specified. Stopping cer-smsc-06"
                echo cd /etc/sv/smsc/ ; echo sv stop smsc
                cd /etc/sv/smsc/ ; sudo sv stop smsc
                echo "Connecting to cer-aculab-02 and killing tcapsrv"
                # Connect directly aculab machine on port 2200
		ssh root@cer-smsc-02 -p 2200 "killall -9 tcapsrv"
                echo "Start smsc services.."
                echo cd /etc/sv/smsc/ ; echo sv start smsc
		cd /etc/sv/smsc/ ; sudo sv start smsc
                echo "Restart completed on cer-smsc-06"
           fi
#################################################################################

;;
    t|T )
        echo "Executing restart of TER smsc..."
        ssh ter-smsc-03 
	   if [[ $2 != '-f' ]];
           then
	       # Count number of process on aculab
               PC=$(ssh root@ter-smsc-01 -p 2200 ps ax |grep tcapsrv| grep -v grep |wc -l)
           fi
#################################################################################

           if [[ $2 != '-f' ]] && ([[ $(sudo tail -50 /etc/sv/smsc/log/main/current |grep -P "fail | \[error\] CRASH REPORT Process") == "" ]] && [[ $PC -eq 2 ]]) ;
              then
                echo "No fail or timeout found on ter-smsc-03. Processes on aculab are two. Not restarted. Exiting"
                exit 1
           else
                echo "Found timeout, fail or wrong number of tcapsrv processes or -f option has been specified. Stopping ter-smsc-03"
                echo cd /etc/sv/smsc/ ; echo sv stop smsc
		cd /etc/sv/smsc/ ; sudo sv stop smsc
                echo "Connecting to ter-aculab-01 and killing tcapsrv"
                # Connect directly aculab machine on port 2200
                ssh root@ter-smsc-01 -p 2200 "killall -9 tcapsrv"
                echo "Start smsc services.."
                echo cd /etc/sv/smsc/ ; echo sv start smsc
                cd /etc/sv/smsc/ ; sudo sv start smsc
                echo "Restart completed on ter-smsc-03"
           fi
#################################################################################

#1,2,1,1,3,2,1
    #cer_smsc_server1=$1
    #cer_smsc_server2=$2
    #cer_acu_server1=$3
    #cer_restart ter-smsc-03 ter-smsc-01 ter-aculab-01
    #cer_restart ter-smsc-04 ter-smsc-02 ter-aculab-02
    
        ssh ter-smsc-04
#################################################################################

	   if [[ $2 != '-f' ]];
           then
	       # Count number of process on aculab
               PC=$(ssh root@ter-smsc-02 -p 2200 ps ax |grep tcapsrv| grep -v grep |wc -l)
           fi
#################################################################################

           if [[ $2 != '-f' ]] && ([[ $(sudo tail -50 /etc/sv/smsc/log/main/current |grep -P "fail | \[error\] CRASH REPORT Process") == "" ]] && [[ $PC -eq 2 ]]) ;
              then
                echo "No fail or timeout found on ter-smsc-04. Processes on aculab are two. Not restarted. Exiting"
                exit 1
           else
                echo "Found timeout, fail or wrong number of tcapsrv processes or -f option has been specified. Stopping ter-smsc-04"
                echo cd /etc/sv/smsc/ ; echo sv stop smsc
		cd /etc/sv/smsc/ ; sudo sv stop smsc
                echo "Connecting to ter-aculab-02 and killing tcapsrv"
                # Connect directly to aculab machine on port 2200
                ssh root@ter-smsc-02 -p 2200 "killall -9 tcapsrv"
                echo "Start smsc services.."
                echo cd /etc/sv/smsc/ ; echo sv start smsc
                echo "Restart completed on ter-smsc-04"
           fi
#################################################################################

    ;;
    * )
        echo "No valid answer, exiting.."
        exit 2
    ;;
esac
