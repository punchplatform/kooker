#!/bin/bash -u
# This files contains reusable, project-independant shell functions

## COLORS ##
# use printf "${red}string in red${clrend}" for example
clrend=$'\e[0m'
wht=$'\e[97m'
red=$'\e[31m'
grn=$'\e[32m'
blu=$'\e[34m'
yel=$'\e[33m'
mag=$'\e[35m'
cyn=$'\e[36m'
gry=$'\e[37m'
# bold
bred=$'\e[1;31m'
bgrn=$'\e[1;32m'
bblu=$'\e[1;34m'
byel=$'\e[1;33m'
bmag=$'\e[1;35m'
bcyn=$'\e[1;36m'

#
# Returns the platform you are running on: mac or linux.
# As of today supports only linux or mac/Darwin.
#
# Arguments : none
# Usage     : platform=$(getPlatform)
#
function getPlatform() {
  local platform='unknown'
  local unamestr=$(uname)
  if [[ "$unamestr" == 'Linux' ]]; then
    platform='linux'
  elif [[ "$unamestr" == 'Darwin' ]]; then
    platform='mac'
  fi
  echo $platform
}
platform=$(getPlatform)

# A portable replace function. It uses perl instead of sed to avoid
# difference between macos native sed and linux one. 
# 
# Usage: replaceInPlace "this" "that" /tmp/file
function replaceInPlace() {
  declare from="$1" to="$2" file="$3"
  perl -i -pe's/$from/$to/g' $file
}

#
# execute a macos/linux portable sed command. This only supports sed in place.
#
function fpunch_sed_i() {
  if [ "$platform" == "mac" ]; then
    sed -i '' "$1" "$2"
  else
    sed -i "$1" "$2"
  fi
}

#this function is a filter used to drop output in quiet mode
function stdout() { if [ "${quiet:-}" != "true" ]; then cat; else true; fi; }
#this function is a filter used to redirect standard output from a command to error output
function stderr() { cat >&2; }

function debugTimestamp() { date +%Y%m%d%H%M%S; }

#this function is a filter used to redirect standard output from a command to common shells log flow
function commonsLogger() {
  if [ -z "${COMMONS_LOG_FILE:-}" ]; then
    stdout
  else
    caller=$(basename "$0" 2>/dev/null)
    if [ "$caller" == "" ]; then
      caller=">$0"
    fi
    export caller
    export timestamp=$(debugTimestamp)
    #sed "s#^#$(debugTimestamp) @ ${caller} : #g" >> "${COMMONS_LOG_FILE}"
    rotateLogIfNeededBySize
    awk '{printf("%s @ %s : %s\n",ENVIRON["timestamp"], ENVIRON["caller"],$0)}' >>"${COMMONS_LOG_FILE}"
  fi
}

function errorLogger() {
  if [ -z "${COMMONS_LOG_FILE:-}" ]; then
    stderr
  else
    caller=$(basename "$0" 2>/dev/null)
    if [ "$caller" == "" ]; then
      caller=">$0"
    fi
    export caller
    export timestamp=$(debugTimestamp)
    awk '{printf("%s @ %s stderr: %s\n",ENVIRON["timestamp"], ENVIRON["caller"],$0)}' >>"${COMMONS_LOG_FILE}"
    #		sed "s#^#$(debugTimestamp) @ ${caller} ERROR : #g" >> "${COMMONS_LOG_FILE}"
  fi

}

#this function sends outputonly  to COMMONS_LOG_FILE (if defined) OR STDOUT if not defined
function silentLog() { echo "$*" | commonsLogger; }
function unquietableLog() { quiet="false" log $@; }

# this function sends output both to stdout AND  to COMMONS_LOG_FILE (if defined)
# option -n can be provided to avoid addition of final carriage return
# option -- can be provided to request log processing from stdin
function log() {
  local echoOpt=""
  if [ "${1:-}" == "-n" ]; then
    local echoOpt="-n"
    shift
  fi
  if [ "${1:-}" == "--" ]; then
    if ! [ -z "${COMMONS_LOG_FILE:-}" ]; then
      tee >(commonsLogger) | stdout
    else
      commonsLogger
    fi
  else
    echo -e ${echoOpt} "$@" | stdout
    # the following 'if' is intended to avoid duplicate logging to stdout in case we do not have a punchplatform log file
    if ! [ -z "${COMMONS_LOG_FILE:-}" ]; then silentLog "$*"; fi
  fi
}

function errecho() {
  echo "$@" >&2
  if ! [ -z "${COMMONS_LOG_FILE:-}" ]; then echo "$@" | errorLogger; fi
}

#
# return a string with filename:line-number of the caller (from bash stack)
# This is handy for all error traces.
#
# @return a string.
#
function shortBashContext() {
  local bashRootCommand=$(basename ${0:-} 2>/dev/null)
  local framesToIgnore=${1:-0}
  local bashFile=$(basename ${BASH_SOURCE[$((2 + framesToIgnore))]} 2>/dev/null)
  local bashLineNum=${BASH_LINENO[$((1 + framesToIgnore))]}
  local bashFuncName=${FUNCNAME[$((2 + framesToIgnore))]}

  # Cedric ? a less verbose version here ..
  if [ "$bashRootCommand" == "$bashFile" ]; then
    computedShortContext="$bashFile:$bashLineNum"
  else
    computedShortContext="$bashRootCommand:$bashFile:$bashLineNum"
  fi
  echo "$computedShortContext"

  #computedShortContext="while running '$bashRootCommand', at line $bashLineNum in function $bashFuncName () in file '$bashFile'."
  #echo "$computedShortContext"
}
function red() { errecho "$(FG RED "$@")"; }
function green() { errecho "$(FG GREEN "$@")"; }
function yellow() { errecho "$(FG YELLOW "$@")"; }
function info() { errecho "$(FG CYAN "$@")"; }
function warn() { errecho "$(FG YELLOW "WARNING: $@")"; }
function white() { errecho "$(FG WHITE "$@")"; }

function error() {
  local echoOpt=""
  if [ "${1:-}" == "-n" ]; then
    echoOpt="-n"
    shift
  fi
  if [ "${1:-}" == "--" ]; then
    if [ "${2:-}" == "--no-context" ]; then
      export errorContext=""
      shift
    else
      local nbFramesToIgnore=${2:-}
      export errorContext=$(DIMMED "$(shortBashContext $nbFramesToIgnore)")
    fi

    if ! [ -z "${COMMONS_LOG_FILE}" ]; then
      tee >(errorLogger) | awk '{printf("%s %s\n",$0,ENVIRON["errorContext"])}' | stderr
    else
      errorLogger
    fi
  else
    if [ "${1:-}" == "--print-stack" ]; then
      local printStack=true
      shift
    fi
    if [ "${1:-}" == "--no-context" ]; then
      errorContext=""
      shift
    else
      errorContext=" $(shortBashContext)"
    fi
    errecho $(FG RED "ERROR: ${@}") $(DIMMED "${errorContext}")
    # quand il s'agit d'une erreur ponctuelle, et non d'une redirection de flux
    # (i.e. quand on n'a pas l'option --) on dumpe la stack bash
    if [ "${printStack:-}" == "true" ]; then
      bashStack | errorLogger
    fi
  fi
  return 1

}

function fatal() {
  errecho $(FG RED $(BOLD "FATAL ERROR: ${*:-generic error}")) $(DIMMED "$(shortBashContext)")
  if ! [ -z "${COMMONS_LOG_FILE:-}" ]; then
    echo "LOG: see $COMMONS_LOG_FILE for bash stack trace" 1>&2
    bashStack | errorLogger
  fi
  RESET_COLORS
  exit -1
}

# this function is used to catch stdout and stderr of the command, and
# send them respectively to the "log --" filter an "error --" filter.
# the overall return status is the return status of the command
function loggedCommand() {
  local command=("$@")
  # on desactive le fichier de log pour éviter les doublons
  # car on veut tout attraper à ce niveau ci (y compris les flots
  # d'erreur non générés par des commandes normalisées...)
  {
    unset COMMONS_LOG_FILE
    {
      "${command[@]}" 2>&8
      export rc=${PIPESTATUS[0]}
    } | log --
  } 8>&1 1>&2 | error -- -1
  return $rc
}
# alias allowing to test in one time if any command has failed within the previous bash command composed of pipelines

alias pipe_errorcode='xargs -n1 echo <<< "${PIPESTATUS[@]}" | { grep -v "^0$"; echo "0"; } | head -n1'

function debug() { if [ "${DEBUG:-true}" == "true" ]; then echo "$@" | sed 's/^/DEBUG: /g' | commonsLogger; fi; }

function defaultTputFGColorCode() {
  if [ -n "${DEFAULTFGCOLOR:-}" ]; then
    echo $DEFAULTFGCOLOR
    return
  fi
  if [ "$TERM" == "xterm-256color" ]; then
    echo 255
  else
    echo 9
  fi
}

function defaultTputBGColorCode() {
  if [ -n "${DEFAULTBGCOLOR:-}" ]; then
    echo $DEFAULTBGCOLOR
    return
  fi
  if [ "$TERM" == "xterm-256color" ]; then
    echo 16
  else
    echo 9
  fi
}

function tputColorCode() {
  colorName=$1
  tput_color_BLACK=0
  tput_color_RED=1
  tput_color_GREEN=2
  tput_color_YELLOW=3
  tput_color_BLUE=4
  tput_color_MAGENTA=5
  tput_color_CYAN=6
  tput_color_WHITE=7
  eval 'echo -n ${tput_color_'$colorName'}'
}


# each time it is called,
# this function defines 2 functions, that activate and deactivate
# an ansi Flag using the provided code
# the functions name will be FLAG and NOFLAG wher FLAG is parameter 1
# if function FLAG is provided any parameters, then the ANSI flag
# will be applied, then parameters echoed, then NOFLAG called
# e.g.
#    defineAnsiFlagFunctions BOLD 'tput smul' 'tput rmul'
#    echo "this is an $(BOLD important info) and this one is not so important."
# in both cases, the functions will not set the ANSI flag
# if the NOCOLOR environment variable is set to any non empty value
function defineAnsiFlagFunctions() {
  ansiFlagFuncName=$1
  flagActivateCode=$2
  flagDeactivateCode=$3
  reverseFuncName=NO$ansiFlagFuncName
  eval 'function '${ansiFlagFuncName}' (){
		[ -z "${NOCOLOR:-}" ] && '${flagActivateCode}';
		[ $# -ne 0 ] && echo -n "$@" && '${reverseFuncName}';  }'
  eval 'function '${reverseFuncName}' (){ [ -z "${NOCOLOR:-}" ] && '$flagDeactivateCode' ; }'
}

if [ "$TERM" == "xterm-256color" ]; then
  defineAnsiFlagFunctions STRIKEDOUT 'echo -en "\x1B[9m"' 'echo -en "\e[29m"'
  defineAnsiFlagFunctions UNDERLINED 'tput smul' 'tput rmul'
  defineAnsiFlagFunctions REVERSED 'echo -en "\x1B[7m"' 'tput sgr0'
  defineAnsiFlagFunctions DIMMED 'echo -en "\x1B[2m"' 'tput sgr0'
  defineAnsiFlagFunctions BOLD 'tput bold' 'tput sgr0'
else
  defineAnsiFlagFunctions STRIKEDOUT 'echo -en "\e[9m"' 'echo -en "\e[29m"'
  defineAnsiFlagFunctions UNDERLINED 'tput smul' 'tput rmul'
  defineAnsiFlagFunctions REVERSED 'echo -en "\e[7m"' 'echo -en "\e[27m"'
  defineAnsiFlagFunctions DIMMED 'echo -en "\x1B[2m"' 'echo -en "\x1B[22m"'
  defineAnsiFlagFunctions BOLD 'tput bold' 'echo -en "\e[21m"'
fi

# when echoed, changes foreground color
#if only a color name is provided, then foreground is changed
#if other parameters are provided, they are echoed with requested background, and
# then default background color is restored  (as FG DEFAULT)
function FG() {
  if [ -z "${NOCOLOR:-}" ]; then
    colorName=${1:-DEFAULT}
    if [ $colorName == DEFAULT ]; then
      tput setaf $(defaultTputFGColorCode)
    else
      tput setaf $(tputColorCode $colorName)
    fi
  fi
  shift
  if [ $# -ne 0 ]; then
    echo -n "$@"
    # we are in the case where parameters to echo are provided explicitely
    # which pin the color is to be applied only to the provided parameters
    # therefore we restore automatically the default color at the end of the provided
    # parameters :
    if [ -z "${NOCOLOR:-}" ]; then
      tput setaf $(defaultTputFGColorCode)
    fi
  fi
}

function BG() {
  if [ -z "${NOCOLOR:-}" ]; then
    colorName=${1:-DEFAULT}
    if [ $colorName == DEFAULT ]; then
      tput setab $(defaultTputBGColorCode)
    else
      tput setab $(tputColorCode $colorName)
    fi
  fi
  shift
  if [ $# -ne 0 ]; then
    echo -n "$@"
    # we are in the case where parameters to echo are provided explicitely
    # which pin the color is to be applied only to the provided parameters
    # therefore we restore automatically the default color at the end of the provided
    # parameters :
    if [ -z "${NOCOLOR:-}" ]; then
      tput setab $(defaultTputBGColorCode)
    fi
  fi
}

function RESET_COLORS() {
  if [ -z "NOCOLOR:-}" ]; then
    echo -ne "\033[00m"
  fi
}

