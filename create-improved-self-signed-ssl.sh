#!/bin/bash
#############################################################################
# CREATE IMPROVED SELF-SIGNED SSL CERTIFICATE
# For prestadores.clinfec.com.br
# Valid for 10 years with proper SAN (Subject Alternative Names)
#############################################################################

set -e

echo "=============================================="
echo "  CREATING IMPROVED SELF-SIGNED SSL"
echo "  Domain: prestadores.clinfec.com.br"
echo "=============================================="
echo ""

DOMAIN="prestadores.clinfec.com.br"
CERT_DIR="/etc/ssl/private"
CERT_NAME="prestadores-selfsigned"
BACKUP_DIR="/opt/webserver/ssl-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"
mkdir -p "$CERT_DIR"

# Create OpenSSL config with SAN
cat > /tmp/openssl-san.cnf << EOFSSL
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=BR
ST=State
L=City
O=Clinfec
OU=IT Department
emailAddress=admin@clinfec.com.br
CN=prestadores.clinfec.com.br

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = prestadores.clinfec.com.br
DNS.2 = www.prestadores.clinfec.com.br
EOFSSL

echo "Step 1: Generating 4096-bit RSA private key..."
openssl genrsa -out "$CERT_DIR/${CERT_NAME}.key" 4096 2>/dev/null
echo "✓ Private key generated"

echo "Step 2: Creating certificate signing request..."
openssl req -new \
    -key "$CERT_DIR/${CERT_NAME}.key" \
    -out "/tmp/${CERT_NAME}.csr" \
    -config /tmp/openssl-san.cnf 2>/dev/null
echo "✓ CSR created"

echo "Step 3: Generating self-signed certificate (valid 10 years)..."
openssl x509 -req \
    -days 3650 \
    -in "/tmp/${CERT_NAME}.csr" \
    -signkey "$CERT_DIR/${CERT_NAME}.key" \
    -out "$CERT_DIR/${CERT_NAME}.crt" \
    -extensions v3_req \
    -extfile /tmp/openssl-san.cnf 2>/dev/null
echo "✓ Certificate created"

echo "Step 4: Setting permissions..."
chmod 600 "$CERT_DIR/${CERT_NAME}.key"
chmod 644 "$CERT_DIR/${CERT_NAME}.crt"
echo "✓ Permissions set"

echo "Step 5: Verifying certificate..."
echo ""
openssl x509 -in "$CERT_DIR/${CERT_NAME}.crt" -noout -text | grep -A 3 "Subject:"
openssl x509 -in "$CERT_DIR/${CERT_NAME}.crt" -noout -text | grep -A 2 "Validity"
openssl x509 -in "$CERT_DIR/${CERT_NAME}.crt" -noout -text | grep -A 3 "Subject Alternative Name"
echo ""

# Create certificate info
cat > "$BACKUP_DIR/SELF-SIGNED-CERT-INFO-$TIMESTAMP.txt" << EOFINFO
SELF-SIGNED SSL CERTIFICATE INFORMATION
========================================
Date: $(date '+%Y-%m-%d %H:%M:%S')
Domain: $DOMAIN

Certificate Paths:
- Certificate: $CERT_DIR/${CERT_NAME}.crt
- Private Key: $CERT_DIR/${CERT_NAME}.key

Certificate Details:
$(openssl x509 -in "$CERT_DIR/${CERT_NAME}.crt" -noout -text | grep -A 3 "Subject:")
$(openssl x509 -in "$CERT_DIR/${CERT_NAME}.crt" -noout -text | grep -A 2 "Validity")
$(openssl x509 -in "$CERT_DIR/${CERT_NAME}.crt" -noout -text | grep -A 3 "Subject Alternative Name")

Key Size: 4096-bit RSA
Validity: 10 years
Type: Self-Signed

IMPORTANT NOTES:
================
1. This is a SELF-SIGNED certificate
2. Browsers will show security warnings
3. For VALID SSL certificate:
   - Go to Hostinger hPanel
   - Navigate to: SSL/TLS → Install SSL
   - Select: Let's Encrypt (Free)
   - Domain: prestadores.clinfec.com.br
   - Click: Install

REASON FOR SELF-SIGNED:
=======================
Domain prestadores.clinfec.com.br resolves to:
- IP: 82.180.156.19 (Hostinger infrastructure)
- VPS IP: 2a02:4780:66:f6b4::1 (different)

The domain is behind Hostinger proxy/CDN, so Let's Encrypt
validation cannot reach this VPS directly. SSL must be installed
via Hostinger hPanel control panel.

Status: SELF-SIGNED ACTIVE (Temporary)
Recommended: Install valid SSL via hPanel
EOFINFO

echo "✓ Certificate info saved: $BACKUP_DIR/SELF-SIGNED-CERT-INFO-$TIMESTAMP.txt"
echo ""
echo "=============================================="
echo "  SELF-SIGNED SSL CREATED SUCCESSFULLY"
echo "=============================================="
echo ""
echo "Certificate: $CERT_DIR/${CERT_NAME}.crt"
echo "Private Key: $CERT_DIR/${CERT_NAME}.key"
echo ""
echo "⚠️  IMPORTANT:"
echo "This is a SELF-SIGNED certificate (browsers will warn)"
echo ""
echo "For VALID SSL certificate:"
echo "1. Access Hostinger hPanel"
echo "2. Go to: SSL/TLS → Install SSL"
echo "3. Select: Let's Encrypt (Free)"
echo "4. Install for: prestadores.clinfec.com.br"
echo ""
