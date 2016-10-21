#!/bin/sh
command=${1:?Command is required}
shift
if [ "$command" = "clone" ]; then
	prefix=${1:?Prefix is required}
	shift
	[ "${prefix}" = "${prefix%?}/" ] || prefix="$prefix/"
fi

while [ ! -e "${root:=$(pwd)}/repo.map" ] && [ "${root:=$(pwd)}" != "/" ]; do
	root="$(dirname "$root")"
done

if [ ! -e "$root/repo.map" ]; then
	echo "repo.map not found!" >&2
	exit 1
fi

exec 3<&0 # save current stdin for using below
while read target src repo || [ -n "$target" ]; do
	[ -n "$target" ] || [ "${target}" = "#${target#?}" ] || continue

	echo "--- $target ---"
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		[ -d "$root/$target" ] || mkdir -p "$root/$target"
		hg clone "$repo$src" "$root/$target" "$@" <&3
	else
		hg -R "$root/$target" "$command" "$@" <&3
	fi
done < "$root/repo.map"
