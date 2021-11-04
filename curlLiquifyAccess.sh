#!/bin/bash

# must be done in java8

TENANT=$1
HOST="https://access.gca-prod.mumms.com"
API_PATH="/liquifydatabase?tenant=$1"
JWT_SECRET=UUFj2UEJZ2D9GqdkL99h2sVpP4sjrzD7xzzeywPNUxxPwKCBd7UXzvv3KEVTnuLC
JWT_TOKEN=`java -jar ./hummingbird-auth-sso-1.0.7-RELEASE-jar-with-dependencies.jar -b $1 -s $JWT_SECRET`
REQUEST="$HOST/$API_PATH"
curl -X GET \
	--header "Authorization: Bearer $JWT_TOKEN" \
	$REQUEST
