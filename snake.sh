#!/bin/bash
# String formatters
	# RGB tool allows you to enter three values on a range from 0 to 5 for red, green, and blue, which will be converted to an ANSI control sequence.
	# For more info, see here: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
	rgb() { printf "\033[1;38;5;$(( 16 + 36 * $1 + 6 * $2 + $3 ))m"; }

	red="$(rgb "5" "0" "0")"
	green="$(rgb "0" "4" "0")"
	blue="$(rgb "1" "1" "5")"
	bold="\033[1m"
	faint="\033[2m"
	italic="\033[3m"
	underline="\033[4m"
	reset="\033[0m"

# Print functions
	print() {
		printf "${bold}%b${reset}" "$@"
		printf "\n"
	}
	# Prints input in red and bold. every argument will be a new line
	error() {
		printf "${red}%b${reset}\n" "$@"
	}

SIZEY=63
SIZEX=202
LENGTH=4
touch /tmp/snake
(( POSY[0]=(SIZEY+1)/2))
(( POSX[0]=(SIZEX+1)/2))
statusbar() {
  printf "\033[$(( SIZEY+1 ))H\033[47m\033[30m\033[0K%b${reset}" "$*"
}
update() {
  printf "\033[${POSY[${#POSY[@]} - 1]};${POSX[${#POSX[@]} - 1]}H%b" "x"
  # statusbar "X: ${POSY[${#POSY[@]} - 1]} Y: ${POSX[${#POSX[@]} - 1]} Score: $(( LENGTH-4 ))"

}
trap trapfunction 0
trapfunction() {
  echo "x" > /tmp/snake
  wait
  clear
  exit
}
move() {
  case $1 in
    w) POSY1=($(( POSY[${#POSY[@]} - 1]-1 ))); POSX1+=(${POSX[${#POSX[@]} - 1]});;
    a) POSX1=($(( POSX[${#POSX[@]} - 1]-1 ))); POSY1+=(${POSY[${#POSY[@]} - 1]});;
    s) POSY1=($(( POSY[${#POSY[@]} - 1]+1 ))); POSX1+=(${POSX[${#POSX[@]} - 1]});;
    d) POSX1=($(( POSX[${#POSX[@]} - 1]+1 ))); POSY1+=(${POSY[${#POSY[@]} - 1]});;
  esac
}
test_pos() {
  i=0
  for y in "${POSY[@]}"; do
    if [[ ${POSX[i++]} == $2 && $y == $1 ]]
    then return 0
    fi
  done
  return 1
}
spawn_apple() {
      APPLEY=$(jot -r 1 1 ${SIZEY})
      APPLEX=$(jot -r 1 1 ${SIZEX})
      while test_pos "${APPLEY}" "${APPLEX}"; do
        APPLEY=$(jot -r 1 1 ${SIZEY})
        APPLEX=$(jot -r 1 1 ${SIZEX})
      done
      printf "\033[${APPLEY};${APPLEX}H${green}%b${reset}" ""
}

printf "\033[8;$(( SIZEY+1 ));${SIZEX}t"
unset LOCK
unset REPLY
clear
update

# wait for first key press
until [[ ${REPLY} =~ w|a|s|d ]]; do
  read -rsn1
done
echo ${REPLY} > /tmp/snake
spawn_apple
while true; do
  # validate input
  case $(cat /tmp/snake) in
    w) [[ ${PREV} == "s" ]] && echo "${PREV}" > /tmp/snake;;
    a) [[ ${PREV} == "d" ]] && echo "${PREV}" > /tmp/snake;;
    s) [[ ${PREV} == "w" ]] && echo "${PREV}" > /tmp/snake;;
    d) [[ ${PREV} == "a" ]] && echo "${PREV}" > /tmp/snake;;
    x) POSY+=(0);;
  esac
  PREV=$(cat /tmp/snake)
  move "${PREV}"
  test_pos "${POSY1}" "${POSX1}"
  if [[ $? == 0 ]]; then
    POSY+=(0)
  else
    POSY+=($POSY1)
    POSX+=($POSX1)
  fi
  # apples
  if (( POSY[${#POSY[@]} - 1] == APPLEY && POSX[${#POSX[@]} - 1] == APPLEX )); then
    spawn_apple
    (( LENGTH ++ ))
  fi

  # cut off length
  if (( ${#POSY[@]} > ${LENGTH} )); then
    printf "\033[${POSY[0]};${POSX[0]}H%b" " "
    POSX=(${POSX[@]:1})
    POSY=(${POSY[@]:1})
  fi
  # wall collision
  if [[ ${POSY[${#POSY[@]} - 1]} -lt 1 || ${POSX[${#POSX[@]} - 1]} -lt 1 || ${POSY[${#POSY[@]} - 1]} -gt ${SIZEY} || ${POSX[${#POSX[@]} - 1]} -gt ${SIZEX} ]]; then
    clear
    printf "\033[8;11;78t\033[3;2H"
    error \
    " ██████╗  █████╗ ███╗   ███╗███████╗     ██████╗ ██╗   ██╗███████╗██████╗ " \
    "██╔════╝ ██╔══██╗████╗ ████║██╔════╝    ██╔═══██╗██║   ██║██╔════╝██╔══██╗" \
    "██║  ███╗███████║██╔████╔██║█████╗      ██║   ██║██║   ██║█████╗  ██████╔╝" \
    "██║   ██║██╔══██║██║╚██╔╝██║██╔══╝      ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗" \
    "╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗    ╚██████╔╝ ╚████╔╝ ███████╗██║  ██║" \
    " ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝     ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝" \
    "                               \033[5mSCORE: $(( LENGTH-4 ))              "
    sleep 3
    clear
    kill $$
    exit
  fi
  update
  sleep 1
done &

# read input
while true; do
  PREV=$(cat /tmp/snake)
  read -rsn1
  if [[ ${REPLY} != ${PREV} && ${REPLY} =~ w|a|s|d ]]; then
      echo "${REPLY}" > /tmp/snake
  fi
done

