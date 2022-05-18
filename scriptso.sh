#!/bin/bash

# Main menu of the project codename RaisingPrinces
# This project is not ment to be used in real life.
# Authors legacy for Operating Systems course at Bucharest University of Economic Studies 
# For details about this project read "readme.txt"

title="Welcome to RaisingPrinces app"
isFirstSelection=0
prompt="Please, pick option from below:"
options=("User guide" "Secure password generator" "Check docker version" "Show all docker containers" "Restart docker instances" "Quit")

GetDockerContainersList() {
    output=$(eval "docker ps -a --format '{{.ID}} {{.Names}}'")

    IFS=$'\n'
    read -rd '' -a CONTAINERS <<<"$output"
}

#### BEGIN INTERACTION #####
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
        ### NEXT OPTION ###
        "Check docker version")
        # check if docker is installed
        # if YES -> then show version
        # if NO -> promt user to install
        echo 'Checking docker version'
            dockerPath=$(which docker)
            dockerVersion=$(docker -v)
            if [[ $dockerPath && $dockerVersion ]]
            then
                echo "### Docker version: $dockerVersion installed on $dockerPath. All good to go!"
            else
                echo "### Docker not found on this system."
                # we put -n param because want user coursor to stay inline with text
                # displayed on stdout
                echo -n "### Shall we install it[Y(es)/N(o)]? Pick Yes only if are using Ubuntu: ";
                read;
                userSelectedValue=${REPLY}
                # user typed character is then conducted through pipe operator 
                # and gets applied a REGEX expression that match any capital letter 
                # to the lower case variant 
                userSelectedValue=$userSelectedValue | sed -e 's/\(.*\)/\L\1/'
                echo $userSelectedValue
                
                if [[ $userSelectedValue == "yes" || $userSelectedValue == 'y' ]]; then
                # we can put this kind of instructions in a variable 
                # because why may want to detect user system and to apply specific instructions
                # NOTICE 1) sudo -s argument = run the shell specified by the SHELL env
                #          -- sudo should stop processing command line arguments
                # NOTICE 2) the -y argument = answer with yes automatic
                sudo -s -- <<EOF
                apt-get update 
                apt-get install -y linux-image-extra-$(uname -r)
                apt-get install docker-engine -y
                service docker start
                docker run hello-world
EOF
                else
                    echo "No option"
                fi
            fi
        ;;
        ### NEXT OPTION ###
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