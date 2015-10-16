#!/bin/bash
# VERSION 1.1
# Change this two lines for any other mensa powered by StudentenWerk 
webSite="http://www.studentenwerk-berlin.de/mensen/speiseplan/beuth/index.html"
webNext="http://www.studentenwerk-berlin.de/mensen/speiseplan/beuth/01.html"

tempFile="/tmp/mensaplan.temp"
prPreise="SMF"
tePreise=""
ampel=0

if [ "$#" -ne 0 ] ; then
while getopts ncp:h opt
	do
	case "$opt" in
		p) tePreise="$OPTARG";;
		c) ampel=1;;
		n) webSite="$webNext";;
		h) 	echo -e "Usage:"
			echo -e "\t[-p Preise: S = Student; M = Mitarbeiter; F = Fremde]"
			echo -e	"\t[-n Plan für den nächsten Tag]"
			echo -e	"\t[-c Ampelsymbol der Speisen farblich kennzeichnen]"
			echo -e	"Beispiel: $0 -n -p SM"
			echo -e	"\tPlan des nächsten Tages wird mit Preisen für Studenten und Mitarbeiter angezeigt"; exit 0;;
  	esac
done
fi

mkdir -p "$(dirname "$tempFile")"

if [ ! -z "$tePreise" ];
then
	prPreise="$tePreise"
fi



setColor(){
	case "$1" in
		"gruen")  echo -en "\e[0;32m";;
		"orange") echo -en "\e[0;33m";;
		"rot")    echo -en "\e[0;31m";;
	esac

}

printSection(){
echo "$del1: ($(($anzahl/2)))"
let "f = 1"
for (( c=1; c<$anzahl; c=c+2 ))
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
		
		echo -ne "€ $nPreis"
		if [ "$ampel" -eq "1" ];
		then
			setColor $(echo "$farben" | awk "NR==$f")
			let "f = f+1"
			echo "$1"  | awk "NR==$c"
			echo -en "\e[0m"
		else
			echo "$1"  | awk "NR==$c"
		fi
	done
}

wget -T 10 -nv --no-cache --output-document="$tempFile" "$webSite" > /dev/null 2>&1 || exit 1
content=$(grep -m 1 -A 400 '<div class="mensa_day">' "$tempFile")
echo
grep -m 1 -o -E "Tagesübersicht [a-Z]*,[ .0-9]*" "$tempFile"

## Parse all sections ##
section=$(sed -ne'/mensa_day_title/s/.*>\([^<]*\)<.*/\1/p' <<< "$content")
numSections=$(wc -l <<< "$section")

for (( sec=1; sec<$numSections; sec++ ))
do
    echo
	del1=$(echo -e "$section" | awk "NR==$sec" )
	del2=$(echo -e "$section" | awk "NR==$((sec+1))")
	cC=$(sed -e '1,/.*'$del1'.*/d'  -e '/.*'$del2'.*/,$d' <<< "$content")
	if [ "$ampel" -eq "1" ];
	then
		farben=$(sed -n '/ampel/s/.*#ampel_\([^"]\+\)">.*/\1/p' <<< "$cC")
	fi
	texte=$(sed -n -e '/zusatz/s/ *<[^>]*zusatz">[0-9a-z]*<\/a>//g' -e 's/.*<\/a> *\([^<]\+\)<\/td>.*/\1/p' -e 's/.*preis">\([^<]\+\)<\/td>.*/\1/p' <<< "$cC")
	## note: first remove all tags with "zusatz", then parse the meal description, then parse the price
	anzahl=$(wc -l <<< "$texte")
	texte=$(sed 's/\ *$//g' <<< "$texte")
	printSection "$texte"
done
echo

