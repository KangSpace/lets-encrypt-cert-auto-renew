x-service test record

1. cloudflare
   - set-dns-txt
    ```
    sh cloudflare-service.sh --zone-identifier ? --token ? --domain kangspace.org --hostname kangspace.org --txt 1234 --set-dns-txt
    ```
   - del-dns-txt
   ```
   sh cloudflare-service.sh --zone-identifier ? --token ? --domain kangspace.org --hostname kangspace.org --id 9413812b481031dbb2573a9900f38887 --del-dns-txt
   ```