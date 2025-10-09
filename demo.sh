#!/usr/bin/env bash

DEMO_START=$(date +%s)

TEMP_DIR="upgrade-example"

# Java version configuration
JAVA8_VERSION="8.0.462-librca"
JAVA25_VERSION="25-librca"

# Function to check if a command exists
check_dependency() {
  local cmd=$1
  local install_msg=$2
  
  if ! command -v "$cmd" &> /dev/null; then
    echo "$cmd not found. $install_msg"
    return 1
  fi
  return 0
}

# Check all required dependencies
check_dependencies() {
  local missing_deps=()
  
  # Check dependencies in parallel by storing results
  check_dependency "vendir" "Please install vendir first." || missing_deps+=("vendir")
  check_dependency "http" "Please install httpie first." || missing_deps+=("httpie")
  check_dependency "bc" "Please install bc first." || missing_deps+=("bc")
  check_dependency "git" "Please install git first." || missing_deps+=("git")
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing_deps[*]}"
    exit 1
  fi
  
  echo "All dependencies found."
}

# Load helper functions and set initial variables
check_dependencies

vendir sync
. ./vendir/demo-magic/demo-magic.sh
export TYPE_SPEED=100
export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
export PROMPT_TIMEOUT=6


# Stop ANY & ALL Java Process...they could be Springboot running on our ports!
function cleanUp {
	local npid=""

  npid=$(pgrep java)
  
 	if [ "$npid" != "" ] 
		then
  		
  		displayMessage "*** Stopping Any Previous Existing SpringBoot Apps..."		
			
			while [ "$npid" != "" ]
			do
				echo "***KILLING OFF The Following: $npid..."
		  	pei "kill -9 $npid"
				npid=$(pgrep java)
			done  
		
	fi
}

# Function to pause and clear the screen
function talkingPoint() {
  wait
  clear
}

# Check if Java version is already installed
check_java_installed() {
  local version=$1
  sdk list java | grep -q "$version" && sdk list java | grep "$version" | grep -q "installed"
}

# Initialize SDKMAN and install required Java versions
function initSDKman() {
  local sdkman_init
  sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$sdkman_init" ]]; then
    # shellcheck disable=SC1090
    source "$sdkman_init"
  else
    echo "SDKMAN not found. Please install SDKMAN first."
    exit 1
  fi
  
  echo "Updating SDKMAN..."
  sdk update
  
  # Install Java versions only if not already installed
  if ! check_java_installed "$JAVA8_VERSION"; then
    echo "Installing Java $JAVA8_VERSION..."
    sdk install java "$JAVA8_VERSION"
  else
    echo "Java $JAVA8_VERSION already installed."
  fi
  
  if ! check_java_installed "$JAVA25_VERSION"; then
    echo "Installing Java $JAVA25_VERSION..."
    sdk install java "$JAVA25_VERSION"
  else
    echo "Java $JAVA25_VERSION already installed."
  fi
}

# Prepare the working directory
function init {
  rm -rf "$TEMP_DIR"
  mkdir "$TEMP_DIR"
  cd "$TEMP_DIR" || exit
  clear
}

# Switch to Java 8 and display version
function useJava8 {
  displayMessage "Use Java 8, this is for educational purposes only, don't do this at home! (I have jokes.)"
  pei "sdk use java $JAVA8_VERSION"
  pei "java -version"
}

# Switch to Java 25 and display version
function useJava25 {
  displayMessage "Switch to Java 25 for Spring Boot 3"
  pei "sdk use java $JAVA25_VERSION"
  pei "java -version"
}

# Create a simple Spring Boot application
function cloneApp {
  displayMessage "Clone Spring Petclinic (2.7.3) application"
  pei "git clone https://github.com/dashaun/spring-petclinic.git ./"
}

# Start the Spring Boot application
function springBootStart {
  displayMessage "Start the Spring Boot application, Wait For It...."
  pei "./mvnw -q clean package spring-boot:start -Dfork=true -DskipTests 2>&1 | tee '$1' &"
  sleep 3
}

# Stop the Spring Boot application
function springBootStop {
  displayMessage "Stop the Spring Boot application"
  pei "./mvnw spring-boot:stop -Dspring-boot.stop.fork -Dfork=true"
}

# Check the health of the application
function validateApp {
  displayMessage "Check application health"
  pei "http :8080/actuator/health 2>/dev/null"
}

function validateApp_1_5 {
  displayMessage "Check application health"
  pei "http :8080/health 2>/dev/null"
}

# Display memory usage of the application
function showMemoryUsage {
  local pid=$1
  local log_file=$2
  local rss
  rss=$(ps -o rss= "$pid" | tail -n1)
  local mem_usage
  mem_usage=$(bc <<< "scale=1; ${rss}/1024")
  echo "The process was using ${mem_usage} megabytes"
  echo "${mem_usage}" >> "$log_file"
}

function advisorBuildConfig {
  displayMessage "Capture some metadata about the application with Advisor"
  pei "advisor build-config get"
}

function showBuildConfigKeys {
  displayMessage "Some interesting information from that step:"
  pei "cat target/.advisor/build-config.json | jq 'keys'"
  echo "^^^ The top level elements in the build-config.json file"
}

function showBuildConfigGitMetadata {
  pei "cat target/.advisor/build-config.json | jq '.\"git-metadata\"'"
  echo "^^^ Information about the git repository"
}

function showBuildConfigSBOMint {
  displayMessage "Some interesting information from that step:"
  pei "cat target/.advisor/build-config.json | jq '.sbom.components | length'"
  echo "^^^ That's the number of components included in the SBOM"
}

function showBuildConfigSubmodules {
  pei "cat target/.advisor/build-config.json | jq '.submodules'"
  echo "^^^ The Maven coordinates (groupId:artifactId) of the artifact(s)"
}

function showBuildConfigTools {
  pei "cat target/.advisor/build-config.json | jq '.tools'"
  echo "^^^ The tools and versions being used"
}

function advisorUpgradePlanGet {
  displayMessage "How hard could it be to upgrade? Let's get a plan!"
  pei "advisor upgrade-plan get"
}

function advisorUpgradePlanApplySquash {
  displayMessage "Do all the upgrades!"
  pei "advisor upgrade-plan apply --squash 8"
}

# Display a message with a header
function displayMessage() {
  echo "#### $1"
  echo ""
}

function startupTime() {
  echo "$(sed -nE 's/.* in ([0-9]+\.[0-9]+) seconds.*/\1/p' < $1)"
}

function showTheDiff() {
  echo "Look at all of changes made to properties, dependencies and code, with git diff."
  sleep 3
  pei "git --no-pager diff --no-prefix -U0"
}

function statsSoFarTableColored {
  displayMessage "Comparison of memory usage and startup times"
  echo ""

  # Define colors
  local WHITE='\033[1;37m'
  local GREEN='\033[1;32m'
  local BLUE='\033[1;34m'
  local NC='\033[0m' # No Color

  # Headers (White)
  printf "${WHITE}%-35s %-25s %-15s %s${NC}\n" "Configuration" "Startup Time (seconds)" "(MB) Used" "(MB) Savings"
  echo -e "${WHITE}--------------------------------------------------------------------------------------------${NC}"

  # Spring Boot 1.5 with Java 8 (Red - baseline)
  MEM1=$(cat java8with1.5.log2)
  START1=$(startupTime 'java8with1.5.log')
  printf "${RED}%-35s %-25s %-15s %s${NC}\n" "Spring Boot 2.7.3 with Java 8" "$START1" "$MEM1" "-"

  # Spring Boot 3.5 with Java25 (Green - improved)
  MEM2=$(cat java25with3.5.log2)
  PERC2=$(bc <<< "scale=2; 100 - ${MEM2}/${MEM1}*100")
  START2=$(startupTime 'java25with3.5.log')
  PERCSTART2=$(bc <<< "scale=2; 100 - ${START2}/${START1}*100")
  printf "${GREEN}%-35s %-25s %-15s %s ${NC}\n" "Spring Boot 3.5 with Java 25" "$START2 ($PERCSTART2% faster)" "$MEM2" "$PERC2%"

  echo -e "${WHITE}--------------------------------------------------------------------------------------------${NC}"
  DEMO_STOP=$(date +%s)
  DEMO_ELAPSED=$((DEMO_STOP - DEMO_START))
  echo ""
  echo ""
  echo -e "${BLUE}Demo elapsed time: ${DEMO_ELAPSED} seconds${NC}"
}

# Main execution flow

cleanUp
initSDKman
init
useJava8
talkingPoint
cloneApp
talkingPoint
springBootStart java8with1.5.log
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'PetClinicApplication' | cut -d ' ' -f 1)" java8with1.5.log2
talkingPoint
springBootStop
talkingPoint
advisorBuildConfig
talkingPoint
showBuildConfigKeys
talkingPoint
showBuildConfigGitMetadata
talkingPoint
showBuildConfigSBOMint
talkingPoint
showBuildConfigSubmodules
talkingPoint
showBuildConfigTools
talkingPoint
advisorUpgradePlanGet
talkingPoint
advisorUpgradePlanApplySquash
talkingPoint
useJava25
talkingPoint
springBootStart java25with3.5.log
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'PetClinicApplication' | cut -d ' ' -f 1)" java25with3.5.log2
talkingPoint
springBootStop
talkingPoint
showTheDiff
talkingPoint
statsSoFarTableColored
