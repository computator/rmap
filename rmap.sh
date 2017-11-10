#!/bin/sh
HG=${HG:-hg}
MAPNAME=${MAPNAME:-.repomap}

usage () {
	self=$(basename "$0")
	cat <<-HELP
		Usage: $self [-q] [options] [--] clone <prefix> [arg] ...
		       $self [-q] [options] [--] <command> [arg] ...

		Options:
		  -q,  --quiet		Don't show the current repo header before running commands

	HELP
	exit 2
}

opts=$(getopt -n $(basename "$0") -s sh -o +rqh -l recursive,quiet,help -- "$@")
[ $? -eq 0 ] || usage
eval set -- "$opts"
for opt; do
	[ "$opt" = "-h" -o "$opt" = "--help" ] && usage;
	[ "$opt" = "--" ] && break;
done
unset quiet
while [ "$1" != "--" ]; do
	case "$1" in
		-q|--quiet)
			quiet=1 ;;
	esac
	shift
done
shift

[ -n "$1" ] || usage
command="$1"
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

	[ -z $quiet ] && echo "--- $target ---"
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		[ -d "$ROOT/$target" ] || mkdir -p "$ROOT/$target"
		$HG clone "$repo$src" "$ROOT/$target" "$@"
	else
		$HG -R "$ROOT/$target" "$command" "$@"
	fi
done
