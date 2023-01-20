#!/bin/bash

YELLOW='\033[1;33m'
NC='\033[0m' # No Color
TLD="local"
OU="DataTeam"
L="Munich"
ST="Bayern"
C="DE"
O="IT"
PASSWORD="YOUR_PASSWD_HERE"

echo -e "-------------------------------------------------"
echo -e "${YELLOW}Deleting previous (if any)...: ${i}${NC}"
echo -e "-------------------------------------------------"
sudo rm -f ./secrets/*.crt
sudo rm -f ./secrets/*.key
sudo rm -f ./secrets/*.srl
sudo rm -f ./secrets/*.csr
sudo rm -f ./secrets/*.jks
sudo rm -f ./secrets/cert_creds

# Generate Fake CA
echo -e "--------------------------------"
echo -e "${YELLOW}Generating Fake CA${NC}"
echo "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=ca.${TLD}"
echo -e "--------------------------------"
sleep 2
openssl req -new -x509 -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=ca.${TLD}" -keyout ./secrets/selfsig-ca.key -out ./secrets/selfsig-ca.crt -days 9999 -passin pass:$PASSWORD -passout pass:$PASSWORD #>/dev/null 2>&1

for i in broker1 broker2 broker3 schema-registry producer consumer; do
    
    cat > extfile << ENDOFFILE
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = ${i}.${TLD} 	
ENDOFFILE

    echo -e "\n"
    echo -e "-------------------------------------------------"
    echo -e "${YELLOW}Generating keys for Component: ${i}${NC}"
    echo -e "-------------------------------------------------" 

    # Create Key Store
    echo -e "\n"
    echo -e "----------------------------------------"
    echo -e "${YELLOW}Creating KeyStore for ${i}${NC}"
    echo -e "${YELLOW}CN=${i}.${TLD}, OU=${OU}, O=${O}, L=${L}, ST=${ST}, C=${C}${NC}"
    echo -e "----------------------------------------"
    sleep 1
    keytool -genkey -alias ${i} -dname "CN=${i}.${TLD}, OU=${OU}, O=${O}, L=${L}, ST=${ST}, C=${C}" -keystore ./secrets/${i}.keystore.jks -keyalg RSA -storepass $PASSWORD -keypass $PASSWORD #>/dev/null 2>&1
    
    # Certificate Signing Request
    echo -e "\n"
    echo -e "-----------------------------------"
    echo -e "${YELLOW}Creating CSR for ${i}${NC}"
    echo -e "-----------------------------------"
    sleep 1
    keytool -keystore 	./secrets/$i.keystore.jks -alias $i -certreq -file ./secrets/$i.csr -storepass $PASSWORD -keypass $PASSWORD #>/dev/null 2>&1

    # Sign Certificate
    echo -e "\n"
    echo -e "------------------------------------------"
    echo -e "${YELLOW}Signing Certificate for ${i}${NC}"
    echo -e "------------------------------------------"
    sleep 1
    openssl x509 -req -CA ./secrets/selfsig-ca.crt -CAkey ./secrets/selfsig-ca.key -in ./secrets/$i.csr -out ./secrets/$i-signed.crt -days 9999  -CAcreateserial -passin pass:$PASSWORD -extensions SAN -extfile <(printf "\n[SAN]\nsubjectAltName=DNS:${i}.${TLD},DNS:*.${TLD}") #>/dev/null 2>&1

    # Import CA into KeyStore
    echo -e "\n"
    echo -e "---------------------------------------------"
    echo -e "${YELLOW}Importing CA into ${i} KeyStore${NC}"
    echo -e "---------------------------------------------"
    sleep 1
    keytool -keystore ./secrets/$i.keystore.jks -alias CARoot -import -noprompt -file ./secrets/selfsig-ca.crt -storepass $PASSWORD -keypass $PASSWORD #>/dev/null 2>&1

    # Import Signed Cert Into Keystore
    echo -e "\n"
    echo -e "-----------------------------------------------------"
    echo -e "${YELLOW}Importing Signed ${i} CRT into KeyStore${NC}"
    echo -e "-----------------------------------------------------"
    sleep 1
    keytool -keystore ./secrets/$i.keystore.jks -alias $i -import  -noprompt -file ./secrets/$i-signed.crt -storepass $PASSWORD -keypass $PASSWORD #>/dev/null 2>&1

    # Create TrustStore and Import CA CRT
    echo -e "\n"
    echo -e "-----------------------------------------------------------"
    echo -e "${YELLOW}Creating a Trustore for ${i} and importing CA${NC}"
    echo -e "-----------------------------------------------------------"
    sleep 1
    keytool -keystore ./secrets/$i.truststore.jks -alias CARoot -import -file ./secrets/selfsig-ca.crt -storepass $PASSWORD -keypass $PASSWORD
done


echo -e "\n"
echo -e "----------------------------------------------------------"
echo -e "${YELLOW}Making Password available as plain text file${NC}"
echo $PASSWORD | tee -a ./secrets/cert_creds >/dev/null 2>&1

echo -e "\n"
echo -e "-----------------------------------------------"
echo -e "${YELLOW}Changing owner and group to files${NC}"
echo -e "-----------------------------------------------"
sudo chown 1000:1000 ./secrets/*.key 
sudo chown 1000:1000 ./secrets/*.crt 
sudo chown 1000:1000 ./secrets/*.srl 
sudo chown 1000:1000 ./secrets/*.csr 
sudo chown 1000:1000 ./secrets/*.jks
sudo chown 1000:1000 ./secrets/cert_creds
