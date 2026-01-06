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
DEFAULT_DB_POD_NAME="athenz-db-0"
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
### User Guide ###################################################
##################################################################

EXPLANATION_STEPS=(
  "👋  Hi! Let me briefly explain how this test scenario works."
  "💡  Athenz sends notifications on startup, but enforces a 24-hour cooldown (v1.12.31 logic)."
  "⏳  Since the last notification time is saved, we normally have to wait 24 hours."
  "😈  But we can't wait! We will connect to the DB and NULLIFY the last notification timestamp."
  "🔄  Then, we'll restart the ZMS server to force the notification trigger check."
  "📜  We will automatically tail the ZMS logs to verify the trigger."
  "📧  Finally, please check your personal email inbox manually."
)

echo -e "\n${YELLOW}--- [Scenario Briefing] ----------------------${NC}"
for step in "${EXPLANATION_STEPS[@]}"; do
  echo -e "$step"
  sleep 3  # Pause for 1 second for dramatic effect & readability
done
echo -e "${YELLOW}----------------------------------------------${NC}\n"

##################################################################
### Core LOGIC ###################################################
##################################################################

echo -e "🚀 Starting the sequence..."

DB_NAME=zms_server

SQL_UPDATE="USE ${DB_NAME}; UPDATE pending_role_member SET last_notified_time = NULL;"
SQL_SELECT="USE ${DB_NAME}; SELECT role_id, principal_id, req_time, last_notified_time, server FROM pending_role_member;"

# Show current record
echo -e "🔍 Connecting to $DB_POD_NAME to show current notification records..."
kubectl exec -i "$DB_POD_NAME" -n "$NAMESPACE" -- mariadb -u"$DB_USER" "$DB_PASS" "$DB_NAME" -e "$SQL_SELECT"

# Nullify last notification timestamp in DB:
echo -e "🛠  Connecting to $DB_POD_NAME to nullify notification record..."
kubectl exec -i "$DB_POD_NAME" -n "$NAMESPACE" -- mariadb -u"$DB_USER" "$DB_PASS" "$DB_NAME" -e "$SQL_UPDATE"
sleep 1 # Small pause for DB update to take effect

# See the updated record:
echo -e "🔍 Verifying the update in $DB_POD_NAME..."
kubectl exec -i "$DB_POD_NAME" -n "$NAMESPACE" -- mariadb -u"$DB_USER" "$DB_PASS" "$DB_NAME" -e "$SQL_SELECT"

# Restart ZMS Deployment:
echo -e "🔄 Restarting ZMS Deployment ($ZMS_DEPLOYMENT)..."
kubectl rollout restart deployment "$ZMS_DEPLOYMENT" -n "$NAMESPACE"

# echo -e "👀 Watching logs... (Hit ^ + c to quit)"
# kubectl logs -f deployment/"$ZMS_DEPLOYMENT" -n "$NAMESPACE"
