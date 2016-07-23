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

while read target src repo || [ -n "$target" ]; do
	[ -n "$target" ] || [ "${target}" = "#${target#?}" ] || continue

	echo "--- $target ---"
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		hg clone "$repo$src" "$root/$target" "$@"
	else
		hg -R "$root/$target" "$command" "$@"
	fi
done < "$root/repo.map"