Release & Keystore backup

This document describes how to backup the Android keystore, move secrets to CI, and run a signed build.

1) Backup the keystore and password
- Keystore file (already created): android/app/myapp-release.keystore
- Passwords (store and key): keep them in a password manager (1Password, Bitwarden, LastPass) or an encrypted vault.

2) Produce base64 of the keystore (for CI secret)
- On Windows PowerShell (run locally):
  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes('android\\app\\myapp-release.keystore')) > keystore.b64.txt
  ```
- Open `keystore.b64.txt` and copy the full contents into your CI secret named `KEYSTORE_BASE64`.

3) CI secrets to add
- KEYSTORE_BASE64: base64 content of the keystore file (generated from your .keystore)
- KEYSTORE_STORE_PASSWORD: the keystore "store" password — the password you set when you created the .keystore. Do NOT commit this value; add it to your CI secrets or a password manager.
- KEYSTORE_KEY_ALIAS: key alias (e.g. myapp). You can confirm the alias with `keytool -list -v -keystore <keystore>` if unsure.
- KEYSTORE_KEY_PASSWORD: key password (often the same as the store password). If different, add the distinct value here.

4) GitHub Actions example
- A workflow already exists at `.github/workflows/build-release.yml` that:
  - Decodes `KEYSTORE_BASE64` into `android/app/myapp-release.keystore` on the runner
  - Uses `KEYSTORE_*` env vars to sign and build an AAB

5) Local test (before pushing to CI)
- To test locally, ensure `android/key.properties` points to `myapp-release.keystore` (it does). Then run:
  ```cmd
  flutter build appbundle --release
  ```
- The produced AAB will be at `build/app/outputs/bundle/release/app-release.aab`.

6) Security notes
- NEVER commit the keystore or its passwords to git.
- `.gitignore` already ignores `*.keystore` and `key.properties`.
- Use a password manager or your organization's secret manager.

7) If you need help
- I can help create CI secrets (I can't store secrets for you), or test the CI run after you set the secrets.
