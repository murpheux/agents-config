# ~/.codex/codex-env.sh — source from ~/.zshrc (after SSL_CERT_FILE is set):  source ~/.codex/codex-env.sh
#
# Codex builds a custom-CA-only TLS client when CODEX_CA_CERTIFICATE or SSL_CERT_FILE is set
# (in that order). SSL_CERT_FILE here is the public Mozilla bundle, which lacks the home-lab CA,
# so https://scarlet:9443 fails with "TLS handshake or certificate validation failed". Without
# either variable Codex uses the macOS platform verifier, which trusts the keychain's home-lab CA.
# Scope the removal to Codex only; other tools keep SSL_CERT_FILE.
codex() {
  ( unset SSL_CERT_FILE SSL_CERT_DIR CODEX_CA_CERTIFICATE; command codex "$@" )
}
