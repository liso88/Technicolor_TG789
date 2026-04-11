#!/usr/bin/env python3
"""
Script per firmare certificati OpenVPN usando Python (non richiede easy-rsa)
Uso: python3 sign_cert_python.py <common-name> [--target-dir easy-rsa-certs]
"""

import sys
import os
from pathlib import Path
from datetime import datetime, timedelta
import argparse
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtensionOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend

def sign_certificate(common_name, target_dir="easy-rsa-certs"):
    """Firma un certificato usando la CA"""
    
    pki_dir = Path(target_dir) / "pki"
    
    # Percorsi dei file
    ca_crt = pki_dir / "ca.crt"
    ca_key = pki_dir / "private" / "ca.key"
    req_file = pki_dir / "reqs" / f"{common_name}.req"
    out_crt = pki_dir / "issued" / f"{common_name}.crt"
    
    # Verifica che i file esistano
    for f in [ca_crt, ca_key, req_file]:
        if not f.exists():
            print(f"[ERRORE] File non trovato: {f}", file=sys.stderr)
            return False
    
    print(f"==== Firma Certificato OpenVPN ====")
    print(f"Nome certificato: {common_name}")
    print()
    
    try:
        # Leggi la CA
        print("[1/3] Caricamento CA...")
        with open(ca_crt, "rb") as f:
            ca_cert = x509.load_pem_x509_certificate(f.read(), default_backend())
        
        with open(ca_key, "rb") as f:
            ca_key_pem = f.read()
            try:
                ca_key_obj = serialization.load_pem_private_key(
                    ca_key_pem, password=None, backend=default_backend()
                )
            except Exception as e:
                # Se ha pswd
                print(f"[ERRORE] Impossibile caricare chiave CA: {e}", file=sys.stderr)
                return False
        
        print("[OK] CA caricata")
        print()
        
        # Leggi la richiesta di certificato
        print("[2/3] Caricamento richiesta certificato...")
        with open(req_file, "rb") as f:
            csr = x509.load_pem_x509_csr(f.read(), default_backend())
        
        print("[OK] Richiesta caricata")
        print()
        
        # Crea il certificato firmato
        print("[3/3] Firma certificato...")
        cert_builder = x509.CertificateBuilder()
        cert_builder = cert_builder.subject_name(csr.subject)
        cert_builder = cert_builder.issuer_name(ca_cert.subject)
        cert_builder = cert_builder.public_key(csr.public_key())
        cert_builder = cert_builder.serial_number(x509.random_serial_number())
        cert_builder = cert_builder.not_valid_before(datetime.utcnow())
        cert_builder = cert_builder.not_valid_after(
            datetime.utcnow() + timedelta(days=3650)
        )
        
        # Aggiungi estensioni dalla richiesta
        for ext in csr.extensions:
            cert_builder = cert_builder.add_extension(ext.value, critical=ext.critical)
        
        # Aggiungi estensioni standard
        cert_builder = cert_builder.add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True,
        )
        
        cert_builder = cert_builder.add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                content_commitment=False,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=False,
                crl_sign=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
        
        # Firma il certificato
        new_cert = cert_builder.sign(
            ca_key_obj, hashes.SHA256(), default_backend()
        )
        
        # Salva il certificato
        with open(out_crt, "wb") as f:
            f.write(new_cert.public_bytes(serialization.Encoding.PEM))
        
        print("[OK] Certificato firmato e salvato!")
        print()
        print("==== Firma completata con successo! ====")
        print()
        print(f"Certificato: {out_crt}")
        print()
        print("Prossimo step: caricare i certificati sul modem")
        print()
        print("Esegui:")
        print(f'  cd "{pki_dir}"')
        print()
        print("Quindi carica i 4 file con plink:")
        print(f'  plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/ca.crt" < ca.crt')
        print(f'  plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/server.crt" < issued/{common_name}.crt')
        print(f'  plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/keys/server.key" < private/{common_name}.key')
        print(f'  plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/dh.pem" < dh.pem')
        return True
        
    except Exception as e:
        print(f"[ERRORE] Firma fallita: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Firma certificati OpenVPN")
    parser.add_argument("common_name", help="Nome del certificato (es: server, tommi)")
    parser.add_argument("--target-dir", default="easy-rsa-certs", help="Directory target (default: easy-rsa-certs)")
    
    args = parser.parse_args()
    
    if not sign_certificate(args.common_name, args.target_dir):
        sys.exit(1)
