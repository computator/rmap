#!/bin/sh
HG=${HG:-hg}
MAPNAME=${MAPNAME:-.repomap}

usage () {
	self=$(basename "$0")
	cat <<-HELP
		Usage: $self [-qr] [options] [--] clone <prefix> [arg] ...
		       $self [-qr] [options] [--] <command> [arg] ...

		Options:
		  -q,  --quiet		Don't show the current repo header before running commands
		  -r,  --recursive	Run command with mapfiles in subdirectories as well

	HELP
	exit 2
}

opts=$(getopt -n $(basename "$0") -s sh -o +rqh -l recursive,quiet,help,recurse-internal -- "$@")
[ $? -eq 0 ] || usage
eval set -- "$opts"
unset subrecurse
for opt; do
	[ "$opt" = "--recurse-internal" ] && subrecurse=1 && break;
	[ "$opt" = "-h" -o "$opt" = "--help" ] && usage;
	[ "$opt" = "--" ] && break;
done

if [ $subrecurse ]; then
	# while [ "$1" != "--" ]; do shift; done
	# shift
	# [ "$command" != "clone" ] || shift
	eval set -- "$subopts"
else
	unset quiet recurse
	while [ "$1" != "--" ]; do
		case "$1" in
			-q|--quiet)
				quiet=1 ;;
			-r|--recursive)
				recurse=1 ;;
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

	[ $recurse ] && export quiet recurse command prefix
fi

if [ ! -e "$ROOT/$MAPNAME" ]; then
	echo "$MAPNAME not found!" >&2
	exit 1
fi

exec 3< "$ROOT/$MAPNAME" # assign the map file to fd 3
while read target src repo <&3 || [ -n "$target" ]; do
	[ -n "$target" ] || [ "${target}" = "#${target#?}" ] || continue

	[ ! $quiet ] && echo "--- $target ---"
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		[ -d "$ROOT/$target" ] || mkdir -p "$ROOT/$target"
		$HG clone "$repo$src" "$ROOT/$target" "$@"
	else
		$HG -R "$ROOT/$target" "$command" "$@"
	fi
done

if [ ! $subrecurse ] && [ $recurse ]; then
	export subopts="$@"
	pfile=$(mktemp) || exit 1
	trap "rm -f '$pfile'" EXIT
	while true; do
		nlines=$(wc -l "$pfile" | cut -f 1 -d " ")
		for path in $(find -mindepth 2 -type f -name "$MAPNAME" ); do
			path=$(dirname "$path")
			grep -qFxe "$path" "$pfile" && continue
			ROOT="$path" "$0" --recurse-internal
			echo "$path" >> "$pfile"
		done
		[ $(wc -l "$pfile" | cut -f 1 -d " ") -gt $nlines ] || break
	done
	rm -f "$pfile"
	trap - EXIT
fi