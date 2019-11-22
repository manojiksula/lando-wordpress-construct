#!/bin/bash

set -e

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)

read -p "Lando Project Name: | default: wordpress-app |: " lando_project_name

if [ -z "${lando_project_name}" ]; then
  PROJECT_NAME='wordpress-app'
else 
  PROJECT_NAME=$lando_project_name;
fi

lando init \
  --source cwd \
  --recipe wordpress \
  --webroot wordpress \
  --name ${PROJECT_NAME}

lando start

#
# Sets up wp-config.
#
setup_config() {
    lando wp core config --dbhost=database --dbname=wordpress --dbuser=wordpress --dbpass=wordpress
}

#
# Install wordpress core.
#
install_wordpress_core() {
    lando wp core download
    setup_config

    read -p "Is Multisite (y/n)? | default n |: " is_multisite

    case "${is_multisite}" in
        y|Y ) MULTISITE=1;;
        n|N ) MULTISITE=0;;
        * ) MULTISITE=0;;
    esac

    while true; do
        read -p "Write your admin email: " ADMIN_EMAIL

        if echo "${ADMIN_EMAIL}" | grep '^[a-zA-Z0-9._%+-]*@[a-zA-Z0-9]*\.[a-zA-Z]*$' >/dev/null; then
            break
        else
            echo "Please write a valid email."
        fi

    done

    URL="${PROJECT_NAME}.lndo.site"
    TITLE="${PROJECT_NAME}"

    if [ ${MULTISITE} -eq 1 ]; then
        echo " * Setting up multisite \"${TITLE}\" at ${URL}"
        lando wp core multisite-install --url="$URL" --title="${TITLE}" --admin_user=admin --admin_password=password --admin_email="${ADMIN_EMAIL}" --subdomains
        lando wp super-admin add admin
    else
        echo " * Setting up \"${TITLE}\" at ${URL}"
        lando wp core install --url="${URL}" --title="${TITLE}" --admin_user=admin --admin_password=password --admin_email="${ADMIN_EMAIL}"
    fi
    
    read -p "Downgrate to specific version? | default n |: " wordpress_version

    if [ ! -z "${wordpress_version}" ]; then
        echo "${wordpress_version}"
        lando wp core update --version="${wordpress_version}" --force
    fi
}

#
# Installs wordpress from scratch.
#
install_wordpress_from_scratch() {
    mkdir -p "$ROOT/wordpress"
    cd "$ROOT/wordpress"
    install_wordpress_core
}

#
# Installs wordpress from existing repo.
# Also possible to install core on top of the repo
#
install_existing_wordpress_from_repo() {
    read -p "Write your project repository URL:" REPOSITORY

    ## WORDPRESS SETUP ##
    if [ ! -z "${REPOSITORY}" ]; then
        echo "Local repository found. Downloading..."
        git clone $REPOSITORY "$ROOT/wordpress"
    fi

    cd "$ROOT/wordpress"

    read -p "Install Core? (y/n)? | default n |: " install_core

    case "${install_core}" in
        y|Y ) INSTALL_CORE=1;;
        n|N ) INSTALL_CORE=0;;
        * ) INSTALL_CORE=0;;
    esac

    if [ ${INSTALL_CORE} -eq 1 ]; then
        install_wordpress_core
    else
        setup_config
    fi

    install_wordpress_core
}

# 
# Imports DB. You have to have
# A file called db.sql in which you want to import to
# 
import_database() {
    cd "$ROOT"
    lando wp db import db.sql
}

#
# Inits the script to install a wordpress installation
#
init() {
    read -p "Install From Scratch? (y/n)? | default n |: " from_scratch

    case "${from_scratch}" in
        y|Y ) FROM_SCRATCH=1;;
        n|N ) FROM_SCRATCH=0;;
        * ) FROM_SCRATCH=0;;
    esac

    if [ ${FROM_SCRATCH} -eq 1 ]; then
        install_wordpress_from_scratch
    else
        install_existing_wordpress_from_repo
    fi

    read -p "Import db? (y/n)? | default n |: " import_db

    case "${import_db}" in
        y|Y ) IMPORT_DB=1;;
        n|N ) IMPORT_DB=0;;
        * ) IMPORT_DB=0;;
    esac

    if [ ${IMPORT_DB} -eq 1 ]; then
        import_database
    fi
}

init
