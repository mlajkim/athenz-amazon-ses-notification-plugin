#!/bin/bash
set -e

##################################################################
### Constant Variables ###########################################
##################################################################
GREEN='\033[0;32m'
# BLUE='\033[0;34m'
# RED='\033[0;31m'
CYAN='\033[0;36m'
# YELLOW='\033[1;33m'
NC='\033[0m' # No Color


##################################################################
### Shellscript Intro  ###########################################
##################################################################

# None

##################################################################
### Prerequisites Check ##########################################
##################################################################

# None

##################################################################
### Interactive User Prompt ######################################
##################################################################

DEFAULT_NS="athenz"
DEFAULT_DEPLOY="athenz-zms-server"

# 2. Namespace
read -p "👉 Athenz ZMS Server Namespace? [Hit enter for default: athenz]: " INPUT_NS
NAMESPACE=${INPUT_NS:-$DEFAULT_NS}

# 4. Deployment Name
read -p "👉 Athenz ZMS Server Deployment Name in ns [$NAMESPACE]? [Hit enter for default: athenz-zms-server]: " INPUT_DEPLOY
ZMS_DEPLOYMENT=${INPUT_DEPLOY:-$DEFAULT_DEPLOY}

echo -e "\n${CYAN}--- Summary ----------------------${NC}"
echo -e "Namespace             : ${GREEN}$NAMESPACE${NC}"
echo -e "ConfigMap             : ${GREEN}$CM_NAME${NC}"
echo -e "Athenz ZMS Deployment : ${GREEN}$ZMS_DEPLOYMENT${NC}"
echo -e "Jar File              : ${GREEN}$JAR_PATH${NC}"
echo -e "Restart?              : ${GREEN}$RESTART${NC}"
echo -e "${CYAN}------------------------------------${NC}\n"


##################################################################
### Core LOGIC ###################################################
##################################################################

path="/usr/lib/jars"
pod_name=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=$ZMS_DEPLOYMENT -o jsonpath="{.items[0].metadata.name}")
echo -e "🔍 Checking JAR file in path [$path] of pod [$pod_name]..."

kubectl exec -n $NAMESPACE $pod_name -- ls -al $path
