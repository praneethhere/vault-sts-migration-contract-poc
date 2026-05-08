from flask import Flask, request, jsonify
from cryptography.hazmat.primitives.asymmetric import rsa
from jwt.utils import base64url_encode
import hashlib
import jwt
import os
import time

app = Flask(__name__)

ISSUER = os.getenv("ISSUER", "http://oidc-issuer:8080")
TOKEN_TTL_SECONDS = int(os.getenv("TOKEN_TTL_SECONDS", "900"))

key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
public_numbers = key.public_key().public_numbers()

def b64(n: int) -> str:
    return base64url_encode(
        n.to_bytes((n.bit_length() + 7) // 8, "big")
    ).decode("utf-8")

kid = hashlib.sha256(str(public_numbers.n).encode()).hexdigest()[:16]

JWKS = {
    "keys": [
        {
            "kty": "RSA",
            "use": "sig",
            "kid": kid,
            "alg": "RS256",
            "n": b64(public_numbers.n),
            "e": b64(public_numbers.e),
        }
    ]
}

@app.route("/.well-known/openid-configuration")
def openid_config():
    return jsonify({
        "issuer": ISSUER,
        "jwks_uri": f"{ISSUER}/certs",
        "id_token_signing_alg_values_supported": ["RS256"],
        "claims_supported": [
            "sub",
            "aud",
            "iss",
            "exp",
            "cluster",
            "namespace",
            "saname",
        ],
    })

@app.route("/certs")
def certs():
    return jsonify(JWKS)

@app.route("/mint")
def mint():
    cluster = request.args.get("cluster", "cluster-b")
    namespace = request.args.get("namespace", "sales")
    saname = request.args.get("saname", "sales-app-sa")
    aud = request.args.get("aud", "vault")

    now = int(time.time())

    claims = {
        "iss": ISSUER,
        "aud": aud,
        "iat": now,
        "nbf": now,
        "exp": now + TOKEN_TTL_SECONDS,
        "sub": f"{cluster}:{namespace}:{saname}",
        "cluster": cluster,
        "namespace": namespace,
        "saname": saname,
    }

    token = jwt.encode(
        claims,
        key,
        algorithm="RS256",
        headers={"kid": kid},
    )

    return jsonify({
        "token": token,
        "claims": claims,
    })

@app.route("/healthz")
def healthz():
    return jsonify({"status": "ok", "issuer": ISSUER})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
