#!/bin/bash
 
FLAGS=""
FONT="Arial,28"
VPOSITION=0
HPOSITION=2
XOFFSET=0
YOFFSET=0
 
while [ $# -gt 0 ]
do
  case $1 in
   --left)
     HPOSITION=0
     ;;
   --center) 
     HPOSITION=1
     ;;
   --right)
     HPOSITION=2
     ;;
   --top)
     VPOSITION=0
     ;;
   --middle)
     VPOSITION=1
     ;;
   --bottom)
     VPOSITION=2
     ;;
   --small)
     FONT="Arial,12"
     ;;
   --normal)
     FONT="Arial,20"
     ;;
   --big)
     FONT="Arial,28"
     ;;
   --large)
     FONT="Arial,36"
     ;;
   --huge)
     FONT="Arial,48"
     ;;
   -f|--font)
     if [ $# -gt 1 ]
     then
       FONT="$2"
       shift
     else
       exit -1
     fi   
     ;;
   --green)
     FLAGS="$FLAGS -R #00ff00"
     ;;
   --yellow)
     FLAGS="$FLAGS -R #ffff00"
     ;;
   --red)
     FLAGS="$FLAGS -R #ff0000"
     ;;
   -l|--l|--lines)
     if [ $# -gt 1 ]
     then
       FLAGS="$FLAGS -l $2"
       shift
     else
       exit -1
     fi
     ;;
   --o|-x|--xoffset)
     if [ $# -gt 1 ]
     then
       XOFFSET=$2
       shift
     else
       exit -1
     fi
     ;;
   --i|-y|--yoffset)
     if [ $# -gt 1 ]
     then
       YOFFSET=$2
       shift
     else
       exit -1
     fi
     ;;
   --d|-d|--delay)
     if [ $# -gt 1 ]
     then
       FLAGS="$FLAGS -u $2"
       shift
     else
       exit -1
     fi
     ;;
  esac
  shift
done
 
(( POSITION=VPOSITION*3+HPOSITION ))
aosd_cat $FLAGS -n $FONT -p $POSITION -x $XOFFSET -y $YOFFSET
