#!/bin/bash

# Main menu of the project codename RaisingPrinces
# This project is not ment to be used in real life.
# Authors legacy for Operating Systems course at Bucharest University of Economic Studies 
# Supervisor: Antonio Clim
# For details about this project read "readme.txt"

title="Welcome to RaisingPrinces app"
isFirstSelection=0
prompt="Please, pick option from below:"
options=("User guide" "Secure password generator" "Show all docker containers" "Check docker version" "Restart docker instances" "Quit")

GetDockerContainersList() {
    output=$(eval "docker ps -a --format '{{.ID}} {{.Names}}'")

    IFS=$'\n'
    read -rd '' -a CONTAINERS <<<"$output"
}

echo "$title"
# use promt shell 3 to capture user selected option
PS3="$prompt "
select opt in "${options[@]}"
# showing the menu for user
do
    case $opt in
        "User guide")
        # file should be placed in same directory as script
        userManualLocation="readme.txt"
        # check for a regular file only
        if [ -f $userManualLocation ]
            then echo "$(cat readme.txt)"
            else echo "Unable to locate user manual."
        fi
        ;;
        "Secure password generator")
        echo "Let's do some magic and generate an unique password"
        alphabet=("A" "B" "C" "D" "E" "F" "G")
        specialChars=("#" "%" "&" "^", "!")
        numericChars=(1 2 3 4 5 6 7 8 9 0)
        minPasswordLength=6
        minSpecialChars=2
        minNumericChars=2
        passwordGenerated=""
        for char in ${alphabet[@]}
        do
            echo "$(( $RANDOM % ${#alphabet[@]} + 1 ))"
        done 
        ;;
        "Check docker version")
        # check if docker is installed
        # if YES -> then show version
        # if NO -> promt user to install
        echo "Checking docker version"
        ;;

        "Show all docker containers")
        echo "Docker containers"
        GetDockerContainersList
        printf "Number of containers: %d\n" "${#CONTAINERS[@]}"
        for container in "${CONTAINERS[@]}"
        do
            : 
            echo $container
        done
        ;;
        
        "Install services")
        # promt user to select what services to install
        # eg: nginx, php, mysql//mariadb (or simply here: should we add a database?)
        # if yes then -> then install nginx + php + mysql
        # if no then just install nginx + php 
        # for each service that will be installed generate configuration file
        echo "Installing services"
        ;;

        "Raise docker instances")
        exec "docker-compose up -d"
        echo "Raising instances"
        ;;

        "Restart docker instances")
        echo "Restarting instances"
        test=$( GetDockerContainersList )
        echo ${test[@]}
        ;;

        "Show logs for instance")
        # can choose for what instance to show logs (eg: webserver)
        echo "Logs"
        ;;

        "Deploy code")
        # dummy repo on github and push to webserver root
        echo "Deploy"
        ;;

        "Quit")
        echo "Goodbye :)"
        break
        ;;
        *) 
        echo "Ops, selected option is not valid"
        ;;
    esac
    # numeric evaluation
    ((isFirstSelection++))
    # have fun, change promt message
    if  [ $isFirstSelection -gt 0 ]
        then PS3="Pick option from list:"
    fi
done