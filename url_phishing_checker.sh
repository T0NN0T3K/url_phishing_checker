#!/bin/bash


api_key="INSERT_YOUR_GOOGLE_API_KEY"


url_checker() {
    if [ ! "${1//:*}" = http ]; then
        if [ ! "${1//:*}" = https ]; then
            echo -e "URL non valido. Usa http o https."
            exit 1
        fi
    fi
}
		
echo "----------------------------------------------------"
echo "----------------------------------------------------"
echo "-CONTROLLA SE UN LINK E' POTENZIALMENTE DI PHISHING-"
echo "----------------------------------------------------"
echo "--di-Alessandro-Tonoli------------------------------"
echo "----------------------------------------------------"
echo -n "Inserisci l'URL completo sospetto: "
read url
url_checker $url 


dominio=$(echo $url | cut -d'/' -f3)
echo "Nome di dominio: $dominio"

if [[ $dominio =~ bit\.ly ]] || [[ $dominio =~ tinyurl\.com ]] || [[ $dominio =~ is\.gd ]] || [[ $dominio =~ tiny\.cc ]]; then
	echo "Quello inserito e' uno Short Link. Ottieni il sito a cui reindirizza e inserisci quello."
elif [[ $dominio =~ ngrok\.io ]]; then
	echo "Quello inserito e' un servizio di tunneling, non e' possibile analizzare l'URL."
else
	
	echo -n "-Controllo se il sito e' raggiungibile -> "
	result=$(ping -q -c 1 $dominio)
	
	
	if [ $? -eq 0 ]; then
		
		echo "OK"
		
		#CONTROLLO1: NOMI DI AZIENDE FAMOSE

		contenuto=$(curl -s $url)
		lista_aziende="facebook google instagram twitter linkedin aliexpress ebay amazon"
		for azienda in $lista_aziende; do
			if [[ $url == *"$azienda"* || $contenuto == *"$azienda"* ]]; then
				echo "-Attenzione! Il contenuto dell'Url contiene la parola: $azienda , assicurarsi che il sito sia quello autentico."
			fi
		done


		#CONTROLLO2: DATI REGISTRANTE

		echo -n "-Controllo la presenza dei dati del Registrante -> "
		info=$(whois $dominio)
		if [[ $info == *"PRIVACY"* ]]; then
			echo "X"
		else
			echo "OK"
		fi

		#CONTROLLO3: CONFRONTO DATABASE DI PHISHING 

		echo -n "-Controllo la presenza nel database di phishtank.com -> "
		wget -q  http://data.phishtank.com/data/online-valid.csv -O phishing_list.txt
		ricerca=$(grep -o "$url" phishing_list.txt)
		if [ -z "$ricerca" ]; then
			echo "URL non presente"
		else
			echo "ATTENZIONE: URL presente!"
		fi

		#CONTROLLO4: VALIDITA' CERTIFICATO SSL 

		echo -n "-Controllo validita' certificato SSL -> "
		if true | openssl s_client -connect $dominio:443 2>/dev/null | openssl x509 -noout -checkend 0; then
			echo "Certificato valido"
		else
			echo "Certificate expired"
		fi
		

		#CONTROLLO5: CONTROLLO SEGNALAZIONI GOOGLE SAFE BROWSING
		
		if [ "$api_key" = "INSERT_YOUR_GOOGLE_API_KEY" ]; then
			echo "-Inserisci la tua google api key per abilitare il controllo tramite Google safe Browsing."
		else 
		
			echo -n "-Controllo se e' segnalato come non sicuro da Google Safe Browsing -> "

			request_body="{\"client\":{\"clientId\":\"YOUR_CLIENT_ID\",\"clientVersion\":\"YOUR_CLIENT_VERSION\"},\"threatInfo\":{\"threatTypes\":[\"MALWARE\",\"SOCIAL_ENGINEERING\"],\"platformTypes\":[\"ANY_PLATFORM\"],\"threatEntryTypes\":[\"URL\"],\"threatEntries\":[{\"url\":\"$url\"}]}}"	
			verifica=$(curl -s -X POST -H "Content-Type: application/json" -d "$request_body" "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$api_key")
			if [[ $verifica = *"matches"* ]]; then
				echo "ATTENZIONE! URL segnalato. Non visitare il sito."
			else
				echo "URL non segnalato"
			fi	
		fi
		
	else

		echo "Il sito e' offline o non raggiungibile."
	
	fi

fi





