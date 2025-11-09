import os
from typing import Any, Dict

import jwt
from fastapi import HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError, PyJWKClient
from starlette import status

from main import app, AUTH0_DOMAIN

API_AUDIENCE = os.getenv("API_AUDIENCE", "")
ALGORITHMS = ["RS256"]

# Security scheme for FastAPI endpoints. Use like:
#   @app.get('/private')
#   def private(payload=Security(verify_jwt)):
#       return {"sub": payload["sub"]}
bearer_scheme = HTTPBearer()

# (Auth0/JWT code temporarily ignored per user request.)

def _get_jwks_client_cached() -> PyJWKClient:
    client = getattr(app.state, "jwks_client", None)
    if client:
        return client
    if not AUTH0_DOMAIN:
        raise RuntimeError("AUTH0_DOMAIN not configured; cannot fetch JWKS")
    jwks_url = f"https://{AUTH0_DOMAIN}/.well-known/jwks.json"
    client = PyJWKClient(jwks_url)
    app.state.jwks_client = client
    return client


def verify_jwt(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
) -> Dict[str, Any]:
    """Verify an incoming JWT using Auth0's JWKS and return the token payload.

    Use as a dependency via FastAPI's Security(...) to protect endpoints.
    """
    token = credentials.credentials
    # Use PyJWKClient to obtain the signing key for this token. This avoids
    # assuming RSA or converting to PEM; PyJWT handles the JWK types.
    try:
        client = _get_jwks_client_cached()
        signing_key = client.get_signing_key_from_jwt(token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Unable to obtain signing key: {str(e)}",
        )

    issuer = f"https://{AUTH0_DOMAIN}/" if AUTH0_DOMAIN else None

    try:
        # Pass the signing key object via the signing_key parameter to jwt.decode
        payload = jwt.decode(
            token,
            signing_key=signing_key.key,
            algorithms=ALGORITHMS,
            audience=API_AUDIENCE or None,
            issuer=issuer,
        )
        return payload
    except InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation error: {str(e)}",
        )