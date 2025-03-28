#!/bin/bash
export GOOGLE_APPLICATION_CREDENTIALS=./credentials.json
terraform "$@"

