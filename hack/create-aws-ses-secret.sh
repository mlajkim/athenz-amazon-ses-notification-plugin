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
echo -e "${CYAN}       🔐 AWS SES Secret Creation Wizard       ${NC}"
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
DEFAULT_SECRET_NAME="aws-ses-secret"

# SMTP Username, with quick trim & not empty check
read -p "👉 Your AWS SES SMTP Username: " SMTP_USERNAME
TRIMMED_SMTP_USERNAME=$(echo -e "${SMTP_USERNAME}" | tr -d '[:space:]')
if [ -z "${TRIMMED_SMTP_USERNAME}" ]; then
  echo -e "${RED}[Error] SMTP Username cannot be empty!${NC}"
  exit 1
fi

# SMTP Password, with quick trim & not empty check
read -s -p "👉 Your AWS SES SMTP Password: " SMTP_PASSWORD
TRIMMED_SMTP_PASSWORD=$(echo -e "${SMTP_PASSWORD}" | tr -d '[:space:]')
if [ -z "${TRIMMED_SMTP_PASSWORD}" ]; then
  echo -e "${RED}[Error] SMTP Password cannot be empty!${NC}"
  exit 1
fi

# 2. Namespace
read -p "👉 Target K8s Namespace? [Hit enter for default: athenz]: " INPUT_NS
NAMESPACE=${INPUT_NS:-$DEFAULT_NS}

# Secret Name
read -p "👉 K8s Secret Name to create? [Hit enter for default: $DEFAULT_SECRET_NAME]: " INPUT_SECRET
SECRET_NAME=${INPUT_SECRET:-$DEFAULT_SECRET_NAME}

##################################################################
### Core LOGIC ###################################################
##################################################################

echo -e "👷 Creating a new package..."
kubectl create secret generic "$SECRET_NAME" \
  --from-literal=username="$TRIMMED_SMTP_USERNAME" \
  --from-literal=password="$TRIMMED_SMTP_PASSWORD" \
  -n "$NAMESPACE"