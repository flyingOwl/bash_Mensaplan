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
	echo "$tePreise" | grep "S" > /dev/null && prPreise+=S
	echo "$tePreise" | grep "M" > /dev/null && prPreise+=M
	echo "$tePreise" | grep "F" > /dev/null && prPreise+=F
fi


numberSection=$(echo -e "$section" | wc -l)
let numberSection--

let BIG_TAB=2+6*$(echo "$prPreise" | wc -c)-6

printSection(){
for (( c=1; c<=$anzahl; c++ ))
	do
		nowPreis=$(echo "$1" | awk "NR==$c")
		studPreis=${nowPreis:4:4}
		mitarPreis=${nowPreis:11:4}
		if [ -z $mitarPreis ];
		then
			mitarPreis=$studPreis
		fi
		fremdPreis=${nowPreis:18:4}
		if [ -z $fremdPreis ];
		then
			fremdPreis=$mitarPreis
		fi
		
		nPreis=''
		echo "$prPreise" | grep "S" > /dev/null && nPreis+="$studPreis  "
		echo "$prPreise" | grep "M" > /dev/null && nPreis+="$mitarPreis  "
		echo "$prPreise" | grep "F" > /dev/null && nPreis+="$fremdPreis  "
		echo -ne "€ $nPreis\033[$TERM_COL""D\033[$BIG_TAB""C"
		echo "$2"  | awk "NR==$c"
	done
}

wget -T 10 -nv --no-cache --output-document="$tempFile" "$webSite" > /dev/null 2>&1 || exit 1

content=$(grep -m 1 -A 400 -B 20 "Tagesübersicht" "$tempFile" | sed -e 's/<[^>]\+>//g' -e 's/^ *//' | uniq)

datum=$(echo "$content" | grep -m 1 "Tagesübersicht")
echo
echo $datum

for (( sec=1; sec<=$numberSection; sec++ ))
do
	del1=$(echo -e "$section" | awk "NR==$sec" )
	echo "$print" | grep "$del1" > /dev/null || continue
	echo
	del2=$(echo -e "$section" | awk "NR==$((sec+1))")
	cC=$(echo "$content" | sed -e '1,/'$del1'/d'  -e '/'$del2'/,$d')
	texte=$(echo "$cC" | awk '0 == (NR+1) % 3' | sed -e 's/ *[0-9]\+  \+//g')
	preise=$(echo "$cC" | awk '0 == NR % 3' | tr -d '\r')
	anzahl=$(echo "$texte" | wc -l)
	echo "$del1: ($anzahl)"
	printSection "$preise" "$texte"
done
echo
