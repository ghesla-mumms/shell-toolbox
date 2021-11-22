echo "TODO: Ignore subject - we only want the intermediate certs"
echo "TODO: Find a way to search the cacerts to see if we already have the cert"
exit 1

SERVERNAME=$1
CERTDIR="/tmp"

if [[ -z "$1" ]]; then
  echo "Please provide a server as the first parameter"
  exit 1
fi

openssl s_client -connect $SERVERNAME:443 -servername $SERVERNAME -showcerts \
  </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' -e '/s:.*CN=/p' > $CERTDIR/$SERVERNAME.pem.tmp

echo ""
echo ""

# | sed 's|^.*/CN=\(.*\)|\1.pem|'

echo "Please provide a password for sudo:"
sudo -v

SUB=
FILE=
while read -r line
do
  if [[ "$line" == *"/CN="* ]]; then
    FILE=$(echo "$line" | sed 's|^.*/CN=\(.*\)|\1.pem|')
    FILE="cert-${FILE}"
    echo "creating $CERTDIR/$FILE"
    [[ -f $CERTDIR/$FILE ]] && rm $CERTDIR/$FILE
    touch $CERTDIR/$FILE
  else
    echo "$line" >> $CERTDIR/$FILE
  fi
done < $CERTDIR/$SERVERNAME.pem.tmp

rm $CERTDIR/$SERVERNAME.pem.tmp

CERTFILES=$(find $CERTDIR -name "cert-*.pem")
TRUSTSTORES=$(find /Library/Java -name cacerts)
CERTALIAS=

for CERTFILE in ${CERTFILES}; do
  CERTALIAS=$(echo "$CERTFILE" | sed -e 's|.*cert-\(.*\).pem|\1|' | awk '{print tolower($0)}')
  echo "Processing $CERTALIAS file: $CERTFILE"
  [[ -f $CERTFILE.der ]] && rm $CERTFILE.der
  openssl x509 -inform pem -outform der -in $CERTFILE -out $CERTFILE.der

  for TRUSTSTORE in ${TRUSTSTORES}; do
    echo "Checking for existence of $CERTALIAS in $TRUSTSTORE"
    if keytool -storepass changeit -keystore ${TRUSTSTORE} -list | egrep -B1 "${CERTALIAS}.*trustedCertEntry"; then
      echo "Already present."
    else
      echo "Not present, adding..."
      # sudo keytool -import -trustcacerts -noprompt -alias ${CERTALIAS} -storepass changeit -keystore ${TRUSTSTORE} -file $CERTFILE
    fi
  done
done
