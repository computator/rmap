#!/bin/sh
HG=${HG:-hg}
command=${1:?Command is required}
shift
if [ "$command" = "clone" ]; then
	prefix=${1:?Prefix is required}
	shift
	[ "${prefix}" = "${prefix%?}/" ] || prefix="$prefix/"
fi

while [ ! -e "${ROOT:=$(pwd)}/repo.map" ] && [ "${ROOT:=$(pwd)}" != "/" ]; do
	ROOT="$(dirname "$ROOT")"
done

if [ ! -e "$ROOT/repo.map" ]; then
	echo "repo.map not found!" >&2
	exit 1
fi

exec 3< "$ROOT/repo.map" # assign the map file to fd 3
while read target src repo <&3 || [ -n "$target" ]; do
	[ -n "$target" ] || [ "${target}" = "#${target#?}" ] || continue

	echo "--- $target ---"
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		[ -d "$ROOT/$target" ] || mkdir -p "$ROOT/$target"
		$HG clone "$repo$src" "$ROOT/$target" "$@"
	else
		$HG -R "$ROOT/$target" "$command" "$@"
	fi
done
