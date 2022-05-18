#!/bin/bash

# Main menu of the project codename RaisingPrinces
# This project is not ment to be used in real life.
# Authors legacy for Operating Systems course at Bucharest University of Economic Studies
# For details about this project read "readme.txt"

title="Welcome to RaisingPrinces app"
isFirstSelection=0
prompt="Please, pick option from below:"
options=("User guide" "Secure password generator" "Check docker version" "Generate container services" 
"Show all docker containers" "Restart docker instances" "Quit")

GetDockerContainersList() {
    output=$(eval "docker ps -a --format '{{.ID}} {{.Names}}'")

    IFS=$'\n'
    read -rd '' -a CONTAINERS <<<"$output"
}

CreatingDockerComposeFile() {
    cat > $1/docker-compose.yml << EOF
version: "3.8"
services:
  php:
    container_name: "\${APP_NAME}-php"
    depends_on:
      - db
    build:
      context: .
      dockerfile: ./docker/webserver/Dockerfile-php
    environment: # We set some environments variables to facilitate debug
    expose:
      - 9003
    volumes:
      - ./codebase:/var/www/html # It has to match with the WORKDIR inside the docker file
    networks:
      - ase_os_net # Still same network

  nginx:
    container_name: "\${APP_NAME}-nginx"
    depends_on:
      - php # We need to load PHP for the Nginx configuration file
    build:
      context: .
      dockerfile: ./docker/webserver/Dockerfile-nginx
    ports:
      - "\${APP_PORT}:80" # Redirect Docker port
    volumes:
      - ./docker/webserver/log:/var/log/nginx
    volumes_from:
      - php
    links:
      - php:php
    networks:
      - ase_os_net     
EOF
}

AppendMysqlConfigurationToDockerComposeFile() {
    cat >> $1/docker-compose.yml << EOF
  db:
    image: mariadb:10.7
    container_name: "\${APP_NAME}-db"
    environment:
      MYSQL_ROOT_PASSWORD: "\${MYSQL_ROOT_PASS}"
      MYSQL_DATABASE: "\${MYSQL_DB}"
    restart: always
    ports:
      - "\${DB_PORT}:3306"
    volumes:
      - ./docker/db/init.db:/docker-entrypoint-initdb.d
      - ./docker/db/data:/var/lib/mysql
EOF
}

CloseDockerComposeFileConfiguration() {
    tar -xvzf docker.tar.gz -C $1
    cat >> $1/docker-compose.yml << EOF
networks:
  - ase_os_net
EOF
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
### ---- NEXT OPTION --------------------------------------------------------------------------###
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
                    echo ""
                    sleep 1
                fi
            fi
        ;;
### ---- NEXT OPTION --------------------------------------------------------------------------###
        "Generate container services")
        # promt user to select what services to install
        # eg: nginx, php, mysql//mariadb (or simply here: should we add a database?)
        # if yes then -> then install nginx + php + mysql
        # if no then just install nginx + php 
        # for each service that will be installed generate configuration file
        echo ""
        sleep 1
        echo "### Before starting let's answer few questions"
        echo ""
        shouldDatabaseServiceBeInstalled=0
        databasePassword=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 13 ; echo '')
        # from bash manual
        # ${parameter:-word} if parameter is unset or null, the expansion of word is substituted
        read -p "### Where should app be located: " applicationPath
        applicationPath=${applicationPath:-.}
        sleep 1
        read -p "### Application name: " applicationName
        applicationName=${applicationName:-demo}
        sleep 1
        read -p "### NGINX should be bound to local port (8100 default): " nginxLocalPort
        nginxLocalPort=${nginxLocalPort:-8100}
        echo -n "### Shall we install MariadDB? [Y(es)/N(o)]: ";
        read;
        if [[ ${REPLY} == "yes" || ${REPLY} == 'y' ]]; then
            read -p "### MariaDB should be bound to local port (33010 default)" databaseLocalPort
            databaseLocalPort=${databaseLocalPort:-33010} 
            read -p "### Database name: " databaseName
            databaseName=${databaseName:-demo} 
            shouldDatabaseServiceBeInstalled=1
        fi

        # all configuration will be placed on applicationPath variable
        # therefore we need to change path
        $(mkdir -p ${applicationPath})
        # make directory to store codebase
        $(mkdir -p ${applicationPath}/codebase)
        # create env file for saving variables
        $(touch ${applicationPath}/.env)
        $(cat > ${applicationPath}/.env << EOF
APP_NAME=$applicationName
APP_PORT=$nginxLocalPort
EOF
)
        if [ $shouldDatabaseServiceBeInstalled -eq 1 ]
        then
        # append to existing configuration
            $(cat >> ${applicationPath}/.env << EOF
DB_PORT=$databaseLocalPort 
MYSQL_ROOT_PASS=$databasePassword
MYSQL_DB=$databaseName
EOF
)
        fi

        echo ""
        echo "#### Saving enviroment variables"
        sleep 1
        echo "### Operation completed"
        echo ""
        sleep 1
        echo "### Starting creating configuration"
        sleep 1
        $(touch file.yml)
        # Starting creating docker-compose yml file configuration
        CreatingDockerComposeFile $applicationPath
        if [ $shouldDatabaseServiceBeInstalled -eq 1 ]; then
            AppendMysqlConfigurationToDockerComposeFile $applicationPath
        fi
        CloseDockerComposeFileConfiguration $applicationPath
        echo "### Done creating configuration"
        sleep 1
        echo ""
        ;;
### ---- NEXT OPTION --------------------------------------------------------------------------###
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
### ---- NEXT OPTION --------------------------------------------------------------------------###
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