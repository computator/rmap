#!/bin/sh
HG=${HG:-hg}
MAPNAME=${MAPNAME:-.repomap}
command=${1:?Command is required}
shift
if [ "$command" = "clone" ]; then
	prefix=${1:?Prefix is required}
	shift
	[ "${prefix}" = "${prefix%?}/" ] || prefix="$prefix/"
fi

while [ ! -e "${ROOT:=$(pwd)}/$MAPNAME" ] && [ "${ROOT:=$(pwd)}" != "/" ]; do
	ROOT="$(dirname "$ROOT")"
done

if [ ! -e "$ROOT/$MAPNAME" ]; then
	echo "$MAPNAME not found!" >&2
	exit 1
fi

exec 3< "$ROOT/$MAPNAME" # assign the map file to fd 3
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
