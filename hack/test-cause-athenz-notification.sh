#!/bin/bash
set -e

##################################################################
### Imports ######################################################
##################################################################
# shellcheck disable=SC1091
source "$(dirname "$0")/colors.sh"

##################################################################
### Shellscript Intro  ###########################################
##################################################################
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}        🔄 Athenz Notification Test          ${NC}"
echo -e "${CYAN}==============================================${NC}"

##################################################################
### Prerequisites Check ##########################################
##################################################################

# None

##################################################################
### Interactive User Prompt ######################################
##################################################################

DEFAULT_NS="athenz"
DEFAULT_DB_POD_NAME="athenz-db"
DEFAULT_DEPLOY="athenz-zms-server"

# 2. Namespace
read -p "👉 Target K8s Namespace? [Hit enter for default: $DEFAULT_NS]: " INPUT_NS
NAMESPACE=${INPUT_NS:-$DEFAULT_NS}

# DB pod name to connect:
read -p "👉 Athenz DB Pod Name in ns [$NAMESPACE]? [Hit enter for default: $DEFAULT_DB_POD_NAME]: " INPUT_DB_POD
DB_POD_NAME=${INPUT_DB_POD:-$DEFAULT_DB_POD_NAME}

# 4. ZMS Deployment Name
read -p "👉 Athenz ZMS Server Deployment Name in ns [$NAMESPACE]? [Hit enter for default: $DEFAULT_DEPLOY]: " INPUT_DEPLOY
ZMS_DEPLOYMENT=${INPUT_DEPLOY:-$DEFAULT_DEPLOY}

echo -e "\n${CYAN}--- Summary ----------------------${NC}"
echo -e "Namespace             : ${GREEN}$NAMESPACE${NC}"
echo -e "DB Pod Name           : ${GREEN}$DB_POD_NAME${NC}"
echo -e "Athenz ZMS Deployment : ${GREEN}$ZMS_DEPLOYMENT${NC}"
echo -e "${CYAN}------------------------------------${NC}\n"


##################################################################
### Core LOGIC ###################################################
##################################################################

# First quickly explain how this works:
echo -e "ℹ️  This script will connect to the Athenz DB pod [$DB_POD_NAME] in namespace [$NAMESPACE],"
echo -e "   and insert a test notification record into the notification table."
echo -e "   Then it will restart the Athenz ZMS server deployment [$ZMS_DEPLOYMENT] to trigger the notification plugin to process it.\n"
