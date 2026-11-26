#!/bin/bash
# Orion N5 — D350 Orbital Data System terminal telemetry header
MINT='\e[1;32m'
SAGE='\e[32m'
TEAL='\e[36m'
ORANGE='\e[1;31m'
AMBER='\e[33m'
DIM='\e[90m'
WHITE='\e[1;37m'
RESET='\e[0m'

printf "${DIM}┌─[${ORANGE}◈${DIM}]─[${MINT} ORION N5 // D350 ${DIM}]──────────────────────[${AMBER} UPLO-07 ${DIM}]─┐${RESET}\n"
printf "${DIM}│${RESET}  ${WHITE}ORBITAL DATA SYSTEM${RESET}  ${DIM}//${RESET}  ${SAGE}UTOPIA LOGISTICS DOME (MARS)${RESET}  ${DIM}│${RESET}\n"
printf "${DIM}├─[${ORANGE}75${DIM} MISSIONS]─[${MINT}12${DIM} ORBITS]─[${TEAL}5,302${DIM} SIGNALS]─[${ORANGE}07.12.2035${DIM}]─┤${RESET}\n"
printf "${DIM}└─[${SAGE}LOCK 34/95${DIM}]─────────────────────────[${ORANGE}LIVE.REC ●${DIM}]─┘${RESET}\n"
printf "${SAGE}>${RESET} ${DIM}Telemetry bus online —${RESET} ${MINT}D350-N5${RESET}\n"
