#!/bin/sh

getResults ()
{
   item=$1
   folder=$2
   count=1
   `touch /tmp/vote`
   while [ $count -le `cat "$folder" | wc -l` ]
   do
      currItem=`cat "$folder" | sed -n "${count}p"`
      wins=`cat "$item" | egrep "^$currItem/.*$" | wc -l`
      loses=`cat "$item" | egrep "^[^/]*/$currItem$" | wc -l`
      total=`expr $wins + $loses`
      tmp=`expr $wins \* 100`
      if [ $total -ne 0 ] ; then
         percent=`expr $tmp / $total`
         echo "${currItem},${wins},${loses},$percent" >> /tmp/vote
      else
         echo "${currItem},${wins},${loses},-" >> /tmp/vote  
      fi
      count=`expr $count + 1`
   done
   cat /tmp/vote | sort -t"," -k4nr -k2nr -k3nr
   rm /tmp/vote 
}

if [ $# -lt 1 ] ; then
echo "No option is given" ; exit 1
fi

if [ $1 != "item" -a $1 != "vote" -a $1 != "results" ] ; then
echo "$1: No such option exists" ; exit 2
fi

if [ $HEAD2HEAD_DATA ] ; then
	usr=$HEAD2HEAD_DATA
else
	usr=$USER
fi

if [ ! -d "/home/$USER/.head2head" ]; then
   mkdir "/home/$USER/.head2head";
   chmod a+rx "/home/$USER/.head2head"
   mkdir "/home/$USER/.head2head/items";
   chmod a+rx "/home/$USER/.head2head/items"
elif [ ! -d "/home/$USER/.head2head/items" ]; then
   mkdir "/home/$USER/.head2head/items";
   chmod a+rx "/home/$USER/.head2head/items"
fi

case $1 in
"item") if [ $# -gt 3 ] ; then
           echo "Too many arguments" ; exit 255 
        elif [ $# -eq 1 ] ; then
           if [ ! -d "/home/$usr/.head2head/items/" ] ; then
              echo "$usr: Does not have any categories" ; exit 254
           fi
           ls "/home/$usr/.head2head/items/"
        elif [ $# -eq 2 ] ; then
           if [ -e "/home/$usr/.head2head/items/$2" ] ; then
              if [ `cat "/home/$usr/.head2head/items/$2" | wc -l` -gt 0 ] ; then
                 cat "/home/$usr/.head2head/items/$2" ; exit 0
              fi
           else
              echo "$2: Category does not exist in $usr" ; exit 3
           fi
        elif [ $# -eq 3 ] ; then
           if [ `echo "$2" | tr -dc '\n' | wc -c` -gt 1 ] || [ `echo "$2" | tr -dc '/' | wc -c` -ge 1 ]; then
              echo "$2: Category names cannot contain a newline or a slash"; exit 1
           elif [ `echo "$3" | tr -dc '/' | wc -c` -ge 1 ] || [ `echo "$3" | tr -dc '\n' | wc -c` -gt 1 ]; then
              echo "$3: Item names cannot contain a newline or a slash"; exit 1
           fi
           if [ $usr = $USER ] ; then
              if [ ! -e "/home/$usr/.head2head/items/$2" ] ; then
                 touch "/home/$usr/.head2head/items/$2"
                 chmod a+rx "/home/$usr/.head2head/items/$2"
                 echo "$3" >> "/home/$usr/.head2head/items/$2" ; exit 0
              elif [ `egrep "^$3$" "/home/$usr/.head2head/items/$2" | wc -l` -gt 0 ] ; then
                 echo "$3 already exists in the $2" ; exit 4
              else
                 echo "$3" >> "/home/$usr/.head2head/items/$2" ; exit 0
              fi
           elif [ $usr != $USER -a $# -eq 3 ] ; then
              echo "A user does not have permission to add a category or an item to a category in when HEAD2HEAD_DATA is set" ; exit 20
           fi
        else
           echo "too many arguments" ; exit 5
        fi
    ;;
"vote") if [ $# -gt 2 ] ; then
           echo "Too many arguements" ; exit 255
        fi
        if [ ! -e "/home/$USER/.head2head/$usr" ] ; then
           mkdir "/home/$USER/.head2head/$usr"
           chmod a+rx "/home/$USER/.head2head/$usr"
        fi
        if [ $# -eq 1 ] ; then
           echo "Please specify the category" ; exit 6
        elif [ $# -eq 2 ] ; then
           if [ `echo "$2" | tr -dc '\n' | wc -c` -gt 1 ] || [ `echo "$2" | tr -dc '/' | wc -c` -ge 1 ]; then
              echo "$2: Category names cannot contain a newline or a slash"; exit 1
           fi
           if [ ! -e "/home/$usr/.head2head/items/$2" ] ; then
              echo "$2: Category does not exist" ; exit 7
           elif [ `cat "/home/$usr/.head2head/items/$2" | wc -l` -lt 2 ] ; then
              echo "Too few names in the $2" ; exit 8
           else
              shuf -n 2 "/home/$usr/.head2head/items/$2" > "/tmp/hiraltmp"
              one=`cat "/tmp/hiraltmp" | head -1`
              two=`cat "/tmp/hiraltmp" | tail -1`
              echo "1)" $one
              echo "2)" $two
              rm "/tmp/hiraltmp"
              read choice
              case $choice in
                 1) echo "$one/$two" >> "/home/$USER/.head2head/$usr/$2" ; chmod a+rx "/home/$USER/.head2head/$usr/$2" ;;
                 2) echo "$two/$one" >> "/home/$USER/.head2head/$usr/$2" ; chmod a+rx "/home/$USER/.head2head/$usr/$2" ;; 
                 *) if [ ! $choice ] ; then
                       echo "No choice provided" ; exit 9
                    else
                       echo "Invalid choice" ; exit 
                    fi
              esac
           fi
        fi
	;;	
"results") if [ $# -gt 2 ] ; then
              echo "Too many arguements" ; exit 255
           fi
           if [ $# -eq 1 ] ; then
              echo "Category not specified" ; exit 11
           fi
           if [ $# -eq 2 ] ; then
              if [ `echo "$2" | awk '{ if($0 ~ /^[^\/]*$/)  print "1"; else print "2" }'` -eq 1 ] ; then
                 if [ ! -e "/home/$usr/.head2head/items/$2" ] ; then
                    echo "$2: No such category exists for $usr" ; exit 21
                 fi
                 if [ -e "/home/$usr/.head2head/$usr/$2" ] ; then
                    getResults "/home/$usr/.head2head/$usr/$2" "/home/$usr/.head2head/items/$2"
                 elif [ ! -e "/home/$usr/.head2head/$usr/$2" ] ; then
                    echo "$2: Category has not been voted by $usr yet" ; exit 14
                 fi
              elif [ `echo "$2" | awk '{ if($0 ~ /^[^\/]*\/[^\/]*$/)  print "1"; else print "2" }'` -eq 1 ] ; then
                 folder=`echo $2 | awk '{split($0,sp,"/"); print sp[1]}'`
                 category=`echo $2 | awk '{split($0,sp,"/"); print sp[2]}'`
                 if [ ! -e "/home/$folder/.head2head/items/$category" ] ; then
                    echo "$category: No such category exists for $folder" ; exit 12
                 fi
                 if [ ! -e "/home/$usr/.head2head/$folder/$category" ] ; then
                    echo "$category: Category has not been voted by $usr yet" ; exit 22
                 fi
                 getResults "/home/$usr/.head2head/$folder/$category" "/home/$folder/.head2head/items/$category"
              fi
           fi
        ;;
*) echo "Invalid option" ; exit 13		
esac
