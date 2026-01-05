#!/bin/bash
set -e

##################################################################
### Constant Variables ###########################################
##################################################################
GREEN='\033[0;32m'
# BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


##################################################################
### Shellscript Intro  ###########################################
##################################################################
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}     🚀 Athenz Plugin Deployment Wizard       ${NC}"
echo -e "${CYAN}==============================================${NC}"

##################################################################
### Prerequisites Check ##########################################
##################################################################

# Extract JAR Path from pom.xml
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}[Error] pom.xml not found in current directory!${NC}"
    exit 1
fi

ARTIFACT_ID=$(grep -m 1 "<artifactId>" pom.xml | sed -e 's/^[[:space:]]*<artifactId>//' -e 's/<\/artifactId>[[:space:]]*$//')
JAR_VERSION=$(grep -m 1 "<version>" pom.xml | sed -e 's/^[[:space:]]*<version>//' -e 's/<\/version>[[:space:]]*$//')

if [ -z "$ARTIFACT_ID" ] || [ -z "$JAR_VERSION" ]; then
  echo -e "${RED}[Error] Failed to parse artifactId or JAR_VERSION from pom.xml${NC}"
  exit 1
else
  JAR_PATH="target/${ARTIFACT_ID}-${JAR_VERSION}.jar"
  echo -e "${GREEN}✅ Confirmed JAR Path: $JAR_PATH${NC}"
fi

##################################################################
### Interactive User Prompt ######################################
##################################################################

DEFAULT_NS="athenz"
DEFAULT_CM="ses-plugin-lib"
DEFAULT_DEPLOY="athenz-zms-server"

# 2. Namespace
read -p "👉 Target K8s Namespace? [Hit enter for default: athenz]: " INPUT_NS
NAMESPACE=${INPUT_NS:-$DEFAULT_NS}

# 3. ConfigMap Name
read -p "👉 K8s ConfigMap Name? [Hit enter for default: ses-plugin-lib]: " INPUT_CM
CM_NAME=${INPUT_CM:-$DEFAULT_CM}

# 5. Restart Confirmation
read -p "👉 Restart Athenz ZMS Server after update? (Any non-Y is no) [Hit enter for default: Y]: " INPUT_RESTART
RESTART=${INPUT_RESTART:-Y}

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

echo -e "👷 Creating a new package..."
mvn clean package

echo -e "📦 Updating ConfigMap..."
kubectl delete cm "$CM_NAME" -n "$NAMESPACE" --ignore-not-found
kubectl create cm "$CM_NAME" --from-file=ses-plugin.jar="$JAR_PATH" -n "$NAMESPACE"

if [[ "$RESTART" =~ ^[Yy]$ ]]; then
  echo -e "🔄 Restarting Deployment..."
  kubectl rollout restart deployment "$ZMS_DEPLOYMENT" -n "$NAMESPACE"
  echo -e "${GREEN}✅ Done! Athenz ZMS Deployment restarted.${NC}"
else
  echo -e "${YELLOW}✋ Skipping Athenz ZMS Deployment restart. Only ConfigMap updated.${NC}"
fi