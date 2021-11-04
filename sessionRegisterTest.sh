USER=
PASS=
KEYCLOAK="https://keycloak-keycloak-dev-ha.gca-dev.mumms.com/auth"
REALM=hbqa04
TOKEN_ENDPOINT=/realms/$REALM/protocol/openid-connect/token
USERID_ENDPOINT="/admin/realms/$REALM/users"
KEYCLOAK_URI=$KEYCLOAK$TOKEN_ENDPOINT
CLIENT=pim-login
TOKEN=`curl -s -d "client_id=$CLIENT" \
            -d "grant_type=password" \
            --data-urlencode "username=$USER" \
            --data-urlencode "password=$PASS" \
            $KEYCLOAK$TOKEN_ENDPOINT |jq -r .access_token `
#CONTENT_HEADER="Content-Type: application/x-www-form-urlencoded charset=UTF-8"
CONTENT_HEADER="Content-Type: application/json;"

#ENDPOINT="http://localhost:8080/web/api/clinical/visits/v1/100/?hbcVisitId=deleteme&agency=demo"

echo TOKEN $TOKEN

ENDPOINT="https://session-unifier.gca-dev.mumms.com/session/register"

curl    -X POST \
        -H "$CONTENT_HEADER" \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"clientTTL\": \"10000\" }"\
        $ENDPOINT
