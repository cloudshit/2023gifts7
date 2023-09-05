#!/bin/bash
while true; do
  number=$RANDOM
  let "number %= 4"

  case $number in
    0)
      echo red
      curl http://localhost:8080/v1/color/red &> /dev/null
      ;;

    1)
      echo green
      curl http://localhost:8080/v1/color/melon &> /dev/null
      ;;
    
    2)
      echo orange
      curl http://localhost:8080/v1/color/orange &> /dev/null
      ;;

    3)
      echo pear
      curl http://localhost:8080/v1/color/pear &> /dev/null
      ;;
  esac
done
