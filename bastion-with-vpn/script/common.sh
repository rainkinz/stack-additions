#!/bin/bash

private_key_path() {
  local keypath = $(terraform output bastion.private_key_path 2> /dev/null)
  if [ $? ne 0 ]; then
    echo "Could not get private key path"
    exit 1
  fi
  echo $keypath
}


function val() {
  local key=$1
  local val=$(terraform output $key 2> /dev/null)
  if [ "$val" == "" ]; then
    echo "Could not find value for $key. Check terraform apply"
    exit 1
  fi
  echo $val
}

function debug() {
  if [ "$VERBOSE" == "true" ]; then
    echo $1
  fi
}

