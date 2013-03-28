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
	if [[ "$tePreise" == *S* ]]
	then
		prPreise+=S
	fi
	if [[ "$tePreise" == *M* ]]
	then
		prPreise+=M
	fi
	if [[ "$tePreise" == *F* ]]
	then
		prPreise+=F
	fi
fi


numberSection=$(echo -e "$section" | wc -l)
let numberSection--

let BIG_TAB=2+6*$(echo "$prPreise" | wc -c)-6

printSection(){
echo "$del1: ($(($anzahl/2)))"
for (( c=1; c<=$anzahl; c=c+2 ))
	do
		nowPreis=$(echo "$1" | awk "NR==$((c+1))")
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
		if [[ "$prPreise" == *S* ]]
		then
			nPreis+="$studPreis  "
		fi
		if [[ "$prPreise" == *M* ]]
		then
			nPreis+="$mitarPreis  "
		fi
		if [[ "$prPreise" == *F* ]]
		then
			nPreis+="$fremdPreis  "
		fi
		echo -ne "€ $nPreis\033[$TERM_COL""D\033[$BIG_TAB""C"
		echo "$1"  | awk "NR==$c"
	done
}


wget -T 10 -nv --no-cache --output-document="$tempFile" "$webSite" > /dev/null 2>&1 || exit 1

content=$(grep -m 1 -A 400 "Tagesübersicht" "$tempFile") #| sed -e 's/<[^>]\+>//g' -e 's/^ *//' -e '/^$/d')

echo
echo "$content" | grep -m 1 -o -E "Tagesübersicht [a-Z]*,[ .0-9]*"

for (( sec=1; sec<=$numberSection; sec++ ))
do
	del1=$(echo -e "$section" | awk "NR==$sec" )
	if [[ "$print" != *"$del1"* ]]
	then
		continue
	fi
	echo
	del2=$(echo -e "$section" | awk "NR==$((sec+1))")
	cC=$(echo "$content" | sed -e '1,/.*'$del1'.*/d'  -e '/.*'$del2'.*/,$d')
	texte=$(echo "$cC" | sed -e 's/.*<\/a> *\([^<]\+\)<a href="#zus.*/\1/' -e 's/.*preis">\([^<]\+\)<\/td>.*/\1/' -e '/^ \+/d')
	#echo "$texte"
	
	#preise=$(echo "$cC" | sed -e 's/.*preis">\([^<]\+\)<\/td>.*/\1/' -e '/^ \+/d')
	anzahl=$(echo "$texte" | wc -l)
	printSection "$texte"
	#exit
done
echo
