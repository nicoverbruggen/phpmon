#!/bin/bash

# Configuration
DOMAIN="${1:-test.test}"
VALET_CA_DIR="$HOME/.config/valet/CA"
VALET_CERT_DIR="$HOME/.config/valet/Certificates"

# Check if Valet CA exists
if [ ! -f "$VALET_CA_DIR/LaravelValetCASelfSigned.pem" ]; then
    echo "Error: Valet CA not found at $VALET_CA_DIR"
    echo "Make sure Laravel Valet is installed and secured."
    exit 1
fi

echo "Generating expired certificate for: $DOMAIN"

# Generate private key for the domain
openssl genrsa -out "$VALET_CERT_DIR/$DOMAIN.key" 2048

# Create certificate signing request (CSR)
openssl req -new -key "$VALET_CERT_DIR/$DOMAIN.key" \
    -out "/tmp/$DOMAIN.csr" \
    -subj "/C=US/ST=Test/L=Test/O=Laravel Valet/CN=$DOMAIN"

# Create extension file for SAN (Subject Alternative Name)
cat > "/tmp/$DOMAIN.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF

# Use faketime to generate certificate with past dates
# Certificate valid from Jan 1, 2023 to Jan 2, 2023 (expired)
faketime '2023-01-01' openssl x509 -req \
    -in "/tmp/$DOMAIN.csr" \
    -CA "$VALET_CA_DIR/LaravelValetCASelfSigned.pem" \
    -CAkey "$VALET_CA_DIR/LaravelValetCASelfSigned.key" \
    -CAcreateserial \
    -out "$VALET_CERT_DIR/$DOMAIN.crt" \
    -days 1 \
    -sha256 \
    -extfile "/tmp/$DOMAIN.ext"

# Cleanup
rm "/tmp/$DOMAIN.csr" "/tmp/$DOMAIN.ext"

echo "✓ Expired certificate generated:"
echo "  Certificate: $VALET_CERT_DIR/$DOMAIN.crt"
echo "  Key: $VALET_CERT_DIR/$DOMAIN.key"
echo ""
echo "Certificate details:"
openssl x509 -in "$VALET_CERT_DIR/$DOMAIN.crt" -noout -dates

echo ""
echo "Reloading the domains list should now indicate $DOMAIN is expired."
