#!/usr/bin/env bash

cd functions || exit
faas up -f syncmesh-fn-local.yml
