---
name: auth-security
description: Use when implementing or modifying authentication, authorization, JWT/refresh tokens, OAuth/social login, account linking, password handling, or session/cookie logic in the backend (Phases 3–4). Encodes non-negotiable security rules that prevent account takeover and token forgery.
---

# Auth & security rules

These rules come from the adversarial security review of the auth design. They are **non-negotiable**;
violating one is a critical bug, not a style choice. The chosen model is **stateless asymmetric JWT
(RS256) access tokens + opaque, rotating, hashed refresh tokens**.

## Build approach
Auth is a **custom layer — no auth framework** — living in `app/modules/auth/` and following the
project's own router→service→repository layering. We own the full lifecycle (register / login / logout
/ refresh / verify-email / password-reset + Phase-4 OAuth association) plus the security-critical core
below: the **RS256 JWT strategy + JWKS endpoint**, **refresh-token rotation + reuse detection**, and the
**hardened account-linking policy**. Dual transport (cookie backend for web, bearer for mobile) is
hand-rolled. Errors are raised as `AppError` and rendered through the i18n envelope like everywhere
else. A complete **Phase 3 also ships `core/ratelimit`, `core/email`, and RSA key management** (see
below) — they are in-scope, not deferred. RS256 is kept for the broadest JWKS interop across future
services (the old "fastapi-users compat" rationale is moot, but RS256 still wins over EdDSA here).

## JWT (access tokens)

- **Pin exactly one algorithm at verification:** `jwt.decode(token, key, algorithms=["RS256"])`. Never
  pass a list that includes `none`, never derive the algorithm from the token header. Reject a token
  whose header `alg` ≠ the configured one. (Prevents `alg=none` and HS256-with-public-key confusion.)
- **Require and verify all claims:** `exp`, `nbf`, `iat`, `iss`, `aud`, `sub`, `jti`, `typ`. Pass
  `audience`/`issuer` explicitly, small `leeway` (≤60s). Assert `typ == "access"` in the access
  dependency and `typ == "refresh"` only in the refresh path.
- **Keys:** the RSA private key comes from a secret store / env (PEM), **never committed**. Support
  `kid`-based rotation: publish new + old `kid` in the JWKS for at least the access-token TTL; sign with
  the current `kid` only. **Refuse to boot in `PROD`** if the key is missing or equals a known dev key.
- JWKS endpoint serves **public keys only**, with `Cache-Control` and `kid`.

## Refresh tokens

- Opaque, ≥256-bit (`secrets.token_urlsafe(32)`), stored **hashed** (SHA-256). Sliding TTL with an
  absolute cap. Family-based rotation with **reuse detection**.
- **Atomic consume** to avoid races: `UPDATE refresh_token SET consumed_at=now() WHERE id=:id AND
  consumed_at IS NULL RETURNING ...`. Only the winning update issues the new token. A token presented
  after it was consumed (outside a small grace window) = replay → **revoke the whole family**.
- On password reset/change: revoke all of the user's refresh families.

## Account linking (highest takeover risk)

- **Identity is resolved by `(provider, provider_subject)` — NEVER by email.**
- **Auto-link only when:** the provider asserts `email_verified is True` (strict boolean — reject the
  string `"false"`, `"0"`, missing) **AND** the existing local account's email is verified **AND** the
  emails match case-folded. Otherwise require an authenticated manual link.
- **Strava** returns no email → never auto-link. **Apple** private-relay addresses → never auto-link.
- A pre-existing **unverified** local account is **not** a valid auto-link target (prevents pre-registration hijack).
- Enforce `UNIQUE(provider, provider_subject)` and `UNIQUE(user_id, provider)` as **DB constraints**;
  insert identities idempotently (`ON CONFLICT`) to survive concurrent callbacks. Never silently merge accounts.

## OAuth flow

- Authorization-code flow with **PKCE S256** everywhere. `state` is single-use and **bound to the
  user's session/cookie** (signed-but-unbound state still allows login-CSRF). Verify OIDC `nonce`.
- Verify provider `id_token`: signature via the provider JWKS (cached with TTL), plus `aud == client_id`,
  `iss`, `exp`.

## Passwords & misc

- **argon2id** via `argon2-cffi` with pinned OWASP-floor params (memory ≥ 19 MiB, time_cost ≥ 2,
  parallelism = 2, 16-byte salt, 32-byte hash); `needs_rehash` upgrade on login; cap input length.
- Email-verification / password-reset tokens: ≥256-bit, stored hashed, short TTL, **atomic single-use**
  (`DELETE ... WHERE token_hash=:h AND used_at IS NULL RETURNING`). Don't reveal whether an email exists.
- **Rate-limit** `login`, `refresh`, `password-reset`, `email-verify` (per-IP and per-account). It is
  owned by `app/core/ratelimit` and consumed by auth — do not ship auth without it.
- Web cookie mode: `__Host-` prefixed, `HttpOnly; Secure; SameSite=Lax; Path=/auth/refresh`, plus an
  `Origin`/CSRF check on state-changing auth endpoints. Mobile uses `Authorization: Bearer`.
- Separate `is_active` (enabled) from `is_email_verified` (gates login). Provide a fast revocation path
  (short access TTL + a `jti`/`token_version` deny check) for ban/logout-all.
- Never log tokens, passwords, or `Authorization`/`Cookie` headers.

## Done criteria

Security-focused tests exist: forged `alg=none`/HS256 token rejected; expired/wrong-`aud` rejected;
refresh replay revokes the family; unverified-email auto-link refused; reset token is single-use. Plus
`make check` green.
