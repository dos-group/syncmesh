#!/usr/bin/env bash

cd functions || exit
faas up -f graphql-handler.yml
