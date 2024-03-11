#!/usr/bin/env bash

set -ex

pip install .

for cmd in lab expect; do
    if ! type -p $cmd; then
        echo "Error: $cmd is not installed"
        exit 1
    fi
done

PID=

cleanup() {
    set +e
    if [ -n "$PID" ]; then
        kill $PID
    fi
}

trap cleanup 0

rm -f config.yaml

# pipe 3 carriage returns to lab init to get past the prompts
echo -e "\n\n\n" | lab init

# download the latest version of the lab
lab download

# check that lab serve is working
# catch ERROR strings in the output
expect -c '
spawn lab serve
expect {
    "ERROR" { exit 1 }
    eof
}
'

python -m http.server 8000 &
PID=$!

# check that lab serve is detecting the port is already in use
# catch 'error while attempting to bind on address ('127.0.0.1', 8000): address already in use' strings in the output
expect -c '
spawn lab serve
expect {
    "error while attempting to bind on address " { exit 0 }
    eof
'

# configure a different port
sed -i 's/8000/9999/g' config.yaml

# check that lab serve is working on the new port
# catch ERROR strings in the output
expect -c '
spawn lab serve
expect {
    "ERROR" { exit 1 }
    "http://localhost:9999/docs" { exit 0}
    eof
}
'

exit 0