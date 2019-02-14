# A sample repo with example of how to build your own Certificate Authority (CA) with HashiCorp Vault

### Prerequisits

- git
- vagrant
- virtualbox

## Start lab

```
git clone https://github.com/achuchulev/vagrant-vault-ca.git
cd vagrant-vault-ca
vagrant up
```

## Configure Vault

Vagrant up run:

`scripts/provision.sh` that:

- check for existing vault instance and kill it if exists
- install vault

`scripts/vault.sh` that:

- start vault in Dev mode
- print root vault token

`scripts/setup-ca.sh` that configure CA and Intermediate CA for CN "mydomain.com" as follows:

- create policies for CA
- enable the pki secrets engine at the pki path for CA
- tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours
- generate the root certificate for CN "mydomain.com" and save the certificate in CA_cert.crt
- configure the CA and Certificate Revocation List (CRL) URLs
- enable the pki secrets engine at the pki_int path for Intermediate CA
- tune the pki_int secrets engine to issue certificates with a maximum time-to-live (TTL) of 43800 hours
- generate an intermediate and save the CSR as pki_intermediate.csr
- sign the intermediate certificate with the root certificate and save the generated certificate as intermediate.cert.pem
- import signed Intermediate into Vault
- create a role named mydomain-dot-com which allows subdomains

## Request a new certificate for a subdomain

### with CLI

```
vagrant ssh
sudo su -
vault write pki_int/issue/mydomain-dot-com common_name="subdomain.mydomain.com" ttl="24h"
```

### by API call

```
$ curl --header "X-Vault-Token:<VAULT_TOKEN>" \
       --request POST \
       --data '{"common_name": "subdomain.mydomain.com", "ttl": "24h"}' \
       http://127.0.0.1:8200/v1/pki_int/issue/mydomain-dot-com | jq
```

### from Vault Web UI

- select Secrets
- select pki_int from the Secrets Engines list
- select mydomain-dot-com under Roles
- enter subdomain.mydomain.com in the Common Name field
- expand Options and then set the TTL to 24 hours
- select Hide Options and then click Generate.
- click Copy credentials and save it to a file

## Revoke Certificates

### with CLI

```
vagrant ssh vault
sudo su -
vault write pki_int/revoke serial_number=<Serial_Number>
```

### by API call

```
curl --header "X-Vault-Token:<VAULT_TOKEN>" \
       --request POST \
       --data '{"serial_number": "<Serial_Number>"}' \
       http://127.0.0.1:8200/v1/pki_int/revoke
```

### from Vault Web UI

- select Secrets
- select pki_int from the Secrets Engines list
- select the Certificates tab
- select the serial number for the certificate you wish to revoke
- click Revoke. At the confirmation, click Revoke again

## Remove Expired Certificates

### with CLI

```
vagrant ssh vault
sudo su -
vault write pki_int/tidy tidy_cert_store=true tidy_revoked_certs=true
```

### by API call

```
curl --header "X-Vault-Token: ..." \
       --request POST \
       --data '{"tidy_cert_store": true, "tidy_revoked_certs": true}' \
       http://127.0.0.1:8200/v1/pki_int/tidy
```

### from Vault Web UI

- select Secrets.
- select pki_int from the Secrets Engines list.
- select Configure.
- select the Tidy tab.
- select the check-box for Tidy the Certificate Store and Tidy the Revocation List (CRL).
- click Save
