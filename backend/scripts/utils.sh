#!/bin/bash

# Create and print a separator line
create_separator() {
  _cols=$(stty size | cut -d' ' -f2)
  printf '%*s\n' "$_cols" '' | tr ' ' '='
}

# color codes - ANSI escape sequences
# These can be used to colorize the output of echo
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'
RESET='\e[0m'
BOLD='\e[1m'
UNDERLINE='\e[4m'
