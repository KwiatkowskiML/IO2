#!/bin/bash
set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

SEPARATOR=$(cat <<EOF
 _________________
< Praca, praca... >
 -----------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\_
                ||----w |
                ||     ||
EOF
)

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# Install/upgrade requirements
echo "Installing requirements..."
pip install -q --upgrade pip pytest requests colorama tabulate

# Set default environment variables
export API_BASE_URL="http://localhost:8080/api"
export API_GATE_URL="http://localhost:8080/"
export API_TIMEOUT="${API_TIMEOUT:-10}"

echo "Running tests through gateway..."
echo "API URL: $API_BASE_URL"
cd "$SCRIPT_DIR"
pytest -v "$@"

echo "$SEPARATOR"

echo "Running tests directly against AUTH API..."
export API_BASE_URL="http://localhost:8000" # AUTH service docker port
pytest -v test_auth.py
