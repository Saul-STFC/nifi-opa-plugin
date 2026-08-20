# How to generate Nifi Key- and Truststore

Follow <https://nifi.apache.org/docs/nifi-docs/html/toolkit-guide.html#potential-issues-with-wildcard-certificates>

## Convert Truststore JKS to PKCS12 for Firefox import

```bash
keytool -importkeystore -srckeystore truststore.jks -destkeystore truststore.p12 -srcstoretype JKS -deststoretype PKCS12 -srcstorepass beMkAJaKVJItosXYKfjspeFH1To7LvpwxHbrTga4lOg -deststorepass beMkAJaKVJItosXYKfjspeFH1To7LvpwxHbrTga4lOg -noprompt
```
