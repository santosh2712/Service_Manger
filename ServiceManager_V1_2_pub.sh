#!/bin/bash
#######################################################################################
# Author    : Santosh Kulkarni System Administrator
# Date      : 18-10-2019
# Mail      : santosh.kulkarni4u@gmail.com
# Phone     : +91-9960708564
# Version   : 1.2
#--------------------------------------------------------------------------------------
# Purpose   : This script is for Checking all services,Stopping Services and Starting services  
#           : IT Will Stop service in reverse  order and ensure Cluster  is in Maintenance_Mode
#           : Checkpoint of Maintenance_Mode status  will ensure service will not stopped without maintenance mode 
#           : this will prevent cluster from undesired /Unclean switchover of  nodes while stopping the  services  
#           : Apart from it it will give convince for stopping and starting services as these service has count of 13 and there order varies while stopping and starting 
# Type      : Independent
#######################################################################################
# 
# 
############################# Global Variable Declaration #############################
#
# 
#######################################################################################
#
############################# Functions  Declaration ##################################
#
#
######### Global Variables ###########
declare Script_Version="1.2"
######################################
#
if [ "$1" == "--help"  ] || [ "$1" == "-help" ] || [ "$1" == "help"  ] ; then
  clear
  echo "========================================================================================"
        echo "--------------------------------------------------------------"
        echo "=====> Welcome to Service manager $Script_Version Help <========="
        echo "--------------------------------------------------------------"
        echo ":This script is for Checking all services,Stopping Services and Starting services and it also has "
        echo ":Cockpit View which will show complete server status  in nicely formated single window on t "
        echo ":IT Will Stop service in reverse  order and ensure Cluster  is in Maintenance_Mode. Checkpoint of Maintenance_Mode "
        echo ":will ensure service will not stopped without maintenance mode this will prevent cluster "
        echo ":from undesired /Unclean switchover of  nodes while stopping the  services Apart from it  will give convince "
        echo ":for stopping and starting services as these service has count of 13 and there order varies while stopping and starting"
        echo "--------------------------------------------------------------"
        echo ":Version     : 1.2" 
        echo ":Run         : sh $0"
        echo ":Report      : '$0' bugs To santosh.kulkarni4u@gmail.com"
        echo ":Subject     : Bugs '$0' Script Version:<Version No>"
        echo ":Type        : Independent"
  echo "========================================================================================"
exit 0
fi
Sanity_check () 
{
    which {awk,column,cut,date,echo,free,grep,head,hostname,ps,sed,service,sort,top,uname,uptime} >  /dev/null  2>&1
    #
    if [[ $? -ne 0 ]]; then
        echo -e "ERROR : Make Sure below command exist on system\\n"
        echo -e "awk column cut date echo free \\ngrep head hostname ps sed service \\nsort  top uname uptime" 
        #
        echo -e "\e[40;38;5;1mTry after installing above command ...! \e[30;48;5;82mExiting Script..!Bye\e[0m"
        exit 1 
    fi

}
#
Services_Status () 
{
declare cluster_status=$( pcs property | grep 'maintenance-mode' | sed 's@:@=@' )
#
echo  -e "CLUSTER STATUS  |-> $cluster_status" \\n'--------------------------'
echo  -e "jboss-eap-rhel  |-> $( systemctl  status  jboss-eap-rhel   |  grep  'Active' | cut -f 2 -d :  )" \\n'--------------------------'
echo  -e "NewgenWrapper   |-> $( systemctl  status  NewgenWrapper    |  grep  'Active' | cut -f 2 -d :  )" \\n'--------------------------'
echo  -e "NewgenAlarm     |-> $( systemctl  status  NewgenAlarm      |  grep  'Active' | cut -f 2 -d :  )" \\n'--------------------------'
echo  -e "NewgenScheduler |-> $( systemctl  status  NewgenScheduler  |  grep  'Active' | cut -f 2 -d :  )" \\n'--------------------------'
echo  -e "NewgenSMS       |-> $( systemctl  status  NewgenSMS        |  grep  'Active' | cut -f 2 -d :  )" \\n'--------------------------'
echo  -e "NewgenTHM       |-> $( systemctl  status  NewgenTHM        |  grep  'Active' | cut -f 2 -d :  )" \\n'--------------------------'
echo  -e "agencysynch     |->  $( service    agencysynch     status     )" \\n'--------------------------'
echo  -e "synch           |->  $( service    synch     status           )" \\n'--------------------------'
echo  -e "uploadarchival  |->  $( service    uploadarchival    status   )" \\n'--------------------------'
echo  -e "irdocdownload   |->  $( service    irdocdownload     status   )" \\n'--------------------------'
echo  -e "epolicyinsert   |->  $( service    epolicyinsert     status   )" \\n'--------------------------'
echo  -e "epolicyupdate   |->  $( service    epolicyupdate     status   )" \\n'--------------------------'
echo  -e "epolicyarchive  |->  $( service    epolicyarchive    status   )" \\n'--------------------------'

}
app_start_all_services_1 () {
#
echo 'Option 1 Selected'    
#
echo -e '================================================================='\\n"\e[30;41;4;82m||=> Starting Services on Host:$( hostname ) at  $(date '+%d-%b-%Y %H:%M') <=||\e[0m"\\n"\e[30;41;5;81m|| Some Services may take time to start ! Wait till completion. ||\e[0m"\\n'================================================================='
#
START_SERVICE_ARRAY=( jboss-eap-rhel  NewgenWrapper  NewgenAlarm  NewgenScheduler   NewgenSMS  NewgenTHM agencysynch  synch    uploadarchival irdocdownload epolicyinsert epolicyupdate epolicyarchive )
#
#           
for i in "${START_SERVICE_ARRAY[@]}"; do
    #
    if [[ -f  "/etc/init.d/$i" ]]; then
        #
        SYSTEMCTL_SERVICE='^Newgen.*' 
        #
        if [[ "$i" =~ $SYSTEMCTL_SERVICE ]]; then
            #
            echo '-----------------------------------'
            systemctl start "$i"  > /dev/null 2>&1
            wait
            echo "Service  $i started ...! "
            #
        else   
            #
            echo '-----------------------------------'
            service  "$i" start  > /dev/null 2>&1
            wait
            echo "Service  $i started ...! " 
            # 
        fi 
        # 
    else 
        #             
        echo -e "Services  $i at /etc/init.d/$i  not available"\\n'------------------------------'
        #
    fi  
    #            
done
        echo -e '================================'\\n"Check Services with options 3 "\\n'================================'
#
}
#
#####################
#
app_stop_all_services_2 () {
#
echo  -e  "Option 2 Selected\\nScript will move Application Cluster in Maintenance mode and Stop all Application Services \\n\\nDo you want to continue [ y | n ]  \\n"
#
read app_stop_all_services_confirmation 
#
declare app_stop_all_services_confirmation=$(echo "$app_stop_all_services_confirmation"  | tr 'A-Z' 'a-z' )
#
if [[ "$app_stop_all_services_confirmation" == "y"     ]]; then
        #
        which pcs  > /dev/null  2>&1 
        #
    if [[ $? -eq 0 ]]; then
        #
        echo "pcs command found."
        #
        echo  'Changing Application Cluster in Maintenance mode' 
        echo "Setting : pcs property set  maintenance-mode=true"
        #
        pcs property set maintenance-mode=true ; sleep 10
        #
        declare Maintenance_Mode=$( pcs property | grep 'maintenance-mode' | sed 's@ @@g' | cut -f 2 -d : )
        #
        #declare Maintenance_Mode="true"
        #
        if [[ "$Maintenance_Mode"  == "true" ]]; then
            #
            echo -e '================================================================='\\n"\e[30;41;4;82m||=> Stopping Services on Host:$( hostname ) at $(date '+%d-%b-%Y %H:%M') <=||\e[0m"\\n"\e[30;41;5;81m|| Some Services may take time to stop ! Wait till completion. ||\e[0m"\\n'================================================================='
            #
            APP_sTOP_ALL_SERVICES_2_ARRAY=( epolicyarchive epolicyupdate epolicyinsert  irdocdownload  uploadarchival  synch  agencysynch  NewgenTHM  NewgenSMS  NewgenScheduler  NewgenAlarm  NewgenWrapper  jboss-eap-rhel )
            #
            for i in "${APP_sTOP_ALL_SERVICES_2_ARRAY[@]}"; do
                #
                if [[ -f  "/etc/init.d/$i" ]]; then
                    #
                    SYSTEMCTL_SERVICE='^Newgen.*' 
                    #
                    if [[ "$i" =~ $SYSTEMCTL_SERVICE ]]; then
                        #
                        #echo "Newgen Services: $i "
                        echo "Stopping $i Services" 
                        echo '-----------------------------------'
                        systemctl stop "$i"  > /dev/null 2>&1
                        wait
                        #
                    else
                        #   
                        echo "Stopping $i Services" 
                        echo '-----------------------------------'
                        service  "$i" stop   > /dev/null  2>&1
                        wait 
                        # 
                    fi
                    # 
                else 
                   #
                   echo -e "Service /etc/init.d/$i  not available"\\n'------------------------------'
                   #
                fi  
                #
            done    
                #        
                echo -e '================================'\\n" Check Services  with options 3 "\\n'================================'\\n
    
                # 
        else
            #
            echo -e '------------------------------'\\n"Ensure Cluster is in maintenance-mode before Stopping Services"\\n'------------------------------'\\n
            # 
        fi
        #
    else 
        echo "ERROR: pcs command not found. Ensure pcs command exist in system"
        #
    fi
   
else 
    echo "Input received other than y. Returning to Main Menu !"

fi
#
#
}
#
#####################
#
app_status_all_Services_3 () {
#
echo  'Option 3 Selected'
#  
echo -e '============================================================'\\n"\e[30;41;5;82m| Checking Services on Host:$( hostname ) at $(date '+%d-%b-%Y %H:%M') |\e[0m"\\n'============================================================'
#
Services_Status
#
}
#
#
app_server_cockpitview_4 () {
    #
    # clear
    #
    echo    "Option 4 Selected"
    echo -e "--------------------------------------------\\n\e[1;4mApplication server Cockpit View \e[0m\\n--------------------------------------------\\n"
    #Server Uptime 
    echo -e "------------------------------\\n\e[1;4mServer $(hostname) Uptime :\e[0m $( uptime | awk '{print $3,$4}' | cut -f1 -d , )"
    #OS name from /etc/redhat-release file 
    if [[ -f "/etc/redhat-release"  ]]; then
        #
        echo -e "------------------------------\\n\e[1;4mOprating System :\e[0m $( cat /etc/redhat-release )"
    fi
    #Kernel Version
    echo -e "------------------------------\\n\e[1;4mKernel Version :\e[0m $( uname -r  )"
    #Architecture
    echo -e "------------------------------\\n\e[1;4mArchitecture :\e[0m $( uname -m  )"
    #Server IPADDRESS
    echo -e "------------------------------\\n\e[1;4mServer IPADDRESS :\e[0m "
    hostname -I  | sed 's@ @\n@g'   
    # echo "------------------------------"
    #Name Server's 
    if [[ -f "/etc/resolv.conf" ]]; then
        echo -e "------------------------------\\n\e[1;4mDefined NameServer's :\e[0m "
        #
        awk '/nameserver/ {print $2}' /etc/resolv.conf
        # echo "------------------------------"
        #
    fi
    #Ram Usage 
    echo -e "------------------------------\\n\e[1;4mServer Ram Usage :\e[0m "
    free -h | grep -B1  '^Mem:' 
    # echo "------------------------------"
    #
    #Swap Usage 
    echo -e "------------------------------\\n\e[1;4mServer Swap Usage :\e[0m\\n              total        used        free      shared  buff/cache   available"
    free -h  | grep   '^Swap:' 
    # echo "------------------------------"
    #Load Averages 
    echo -e "------------------------------\\n\e[1;4mServer Load Averages:\e[0m $(  top -n 1 -b | grep "load average:" | tr ' ' '\n' | tail -3 | tr '\n' ' ' | sed 's@,@ @g' )"
    #Top 5 Process by Memory 
    echo -e "------------------------------\\n\e[1;4mTop 5 Memory Consuming Process :\e[0m "
    # 
    ps -eo user,pid,ppid,cmd,start,%mem,%cpu --sort=-%mem | head -n6 
    #Top 5 Process by CPU 
    echo -e "------------------------------\\n\e[1;4mTop 5 CPU Consuming Process :\e[0m "
    # 
    ps -eo user,pid,ppid,cmd,start,%mem,%cpu --sort=-%cpu | head -n6
    #Top 5 Partition as per usage Usage 
    echo -e "------------------------------\\n\e[1;4mTop 5 Partitions as per Utilization % :\e[0m "
    #
    echo "Filesystem      Size  Used Avail Use% Mounted_on"  | column -t
    #
    echo -e "\e[1;4m$( df -h | sed '1d' | sort -nr -k 5 | column -t  -o '|' | head -5 )\e[0m"
    # Services Status 
    echo -e '============================================================'\\n"\e[30;41;5;82m| Checking Services on Host:$( hostname ) at $(date '+%d-%b-%Y %H:%M') |\e[0m"\\n'============================================================'
    #
    Services_Status
    #
    echo -e "\\nScroll Upward's to check server status information\\n"

}
#
########################   Function Section Completed #######################################
#
#
############################# Script Section Begins  ##################################
#
if [[ $UID -eq 0 ]]; then
    #echo "Running as root User:"
    #Sanity check function
    Sanity_check

    while true; do 
        # 
        options=("Start All Services" "Stop All Services" "Status All Services" "Server Status CockpitView"  "Quit")
        #
        echo -e '==================================================='\\n"\e[30;48;5;82m|| Application Services Manager Utility Ver:$Script_Version ||\e[0m"\\n'==================================================='
        #
        echo -e  "\e[30;43;5;82m| Choose an option: Enter input between 1-5 only |\e[0m"\\n'==================================================='
        #
        select opt in "${options[@]}"; do
            #
            case $REPLY in
                1) app_start_all_services_1 ; break ;;
                2) app_stop_all_services_2 ; break ;;
                3) app_status_all_Services_3 ; break ;;
                4) app_server_cockpitview_4 ; break ;;
                5) break 2 ;;
                *) echo "Wrong input! Please Input Numbers only from 1 to 4 " >&2
            esac
            #
        done
        #
    done
    #
    echo -e  \\n'=================================='\\n"\e[30;45;6;82mThanks $USER ! Have A Great Day \e[0m"\\n'=================================='
    #
else
    # 
    echo -e \\n'---------------------------'\\n'User Need to be root to use this Script ! Login as root User '\\n'---------------------------'\\n
    #
fi
