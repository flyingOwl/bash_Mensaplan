#!/bin/bash

webSite="http://www.studentenwerk-berlin.de/mensen/speiseplan/beuth/index.html"
webNext="http://www.studentenwerk-berlin.de/mensen/speiseplan/beuth/01.html"
tempFile="/tmp/mensaplan.temp"
section="Salate\nAktionsstand\nEssen\nBeilagen\nDesserts\nKennzeichnungen"
print=""
prPreise="SMF"
tePreise=""
TERM_COL=$(tput cols)

if [ $# -ne 0 ] ; then
while getopts AEBDSnp:h opt
	do
	case "$opt" in
      		A) print=$print":Aktionsstand";;
		E) print=$print":Essen";;
		B) print=$print":Beilagen";;
		D) print=$print":Desserts";;
		S) print=$print":Salate";;
		p) tePreise=$OPTARG;;
		n) webSite=$webNext;;
		h) 	echo -e "Usage:"
			echo -e "\t[-A Nur Aktionsessen]"
			echo -e	"\t[-E Nur \"normales\" Essen]"
			echo -e	"\t[-B Nur Beilagen]"
			echo -e	"\t[-D Nur Desserts]"
			echo -e "\t[-S Nur Salate]"
			echo -e "\t[-p Preise: S = Student; M = Mitarbeiter; F = Fremde]"
			echo -e	"\t[-n Plan für den nächsten Tag]"
			echo -e	"Beispiel: <Skript> -nAD -p SM"
			echo -e	"\tPlan des nächsten Tages, nur Aktion+Desserts werden angezeigt und"
			echo -e	"\tnur die Preise für Student und Mitarbeiter"; exit 0;;
  	esac
done
fi

mkdir -p "$(dirname "$tempFile")"

if [ -z "$print" ];
then
	print=$section
fi

if [ ! -z "$tePreise" ];
then
	prPreise=""
	echo "$tePreise" | grep "S" > /dev/null && prPreise=$prPreise"S"
	echo "$tePreise" | grep "M" > /dev/null && prPreise=$prPreise"M"
	echo "$tePreise" | grep "F" > /dev/null && prPreise=$prPreise"F"
fi


numberSection=$(echo -e "$section" | wc -l)
numberSection=$((numberSection-1))

BIG_TAB=$((2+6*$(echo "$prPreise" | wc -c)-6))

printSection(){
for (( c=1; c<=$anzahl; c++ ))
	do
		#echo -n "$c"
		nowPreis=$(echo "$1" | awk "NR==$c" | tr '\r' ' ' | sed 's/ *$//g')
		studPreis=$(echo "$nowPreis"  | awk '{ if ( $2 ~ /[0-9]/ ) { print $2 } }')
		mitarPreis=$(echo "$nowPreis" | awk '{ if ( $3 ~ /[0-9]/ ) { print $3 } else { if ( $2 ~ /[0-9]/ ) { print $2 } } }')
		fremdPreis=$(echo "$nowPreis" | awk '{ if ( $4 ~ /[0-9]/ ) { print $4 } else { if ( $3 ~ /[0-9]/ ) 
							{ print $3 } else { if ( $2 ~ /[0-9]/ ) { print $2 } } } }')
		nowText=$(echo "$2"  | awk "NR==$c" | tr '\r' ' ' | sed 's/ *$//g')
		
		nPreis=""
		echo "$prPreise" | grep "S" > /dev/null && nPreis=$nPreis"$studPreis  "
		echo "$prPreise" | grep "M" > /dev/null && nPreis=$nPreis"$mitarPreis  "
		echo "$prPreise" | grep "F" > /dev/null && nPreis=$nPreis"$fremdPreis  "
		
		echo -n "€ $nPreis"
		echo -ne "\033[$TERM_COL""D\033[$BIG_TAB""C" #set cursor
		echo "$nowText"
	done
}

wget -T 10 -nv --no-cache --output-document="$tempFile" "$webSite" > /dev/null 2>&1 || exit 1

content=$(sed -e 's/<[^>]\+>//g' "$tempFile" | sed -e 's/^ *//; s/ *$//; /^$/d' | uniq)

datum=$(echo "$content" | grep "Tagesübersicht")
echo
echo $datum

for (( sec=1; sec<=$numberSection; sec++ ))
do
	del1=$(echo -e "$section" | awk "NR==$sec" | tr '\r' ' ' | sed 's/ *$//g')
	echo "$print" | grep "$del1" > /dev/null || continue
	echo
	del2=$(echo -e "$section" | awk "NR==$((sec+1))" | tr '\r' ' ' | sed 's/ *$//g')
	cC=$(echo "$content" | sed -e '1,/'$del1'/d' | sed -e '/'$del2'/,$d')

	texte=$(echo "$cC" | grep -v "EUR" | sed -e 's/  \+[0-9]\+//g' | grep "   ")
	preise=$(echo "$cC" | grep "EUR" | tr -d '/')
	anzahl=$(echo "$texte" | wc -l)
	echo "$del1: ($anzahl)"
	printSection "$preise" "$texte"
done
echo
