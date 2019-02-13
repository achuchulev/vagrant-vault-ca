#!/usr/bin/env bash

# create policies for CA
sudo VAULT_ADDR="http://127.0.0.1:8200" vault policy write CA-policy /vagrant/config/ca-policy.hcl

#  view existing policies
sudo VAULT_ADDR="http://127.0.0.1:8200" vault policy list

# view  CA-policy
sudo VAULT_ADDR="http://127.0.0.1:8200" vault policy read CA-policy

# enable the pki secrets engine at the pki path
sudo VAULT_ADDR="http://127.0.0.1:8200" vault secrets enable pki

# Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours
sudo VAULT_ADDR="http://127.0.0.1:8200" vault secrets tune -max-lease-ttl=87600h pki

# generate the root certificate and save the certificate in CA_cert.crt
sudo VAULT_ADDR="http://127.0.0.1:8200" vault write -field=certificate pki/root/generate/internal common_name="mydomain.com" \
	ttl=87600h > CA_cert.crt

# configure the CA and Certificate Revocation List (CRL) URLs
sudo VAULT_ADDR="http://127.0.0.1:8200" vault write pki/config/urls \
       issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
       crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"

# print the certificate in text form
sudo openssl x509 -in CA_cert.crt -text

# print the validity dates
sudo openssl x509 -in CA_cert.crt -noout -dates

## enable Intermediate CA
# enable the pki secrets engine at the pki_int path
sudo VAULT_ADDR="http://127.0.0.1:8200" vault secrets enable -path=pki_int pki

# tune the pki_int secrets engine to issue certificates with a maximum time-to-live (TTL) of 43800 hours
sudo VAULT_ADDR="http://127.0.0.1:8200" vault secrets tune -max-lease-ttl=43800h pki_int

# generate an intermediate and save the CSR as pki_intermediate.csr
sudo VAULT_ADDR="http://127.0.0.1:8200" vault write -format=json pki_int/intermediate/generate/internal \
        common_name="mydomain.com Intermediate Authority" ttl="43800h" \
        | jq -r '.data.csr' > pki_intermediate.csr

# sign the intermediate certificate with the root certificate and save the generated certificate as intermediate.cert.pem
sudo VAULT_ADDR="http://127.0.0.1:8200" vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle \
        | jq -r '.data.certificate' > intermediate.cert.pem

# import signed Intermediate back into Vault
sudo VAULT_ADDR="http://127.0.0.1:8200" vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

# create a role named mydomain-dot-com which allows subdomains.
sudo VAULT_ADDR="http://127.0.0.1:8200" vault write pki_int/roles/mydomain-dot-com \
        allowed_domains="mydomain.com" \
        allow_subdomains=true \
        max_ttl="720h"
