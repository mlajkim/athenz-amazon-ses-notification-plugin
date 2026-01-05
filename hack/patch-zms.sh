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
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   🔧 Athenz Deployment Patch Wizard        ${NC}"
echo -e "${CYAN}============================================${NC}"

##################################################################
### Prerequisites Check ##########################################
##################################################################

# Get the yaml file path:
SCRIPT_DIR="$(dirname "$0")"
PATCH_FILE="${SCRIPT_DIR}/patch-zms.yaml"
if [ ! -f "$PATCH_FILE" ]; then
  echo -e "${RED}[Error] Patch file not found at: $PATCH_FILE${NC}"
  echo -e "${YELLOW}Please ensure 'patch-zms.yaml' exists in the hack/ directory.${NC}"
  exit 1
fi

##################################################################
### Interactive User Prompt ######################################
##################################################################

DEFAULT_NS="athenz"
DEFAULT_DEPLOY="athenz-zms-server"

echo ""

# 2. Namespace
read -p "👉 Athenz ZMS Server Namespace? [Hit enter for default: $DEFAULT_NS]: " INPUT_NS
NAMESPACE=${INPUT_NS:-$DEFAULT_NS}

# 4. Deployment Name
read -p "👉 Athenz ZMS Server Deployment Name in ns [$NAMESPACE]? [Hit enter for default: $DEFAULT_DEPLOY]: " INPUT_DEPLOY
ZMS_DEPLOYMENT=${INPUT_DEPLOY:-$DEFAULT_DEPLOY}

echo -e "\n${CYAN}--- Summary ----------------------${NC}"
echo -e "Namespace             : ${GREEN}$NAMESPACE${NC}"
echo -e "Athenz ZMS Deployment : ${GREEN}$ZMS_DEPLOYMENT${NC}"
echo -e "Patch File            : ${GREEN}$PATCH_FILE${NC}"
echo -e "${CYAN}------------------------------------${NC}\n"

##################################################################
### Core LOGIC ###################################################
##################################################################

echo -e "📦 Applying Patch to Deployment..."

# Apply the patch using kubectl:
kubectl patch deployment "$ZMS_DEPLOYMENT" -n "$NAMESPACE" --patch-file "$PATCH_FILE"
