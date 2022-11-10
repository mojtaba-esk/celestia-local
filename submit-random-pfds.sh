#!/bin/bash

set -o errexit -o nounset
source .env

#------------------------#

function rand_nid {
  echo $RANDOM | md5sum | head -c 16; echo;
}

#------------------------#

function rand_msg {
  
  MSG_LEN=$(($RANDOM%10+1))

  for (( i=0; i<MSG_LEN; i++)); 
  do   
    echo $RANDOM | sha256sum | head -c 64
  done
  
}

#------------------------#

function submit_pfd {

  NID=$(rand_nid)
  DATA=$(rand_msg)
  TX=$(curl -s -X POST -d "{\"namespace_id\": \"${NID}\", \"data\": \"${DATA}\", \"gas_limit\": 70000}" ${NODE_RPC_URL}/submit_pfd)

  HEIGHT=$(echo ${TX} | jq ".height")
  TXHASH=$(echo ${TX} | jq ".txhash" | tr -d \")

  echo -e "${HEIGHT} ${TXHASH}"

}

#------------------------#


while true;
do

  PDF_TX_NUM=$(($RANDOM%20+1))
  echo -e "Submiting ${PDF_TX_NUM} PDFs...\n"

  for (( i=0; i<PDF_TX_NUM; i++)); 
  do   
    RES=$(submit_pfd)
    echo -e "\t${RES}"
  done

  SLEEP_TIME=$(($RANDOM%5+1))
  echo -e "\nWaiting ${SLEEP_TIME} seconds..."
  sleep ${SLEEP_TIME}

done


#------------------------#