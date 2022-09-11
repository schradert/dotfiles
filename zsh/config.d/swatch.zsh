swatch_usage() {
    cat <<EOF >&2
NAME
       swatch - execute a program periodically with "watch". Supports aliases.

SYNOPSIS
       swatch [options] command

OTIONS
       -n, --interval seconds (default: 1)
              Specify update interval.  The command will not allow quicker than 
              0.1 second interval.
EOF
}

swatch() {
    if [ $# -eq 0 ]; then
        swatch_usage
        return 1
    fi
    seconds=1

    case "$1" in
    -n)
        seconds="$2"
        args=${*:3}
        ;;
    -h)
        swatch_usage
        return 1
        ;;
    *)
        seconds=1
        args=${*:1}
        ;;

    esac

    watch --color -n "$seconds" --exec bash -ic "$args || true"
}


