# fpga_hash_512
Hardware FPGA implementation of PBKDF2-HMAC-SHA512 for restricted key sizes (<= 1024 bits), salts (== 256 bits), and outputs only the first 512 bits.

## macOS password recovery
With root access:
```bash
sudo dscl . -read /Users/<Bob> dsAttrTypeNative:ShadowHashData | tail -n 1 | tr -dc "0-9a-f " | xxd -p -r | plutil -convert xml1 - -o -
```

Under `SALTED-SHA512-PBKDF2`, there are base64 encoded `entropy` for the
resulting hash and `salt`. `iterations` indicates the number of PBKDF2 HMAC cycles.

## References
1. [US Secure Hash Algorithms (SHA and HMAC-SHA)](https://www.rfc-editor.org/rfc/rfc6234)
2. [Password-Based Cryptography Specification](https://www.rfc-editor.org/rfc/rfc8018)
