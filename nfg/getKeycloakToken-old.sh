read -p "Username: " USER
read -s -p "Password: " PASS
echo ""
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

echo $TOKEN
