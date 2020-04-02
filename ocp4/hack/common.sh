#!/usr/bin/bash

ocp:log:error() {
  local RED='\033[0;31m'
  NC='\033[0m'
  printf "${RED}ERROR: $1${NC}\n" >&2
}

ocp:log:warning() {
  local YELLOW='\033[1;33m'
  NC='\033[0m'
  printf "${YELLOW}WARNING: $1${NC}\n"  >&2
}

ocp:log:info() {
  local GREEN='\033[0;32m'
  NC='\033[0m'
  printf "${GREEN}INFO: $1${NC}\n" >&2
}