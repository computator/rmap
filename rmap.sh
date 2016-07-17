#!/bin/sh
command=${1:?Command is required}
shift
if [ "$command" = "clone" ]; then
	prefix=${1:?Prefix is required}
	shift
	[ "${prefix}" = "${prefix%?}/" ] || prefix="$prefix/"
fi

while read target src repo || [ -n "$target" ]; do
	[ -n "$target" ] || [ "${target}" = "#${target#?}" ] || continue

	echo "--- $target ---"
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		hg clone "$repo$src" "$target" "$@"
	else
		hg -R "$target" "$command" "$@"
	fi
done < repo.map