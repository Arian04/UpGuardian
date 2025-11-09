#!/usr/bin/env bash

(
	cd ./demo_backend &&
		uv run -- demo-backend 1
) &
(
	cd ./demo_backend &&
		uv run -- demo-backend 2
) &
(
	sleep 3s
	cd ./backend &&
		uv run -- upguardian-backend cli 1
) &

wait
