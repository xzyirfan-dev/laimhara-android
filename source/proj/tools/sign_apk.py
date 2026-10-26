#!/usr/bin/env python3
"""Sign APK (v1 + v2) dengan zip alignment. usage: sign_apk.py in.apk out.apk"""
import sys, os, struct, zipfile, hashlib, base64, datetime
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives.serialization import pkcs7

KEY = os.path.expanduser('~/.laimhara_key.pem')
CRT = os.path.expanduser('~/.laimhara_cert.pem')

def load_key():
    if not os.path.exists(KEY):
        k = rsa.generate_private_key(65537, 2048)
        name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'Laimhara'), x509.NameAttribute(NameOID.ORGANIZATION_NAME, 'Irfan')])
        c = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(k.public_key())
             .serial_number(x509.random_serial_number()).not_valid_before(datetime.datetime(2024, 1, 1))
             .not_valid_after(datetime.datetime(2056, 1, 1)).sign(k, hashes.SHA256()))
        open(KEY, 'wb').write(k.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
        open(CRT, 'wb').write(c.public_bytes(serialization.Encoding.PEM))
    k = serialization.load_pem_private_key(open(KEY, 'rb').read(), None)
    c = x509.load_pem_x509_certificate(open(CRT, 'rb').read())
    return k, c

def b64(b): return base64.b64encode(b).decode()

def v1_files(zin, names):
    mf = ['Manifest-Version: 1.0', 'Created-By: 1.0 (Android)', '', '']
    entries = {}
    for n in names:
        d = hashlib.sha256(zin.read(n)).digest()
        sec = 'Name: %s\r\nSHA-256-Digest: %s\r\n\r\n' % (n, b64(d))
        entries[n] = sec
    mf_txt = 'Manifest-Version: 1.0\r\nCreated-By: 1.0 (Android)\r\n\r\n' + ''.join(entries.values())
    sf = 'Signature-Version: 1.0\r\nSHA-256-Digest-Manifest: %s\r\nCreated-By: 1.0 (Android)\r\n\r\n' % b64(hashlib.sha256(mf_txt.encode()).digest())
    for n, sec in entries.items():
        sf += 'Name: %s\r\nSHA-256-Digest: %s\r\n\r\n' % (n, b64(hashlib.sha256(sec.encode()).digest()))
    return mf_txt.encode(), sf.encode()

def rewrite(src, dst, key, cert):
    zin = zipfile.ZipFile(src)
    names = [i.filename for i in zin.infolist() if not i.filename.endswith('/') and not i.filename.startswith('META-INF/')]
    mf, sf = v1_files(zin, names)
    rsa_sig = pkcs7.PKCS7SignatureBuilder().set_data(sf).add_signer(cert, key, hashes.SHA256()).sign(
        serialization.Encoding.DER, [pkcs7.PKCS7Options.DetachedSignature, pkcs7.PKCS7Options.NoCapabilities])
    zout = zipfile.ZipFile(dst, 'w')
    def put(name, data, comp):
        zi = zipfile.ZipInfo(name, (2024, 1, 1, 0, 0, 0))
        zi.compress_type = comp
        zi.external_attr = 0o644 << 16
        if comp == zipfile.ZIP_STORED:
            align = 16384 if name.endswith('.so') else 4
            off = zout.fp.tell() + 30 + len(name.encode())
            pad = (-off) % align
            if pad:
                while pad < 4: pad += align
                zi.extra = struct.pack('<HH', 0xD935, pad - 4) + b'\0' * (pad - 4)
        zout.writestr(zi, data)
    put('META-INF/MANIFEST.MF', mf, zipfile.ZIP_DEFLATED)
    put('META-INF/CERT.SF', sf, zipfile.ZIP_DEFLATED)
    put('META-INF/CERT.RSA', rsa_sig, zipfile.ZIP_DEFLATED)
    for i in zin.infolist():
        if i.filename.endswith('/') or i.filename.startswith('META-INF/'):
            continue
        comp = zipfile.ZIP_STORED if (i.compress_type == zipfile.ZIP_STORED or i.filename.endswith('.so') or i.filename == 'resources.arsc') else zipfile.ZIP_DEFLATED
        put(i.filename, zin.read(i.filename), comp)
    zout.close()

def v2_sign(path, key, cert):
    data = bytearray(open(path, 'rb').read())
    eocd = data.rfind(b'PK\x05\x06')
    cd_off = struct.unpack('<I', data[eocd + 16:eocd + 20])[0]
    sections = [bytes(data[:cd_off]), bytes(data[cd_off:eocd]), bytes(data[eocd:])]
    eo = bytearray(sections[2]); eo[16:20] = struct.pack('<I', cd_off); sections[2] = bytes(eo)
    chunk = 1024 * 1024
    digests = []
    for sec in sections:
        for o in range(0, len(sec), chunk):
            c = sec[o:o + chunk]
            digests.append(hashlib.sha256(b'\xa5' + struct.pack('<I', len(c)) + c).digest())
    top = hashlib.sha256(b'\x5a' + struct.pack('<I', len(digests)) + b''.join(digests)).digest()
    cert_der = cert.public_bytes(serialization.Encoding.DER)
    def lp(b): return struct.pack('<I', len(b)) + b
    digest_entry = lp(struct.pack('<I', 0x0103) + lp(top))
    signed = lp(digest_entry) + lp(lp(cert_der)) + lp(b'')
    sig = key.sign(signed, padding.PKCS1v15(), hashes.SHA256())
    pub = key.public_key().public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    signer = lp(signed) + lp(lp(struct.pack('<I', 0x0103) + lp(sig))) + lp(pub)
    v2 = lp(lp(signer))
    pair = struct.pack('<Q', len(v2) + 4) + struct.pack('<I', 0x7109871a) + v2
    block = struct.pack('<Q', len(pair) + 8 + 16) + pair + struct.pack('<Q', len(pair) + 8 + 16) + b'APK Sig Block 42'
    new_cd = cd_off + len(block)
    out = bytes(data[:cd_off]) + block + bytes(data[cd_off:eocd]) + bytes(eo[:16]) + struct.pack('<I', new_cd) + bytes(eo[20:])
    open(path, 'wb').write(out)

if __name__ == '__main__':
    key, cert = load_key()
    rewrite(sys.argv[1], sys.argv[2], key, cert)
    v2_sign(sys.argv[2], key, cert)
    print('signed', sys.argv[2], os.path.getsize(sys.argv[2]))
