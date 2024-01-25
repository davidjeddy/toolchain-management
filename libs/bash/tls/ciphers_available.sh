#!/usr/bin/env bash

# example /path/to/project/libs/bash/tls/ciphers_available.sh admintool.preprod.connect.worldline-solutions.com 443
# source https://stackoverflow.com/questions/24457408/openssl-command-to-check-if-a-server-is-presenting-a-certificate
# source https://superuser.com/questions/109213/how-do-i-list-the-ssl-tls-cipher-suites-a-particular-website-offers
# usage /path/to/project/libs/bash/tls/ciphers_available.sh IP PORT

## Constants

CIPHERS=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')
DELAY=1

## Vars

declare SERVER
SERVER=$1
declare PORT
PORT=$2

## Pre-flight

if [[ -f ${SERVER}_cipher_status.log ]]
then
  rm -rf "${SERVER}_cipher_status.log"
fi

## Logic

if [[ $SERVER =~ https* ]]
then
  printf "INFO: ERR: Do not include protocol (HTTPS/HTTP/etc) in address."
  exit 1
fi

printf "INFO: Obtaining cipher list from %s.\n" "$(openssl version)"

# shellcheck disable=SC2068
for CIPHER in ${CIPHERS[@]}
do
  result=$(openssl s_client -cipher "${CIPHER}" -connect "$SERVER:$PORT" 2>&1)

  printf "INFO: Testing cipher %s...\n" "${CIPHER}" | tee --append "${SERVER}_cipher_status.log"

  # shellcheck disable=SC2076
  if [[ "$result" =~ "Cipher is ${CIPHER}" || "$result" =~ "Cipher    :" ]]
  then
    printf  "INFO: ... is available\n" | tee --append "${SERVER}_cipher_status.log"
  elif [[ "$result" =~ ":error:" ]]
  then
    printf "INFO:... is NOT availalbe\n" | tee --append "${SERVER}_cipher_status.log"
  else
    printf "INFO: ... returned unhandled response\n" | tee --append "${SERVER}_cipher_status.log"
  fi

  sleep $DELAY
done
