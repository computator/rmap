#!/bin/sh
HG=${HG:-hg}
MAPNAME=${MAPNAME:-.repomap}

usage () {
	self=$(basename "$0")
	cat <<-HELP
		Usage: $self [-qr1] [options] [--] clone <prefix> [arg] ...
		       $self [-qr1] [options] [--] <command> [arg] ...

		Options:
		  -q,  --quiet		Don't show the current repo header before running commands
		  -r,  --recursive	Run command with mapfiles in subdirectories as well
		  -1			One line format. Repo headers are easy to parse and are on the
					  same line as the command's output.
		       --color[=WHEN]	Colorize the current repo headers 'always', 'never', or 'auto'

	HELP
	exit 2
}

opts=$(getopt -n $(basename "$0") -s sh -o +rq1h -l recursive,quiet,help,color::,recurse-internal -- "$@")
[ $? -eq 0 ] || usage
eval set -- "$opts"
unset subrecurse
for opt; do
	[ "$opt" = "--recurse-internal" ] && subrecurse=1 && break;
	[ "$opt" = "-h" -o "$opt" = "--help" ] && usage;
	[ "$opt" = "--" ] && break;
done

if [ $subrecurse ]; then
	while [ "$1" != "--" ]; do shift; done
	shift
else
	unset quiet recurse oneline coloropt
	while [ "$1" != "--" ]; do
		case "$1" in
			-q|--quiet)
				quiet=1 ;;
			-r|--recursive)
				recurse=1 ;;
			-1)
				oneline=1 ;;
			--color)
				shift
				if [ -z "$1" ]; then
					coloropt="always"
				else
					coloropt="$1"
				fi
				;;
		esac
		shift
	done
	shift

	unset color
	if [ -z "$coloropt" -o "$coloropt" = "auto" ]; then
		[ -t 1 ] && color=1
	elif [ "$coloropt" = "always" ]; then
		color=1
	fi

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

	[ $recurse ] && export quiet recurse oneline color command prefix
fi

if [ ! -e "$ROOT/$MAPNAME" ]; then
	echo "$MAPNAME not found!" >&2
	exit 1
fi

unset c_cyan c_clr
unset a_bold a_dim a_clr
if [ $color ]; then
	c_cyan=$(tput setaf 6)
	c_clr=$(tput op)

	a_bold=$(tput bold)
	a_dim=$(tput dim)
	a_clr=$(tput sgr0)
fi

exec 3< "$ROOT/$MAPNAME" # assign the map file to fd 3
while read target src repo <&3 || [ -n "$target" ]; do
	[ -n "$target" ] || [ "${target}" = "#${target#?}" ] || continue

	if [ ! $quiet ]; then
		if [ $oneline ]; then
			if [ $subrecurse ]; then
				echo -n "${ROOT#"$orig_root"}/$target:"
			else
				echo -n "$target:"
			fi
		else
			if [ $subrecurse ]; then
				echo "$a_bold$c_cyan=== $a_dim${ROOT#"$orig_root"} :$a_clr$a_bold$c_cyan $target ===$a_clr"
			else
				echo "$a_bold$c_cyan=== $target ===$a_clr"
			fi
		fi
	fi
	if [ "$command" = "clone" ]; then
		[ -n "$src" ] || src="$target"
		[ -n "$repo" ] || repo="$prefix"
		[ -d "$ROOT/$target" ] || mkdir -p "$ROOT/$target"
		if [ $oneline ]; then
			# use echo to make sure a newline is added
			echo "$($HG clone "$repo$src" "$ROOT/$target" "$@")"
		else
			$HG clone "$repo$src" "$ROOT/$target" "$@"
		fi
	else
		if [ $oneline ]; then
			# use echo to make sure a newline is added
			echo "$($HG -R "$ROOT/$target" "$command" "$@")"
		else
			$HG -R "$ROOT/$target" "$command" "$@"
		fi
	fi
done

if [ ! $subrecurse ] && [ $recurse ]; then
	export orig_root="${ROOT%/}/"
	pfile=$(mktemp) || exit 1
	trap "rm -f '$pfile'" EXIT
	while true; do
		nlines=$(wc -l "$pfile" | cut -f 1 -d " ")
		for path in $(find $ROOT -depth -mindepth 2 -type f -name "$MAPNAME" | tac); do
			path=$(dirname "$path")
			grep -qFxe "$path" "$pfile" && continue
			ROOT="$path" "$0" --recurse-internal -- "$@"
			echo "$path" >> "$pfile"
		done
		[ $(wc -l "$pfile" | cut -f 1 -d " ") -gt $nlines ] || break
	done
	rm -f "$pfile"
	trap - EXIT
fi