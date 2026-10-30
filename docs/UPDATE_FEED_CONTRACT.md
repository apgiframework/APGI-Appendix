# Signed update feed contract

Client: `UpdateSignatureVerifier.swift`. Server: `apgi-api` `GET /updates.json`
(`app/services/update_feed.py`).

**Document** (JSON): `latestVersion`, `releaseNotes` (required); `minimumVersion`,
`downloadURL`, `releaseDate`, `isCritical` (optional); `signature`, `keyId`, `algorithm`.

**Signed payload**: every field except `signature`, `keyId`, `algorithm`, as UTF-8 JSON
with sorted keys, no whitespace and `/` unescaped. Critical updates require `minimumVersion`.

**Signature**: `algorithm` is `P256-ECDSA`: ECDSA over SHA-256 of the payload, encoded as
the raw 64-byte `r‖s`, base64. The client rejects unsigned documents, unknown `keyId`s,
other algorithms, tampered fields and download URLs outside `apgiframework.com` /
`api.apgiframework.com` under `/releases/`, `/downloads/` or `/updates/` over HTTPS.

**Server behaviour**: public (no token). Answers 503 unless `UPDATE_MANIFEST_PATH`,
`UPDATE_SIGNING_PRIVATE_KEY` (P-256 PEM, from Secret Manager) and `UPDATE_SIGNING_KEY_ID`
are all set; it never serves an unsigned feed.

**Cross-language evidence**: the Swift tests verify a vector produced by the Python signer
with a fixed test-only key (`testServerSignedFeedVerifiesEndToEnd`).

**Still required for production** (not done): generate the release key offline, have the
public key reviewed independently, add it to `productionPublicKeys`, store the private key
in Secret Manager, publish a signed release, and verify it end to end from a signed build.
Rotation means shipping a client that pins the new `keyId`.
