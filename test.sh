#!/usr/bin/env bash

(
	cd ./demo_backend &&
		uv run -- demo-backend 1
) &
(
	cd ./demo_backend &&
		uv run -- demo-backend 2
) &

sleep 3s
cd ./backend || exit

uv run -- upguardian-backend cli 1
ret=$?

jobs -p | xargs kill

wait

exit $ret
