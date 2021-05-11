#!/bin/bash

__tilt_ps1()
{
  die() {
    echo "$*" 1>&2
    exit 1
  }
  
  if ! type jq > /dev/null; then
    die "error: jq not on path"
  fi
  
  STATUS_JSON="$(tilt get session -ojson 2> /dev/null)"
  if [[ $? != 0 ]]; then
    exit 0
  fi
  
  # echo "$STATUS_JSON" | jq -C '.'
  RESOURCE_STATUSES="$(echo "$STATUS_JSON" | jq -r '.items[].status.targets[] | "\(.name) \(.type) \(.state | keys[0]) \(.state.terminated | has("error")) \(.state.active.ready)"')"
  
  status() {
    local NAME="$1" TYPE="$2" STATE="$3" ISERROR="$4" ISREADY="$5"
    local STATUS
    case $TYPE in
      job)
        case $STATE in
          active)
            STATUS=pending
            ;;
          terminated)
            if [[ $ISERROR == false ]]; then
              STATUS=healthy
            else
              STATUS=unhealthy
            fi
            ;;
          waiting)
            STATUS=pending
            ;;
          *)
            die "error: resource $NAME had unexpected state $STATE"
            ;;
        esac
        ;;
      server)
        case $STATE in
          active)
            if [[ $ISREADY == true ]]; then
              STATUS=healthy
            else
              STATUS=pending
            fi
            ;;
          terminated)
            STATUS=unhealthy
            ;;
          waiting)
            STATUS=pending
            ;;
          *)
            die "error: resource $NAME had unexpected state $STATE"
            ;;
        esac
        ;;
      *)
        die "error: resource $NAME had unknown type $TYPE"
        ;;
    esac
    echo "$STATUS"
  }
  
  HEALTHY_COUNT=0
  PENDING_COUNT=0
  UNHEALTHY_COUNT=0
  TOTAL_COUNT=0
  while IFS=" " read -r NAME TYPE STATE ISERROR ISREADY
  do
    STATUS="$(status "$NAME" "$TYPE" "$STATE" "$ISERROR" "$ISREADY")"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    case $STATUS in
      healthy)
        HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
        ;;
      unhealthy)
        UNHEALTHY_COUNT=$((UNHEALTHY_COUNT + 1))
        ;;
      pending)
        PENDING_COUNT=$((PENDING_COUNT + 1))
        ;;
      *)
        die "internal error: calculated unhandled status $STATUS"
        ;;
    esac
  done < <(echo "$RESOURCE_STATUSES")
  
  RED="\033[01;31m"
  GREEN="\033[01;32m"
  WHITE="\033[01;37m"
  RESET="\033[00m"
  
  OUTPUT=()
  if [[ $PENDING_COUNT -gt 0 ]]; then
    OUTPUT+=("${WHITE}⌛${PENDING_COUNT}${RESET}")
  fi
  if [[ $UNHEALTHY_COUNT -gt 0 ]]; then
    OUTPUT+=("${RED}🚩${UNHEALTHY_COUNT}${RESET}")
  fi
  OUTPUT+=("${GREEN}✔ ${HEALTHY_COUNT}${RESET}/${TOTAL_COUNT}")
  IFS=" " echo -e "(tilt:${OUTPUT[*]})"
}
