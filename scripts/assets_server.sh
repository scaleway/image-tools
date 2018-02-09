#! /bin/bash

exec >/dev/null 2>&1

if [ "$1" = "start" ]; then
    cd $3 && python3 -m http.server $2 &
else
    kill $(lsof -i :$2 -t | tr '\n' ' ')
fi
