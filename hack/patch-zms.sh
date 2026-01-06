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
DEAFULT_ZMS_CM="athenz-zms-conf"

echo ""

# Namespace
read -p "👉 Athenz ZMS Server Namespace? [Hit enter for default: $DEFAULT_NS]: " INPUT_NS
NAMESPACE=${INPUT_NS:-$DEFAULT_NS}

# Deployment Name
read -p "👉 Athenz ZMS Server Deployment Name in ns [$NAMESPACE]? [Hit enter for default: $DEFAULT_DEPLOY]: " INPUT_DEPLOY
ZMS_DEPLOYMENT=${INPUT_DEPLOY:-$DEFAULT_DEPLOY}

# ZMS Config Name
read -p "👉 Athenz ZMS Server ConfigMap Name in ns [$NAMESPACE]? [Hit enter for default: $DEAFULT_ZMS_CM]: " INPUT_ZMS_CM
ZMS_CM_NAME=${INPUT_ZMS_CM:-$DEAFULT_ZMS_CM}

echo -e "\n${CYAN}--- Summary ----------------------${NC}"
echo -e "Namespace             : ${GREEN}$NAMESPACE${NC}"
echo -e "Athenz ZMS Deployment : ${GREEN}$ZMS_DEPLOYMENT${NC}"
echo -e "ZMS ConfigMap Name    : ${GREEN}$ZMS_CM_NAME${NC}"
echo -e "Patch File            : ${GREEN}$PATCH_FILE${NC}"
echo -e "${CYAN}------------------------------------${NC}\n"

##################################################################
### Core LOGIC ###################################################
##################################################################

echo -e "📦 Applying Patch to ZMS and its config..."

# Modify zms configmap first:
PLUGIN_CONFIG_KEY="athenz.zms.notification_service_factory_class="
PLUGIN_CONFIG_LINE="${PLUGIN_CONFIG_KEY}com.mlajkim.athenz.AwsSesPlugin"
if kubectl get cm "$ZMS_CM_NAME" -n "$NAMESPACE" -o jsonpath='{.data.zms\.properties}' | grep -q "$PLUGIN_CONFIG_KEY"; then
  echo -e "${YELLOW}✋ Configuration Key [$PLUGIN_CONFIG_KEY] already exists in [$ZMS_CM_NAME]. Skipping update.${NC}"
else
  echo -e "🔧 Configuration not found. Appending to ConfigMap..."
# [CRITICAL FIX]
  # 1. Switched from 'sed' to 'perl' for cross-platform compatibility (MacOS/Linux).
  # 2. Used '~' as delimiter to avoid collision with '|' in "zms.properties: |".
  # 3. \n works correctly in perl on all platforms.
  kubectl get cm "$ZMS_CM_NAME" -n "$NAMESPACE" -o yaml | \
    perl -pe "s~zms.properties: \|~zms.properties: \|\n    ${PLUGIN_CONFIG_LINE}~" | \
    kubectl apply -f -

  echo -e "${GREEN}✅ ConfigMap [$ZMS_CM_NAME] updated successfully.${NC}"
fi


# Apply the patch using kubectl:
kubectl patch deployment "$ZMS_DEPLOYMENT" -n "$NAMESPACE" --patch-file "$PATCH_FILE"

# Allow restart, if config changed:
kubectl rollout restart deployment "$ZMS_DEPLOYMENT" -n "$NAMESPACE"
