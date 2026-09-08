#!/usr/bin/env python3
"""
Generate a printable PDF test pack of Express Mode QR codes for Google Play
closed-testing testers of the LoyaltyCards Customer Wallet app.

For each business in seed_businesses.json, produces one A4 sheet with:
  - 1 "Add Card" QR (CardIssueToken, genuinely ECDSA-signed - the customer
    app verifies this signature in every mode, so it must be real)
  - 3 "Add Stamp" QR codes (StampToken, denominations of 1/2/3 stamps -
    Express Mode never checks the stamp signature, only expiry/stampCount,
    so these carry a placeholder signature by design, matching real
    Express Mode behavior)
  - 1 "Business Backup" QR (SupplierConfigBackup, type "recovery" -
    non-expiring, HMAC-signed from the business's own private key)

Every payload format below was reverse-engineered from the actual Dart
source (not guessed) - see the comments at each encoding step for the
exact file/function it mirrors. Run verify_with_dart.py afterwards to
confirm the app's own code accepts what this script generates.

Usage:
    python3 generate_test_assets.py

Requires: cryptography, qrcode (pip install cryptography qrcode)
Requires Chrome/Chromium for the HTML -> PDF step (set CHROME_PATH env var
to override the default macOS location).
"""

import base64
import json
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path

from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
from cryptography.hazmat.primitives import hashes
import hmac as hmac_module
import hashlib
import qrcode

SCRIPT_DIR = Path(__file__).resolve().parent
SEED_PATH = SCRIPT_DIR / "seed_businesses.json"
OUTPUT_DIR = SCRIPT_DIR / "output"
CHROME_PATH = os.environ.get(
    "CHROME_PATH", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)

# Icon index -> emoji, purely for the printed sheet's visual header - the
# app itself renders these via BusinessIcons.icons (Flutter IconData), which
# isn't reachable from this offline script, so an emoji stand-in is used for
# the human-facing label only. Never encoded into any QR payload.
ICON_EMOJI = {
    1: "☕",   # local_cafe
    2: "\U0001F37D",  # restaurant
    5: "\U0001F950",  # bakery_dining
    10: "\U0001F6D2",  # local_grocery_store
    13: "\U0001F486",  # spa
    23: "\U0001F4D6",  # menu_book
}


# --------------------------------------------------------------------------
# Crypto primitives - mirrors source/supplier_app/lib/services/key_manager.dart
# exactly (encoding format confirmed against docs/technical/CRYPTOGRAPHIC_DESIGN.md
# and cross-checked against source/shared/lib/utils/crypto_utils.dart's decode side).
# --------------------------------------------------------------------------


def bigint_to_bytes(n: int) -> bytes:
    """Mirrors KeyManager._bigIntToBytes: minimal-length big-endian bytes,
    hex padded to an even number of digits only (NOT fixed-width 32 bytes)."""
    if n == 0:
        return b"\x00"
    hex_str = format(n, "x")
    if len(hex_str) % 2 == 1:
        hex_str = "0" + hex_str
    return bytes.fromhex(hex_str)


def encode_length(n: int) -> bytes:
    """4-byte big-endian length prefix, per KeyManager._encodeLength."""
    return n.to_bytes(4, "big")


def encode_public_key(public_key) -> str:
    """Mirrors KeyManager.encodePublicKey:
    [4-byte len(x)][x bytes][4-byte len(y)][y bytes], base64."""
    numbers = public_key.public_numbers()
    x_bytes = bigint_to_bytes(numbers.x)
    y_bytes = bigint_to_bytes(numbers.y)
    combined = encode_length(len(x_bytes)) + x_bytes + encode_length(len(y_bytes)) + y_bytes
    return base64.b64encode(combined).decode("ascii")


def encode_private_key_raw(private_key) -> str:
    """Mirrors KeyManager.storePrivateKey: base64(bigIntToBytes(d)) - no
    length prefix, just the raw scalar. This is the exact string format
    SupplierConfigBackup.privateKey expects."""
    d = private_key.private_numbers().private_value
    return base64.b64encode(bigint_to_bytes(d)).decode("ascii")


def sign_data(private_key, data: str) -> str:
    """Mirrors KeyManager.signData: ECDSA/SHA-256 over the UTF-8 bytes of
    `data`, re-encoded from DER into [4-byte len(r)][r][4-byte len(s)][s],
    base64. `cryptography` returns a DER signature; decode_dss_signature
    extracts the raw (r, s) integers."""
    der_sig = private_key.sign(data.encode("utf-8"), ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(der_sig)
    r_bytes = bigint_to_bytes(r)
    s_bytes = bigint_to_bytes(s)
    combined = encode_length(len(r_bytes)) + r_bytes + encode_length(len(s_bytes)) + s_bytes
    return base64.b64encode(combined).decode("ascii")


def derive_backup_hmac_key(private_key_b64: str) -> bytes:
    """Mirrors SupplierConfigBackup._deriveHMACKey exactly: an HKDF-Extract
    then HKDF-Expand (single block) construction using HMAC-SHA256, with the
    same public salt/info strings as the Dart source - no hidden secret,
    fully derivable from the business's own private key bytes."""
    private_key_bytes = base64.b64decode(private_key_b64)
    salt = b"LoyaltyCards-Backup-HMAC-Salt-v1"
    info = b"signature-key"
    prk = hmac_module.new(salt, private_key_bytes, hashlib.sha256).digest()
    expand_input = info + b"\x01"
    return hmac_module.new(prk, expand_input, hashlib.sha256).digest()


def dart_iso8601(dt) -> str:
    """Formats a naive local datetime exactly as Dart's DateTime.toIso8601String()
    would for a non-UTC instance: YYYY-MM-DDTHH:MM:SS.ffffff (6-digit
    microseconds, no timezone suffix). Chosen so DateTime.parse(this).toIso8601String()
    round-trips to the identical string on the Dart side, since
    SupplierConfigBackup's HMAC is computed over the *parsed-then-reformatted*
    timestamp, not the raw JSON string."""
    return dt.strftime("%Y-%m-%dT%H:%M:%S.%f")


# --------------------------------------------------------------------------
# Token builders
# --------------------------------------------------------------------------


def generate_keypair():
    private_key = ec.generate_private_key(ec.SECP256R1())
    public_key = private_key.public_key()
    return private_key, public_key


def build_card_issue_token(business: dict, now_ms: int) -> dict:
    """Mirrors CardIssueToken (shared/lib/models/qr_tokens.dart). Signed
    over businessId:businessName:publicKey:stampsRequired:brandColor:cardId:timestamp:mode
    with cardId empty (no pre-applied stamps, so it's fine to omit per the
    model's own validationError() check) - see CardIssueToken.getSignatureData().
    mode is 'express' (OperationModeExtension.toStorageString() current value,
    NOT the older 'simple' string some pre-existing seed scripts still use)."""
    private_key = business["_private_key_obj"]
    public_key_str = business["_public_key_str"]
    business_id = business["businessId"]
    name = business["name"]
    stamps_required = business["stampsRequired"]
    brand_color = business["brandColor"]
    logo_index = business["logoIndex"]
    mode = "express"
    card_id_value = ""  # omitted from JSON; empty string in the signed data

    signature_data = (
        f"{business_id}:{name}:{public_key_str}:{stamps_required}:"
        f"{brand_color}:{card_id_value}:{now_ms}:{mode}"
    )
    signature = sign_data(private_key, signature_data)

    return {
        "type": "card_issue",
        "businessId": business_id,
        "businessName": name,
        "publicKey": public_key_str,
        "stampsRequired": stamps_required,
        "brandColor": brand_color,
        "logoIndex": logo_index,
        "mode": mode,
        "timestamp": now_ms,
        "signature": signature,
        "initialStamps": [],
    }


def build_stamp_token(business: dict, stamp_count: int, cooldown_seconds: int, now_ms: int) -> dict:
    """Mirrors StampToken (shared/lib/models/qr_tokens.dart). cardId MUST be
    exactly 'express-mode-stamp' (or 'simple-mode-stamp') - this literal
    string is the Smart Routing sentinel QrScannerController checks for
    (source/customer_app/lib/controllers/qr_scanner_controller.dart) to look
    the card up by businessId instead of by cardId. Signature is a
    placeholder: confirmed by reading the controller's Express Mode branch
    that only expiryDate and stampCount are validated for Express Mode -
    the signature field is required to be non-empty but is never
    cryptographically checked."""
    return {
        "type": "stamp_token",
        "id": str(uuid.uuid4()),
        "cardId": "express-mode-stamp",
        "businessId": business["businessId"],
        "stampNumber": 1,
        "timestamp": now_ms,
        "previousHash": "",
        "signature": "express-mode-unsigned",
        "additionalStamps": [],
        "stampCount": stamp_count,
        "scanInterval": cooldown_seconds * 1000,
        "businessName": business["name"],
        "brandColor": business["brandColor"],
        "logoIndex": business["logoIndex"],
        "stampsRequired": business["stampsRequired"],
    }


def build_supplier_backup(business: dict, now_dt) -> dict:
    """Mirrors SupplierConfigBackup.createRecoveryBackup (shared/lib/models/
    supplier_config_backup.dart) - type 'recovery' never expires, matching
    "restore this business in the future". Known, documented, pre-existing
    app gap (DEFECT_TRACKER.md): logoIndex and scanInterval are NOT part of
    this model, so restoring from this backup resets the icon to Store and
    the scan cooldown to the app's default - not something this script can
    fix, since it's the real app's restore code that would need the field
    added."""
    business_id = business["businessId"]
    name = business["name"]
    private_key_str = business["_private_key_str"]
    public_key_str = business["_public_key_str"]
    stamps_required = business["stampsRequired"]
    brand_color = business["brandColor"]
    timestamp_str = dart_iso8601(now_dt)

    data_to_sign = (
        f"recovery|1|{business_id}|{name}|{private_key_str}|{public_key_str}|"
        f"{stamps_required}|{brand_color}|express|{timestamp_str}|null"
    )
    hmac_key = derive_backup_hmac_key(private_key_str)
    signature = base64.b64encode(
        hmac_module.new(hmac_key, data_to_sign.encode("utf-8"), hashlib.sha256).digest()
    ).decode("ascii")

    return {
        "type": "recovery",
        "version": 1,
        "businessId": business_id,
        "businessName": name,
        "privateKey": private_key_str,
        "publicKey": public_key_str,
        "stampsRequired": stamps_required,
        "brandColor": brand_color,
        "operationMode": "express",
        "timestamp": timestamp_str,
        "expiresAt": None,
        "signature": signature,
    }


# --------------------------------------------------------------------------
# Seed file: load, fill in missing key pairs, persist immediately
# --------------------------------------------------------------------------


def load_seed(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_seed(path: Path, seed: dict) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(seed, f, indent=2)
        f.write("\n")


def ensure_keys(seed: dict, seed_path: Path) -> bool:
    """For any business with keys == null, generates a new key pair and
    writes it back into the seed dict's on-disk JSON (base64 public/private
    key strings only - never the live key objects, which aren't
    JSON-serializable and are re-derived in memory each run from these
    strings). Saves immediately after each new key pair, not just at the
    end, so an interrupted run never loses an already-generated key.
    Returns True if any keys were generated."""
    changed = False
    for business in seed["businesses"]:
        if business.get("keys") is None:
            private_key, public_key = generate_keypair()
            business["keys"] = {
                "businessId": str(uuid.uuid4()),
                "privateKey": encode_private_key_raw(private_key),
                "publicKey": encode_public_key(public_key),
            }
            changed = True
            print(f"  generated new key pair for '{business['name']}'")
            save_seed(seed_path, seed)  # persist immediately, not at the end
    return changed


def load_keypair_from_seed(business: dict):
    """Reconstructs the actual EC private key object from the stored raw
    scalar so this business can keep signing identically across runs -
    mirrors KeyManager.decodePrivateKey's BigInt-from-bytes reconstruction."""
    d_bytes = base64.b64decode(business["keys"]["privateKey"])
    d = int.from_bytes(d_bytes, "big")
    private_key = ec.derive_private_key(d, ec.SECP256R1())
    return private_key, private_key.public_key()


# --------------------------------------------------------------------------
# QR image generation
# --------------------------------------------------------------------------


def qr_data_uri(payload: dict) -> str:
    """SVG output, not the qrcode library's default PIL/PNG backend - PIL's
    compiled extension on this machine is an x86_64 build that fails to
    import under the arm64 Python actually running (confirmed the same
    failure and same fix earlier this session), so PNG rendering is
    unavailable here regardless of what the QR payload contains."""
    import qrcode.image.svg

    text = json.dumps(payload, separators=(",", ":"))
    img = qrcode.make(
        text,
        image_factory=qrcode.image.svg.SvgPathImage,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=20,
        border=2,
    )
    import io

    buf = io.BytesIO()
    img.save(buf)
    svg_bytes = buf.getvalue()
    # Add an explicit white background rect - SvgPathImage only emits the
    # dark-module path on a transparent canvas, which would otherwise
    # disappear against this template's colored/dark contexts.
    svg_text = svg_bytes.decode("utf-8")
    match_start = svg_text.index("viewBox=")
    tag_end = svg_text.index(">", match_start)
    view_box = svg_text[match_start:tag_end].split('"')[1]
    _, _, w, h = view_box.split()
    bg_rect = f'<rect width="{w}" height="{h}" fill="#ffffff"/>'
    svg_text = svg_text[: tag_end + 1] + bg_rect + svg_text[tag_end + 1 :]
    b64 = base64.b64encode(svg_text.encode("utf-8")).decode("ascii")
    return f"data:image/svg+xml;base64,{b64}"


# --------------------------------------------------------------------------
# HTML page per business
# --------------------------------------------------------------------------

PAGE_TEMPLATE = """
<section class="sheet" style="--accent: {brand_color};">
  <header class="title-bar">
    <span class="icon-badge">{icon_emoji}</span>
    <div class="title-text">
      <h1>{name}</h1>
      <p>Express Mode test business &mdash; {stamps_required} stamps to complete a card</p>
    </div>
  </header>

  <div class="group add-card-group">
    <div class="qr-block large">
      <img src="{add_card_qr}" alt="Add Card QR for {name}">
      <p class="qr-label">Add Card</p>
    </div>
  </div>

  <div class="group stamps-group">
    <p class="group-label">Add Stamps</p>
    <div class="stamp-row">
      <div class="qr-block">
        <img src="{stamp1_qr}" alt="Add 1 stamp QR for {name}">
        <p class="qr-label">+1 Stamp</p>
      </div>
      <div class="qr-block">
        <img src="{stamp2_qr}" alt="Add 2 stamps QR for {name}">
        <p class="qr-label">+2 Stamps</p>
      </div>
      <div class="qr-block">
        <img src="{stamp3_qr}" alt="Add 3 stamps QR for {name}">
        <p class="qr-label">+3 Stamps</p>
      </div>
    </div>
  </div>

  <div class="group backup-group">
    <div class="qr-block small">
      <img src="{backup_qr}" alt="Business backup QR for {name}">
      <p class="qr-label">Business Backup <span>(restores this test business in the Supplier app - not part of the wallet test flow)</span></p>
    </div>
  </div>

  <footer class="sheet-footer">LoyaltyCards Android Play-testing pack &mdash; {name} &mdash; businessId {business_id}</footer>
</section>
"""

DOCUMENT_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>LoyaltyCards Express Test Pack</title>
<style>
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; font: 14px/1.4 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #1a1a1a; }}
  .sheet {{
    width: 210mm; height: 297mm; padding: 14mm 16mm; page-break-after: always;
    display: flex; flex-direction: column;
  }}
  .sheet:last-child {{ page-break-after: auto; }}
  .title-bar {{ display: flex; align-items: center; gap: 8mm; border-bottom: 3px solid var(--accent); padding-bottom: 6mm; margin-bottom: 10mm; }}
  .icon-badge {{
    width: 20mm; height: 20mm; border-radius: 5mm; background: var(--accent);
    display: flex; align-items: center; justify-content: center; font-size: 11mm; flex: 0 0 auto;
  }}
  .title-text h1 {{ font-size: 22pt; margin: 0 0 2mm; }}
  .title-text p {{ margin: 0; color: #555; font-size: 11pt; }}

  .group {{ margin-bottom: 10mm; }}
  .group-label {{ font-size: 12pt; font-weight: 700; margin: 0 0 4mm; color: #333; }}

  .add-card-group {{ display: flex; justify-content: center; margin-top: 4mm; }}
  .stamp-row {{ display: flex; justify-content: center; gap: 14mm; }}
  .backup-group {{ margin-top: auto; display: flex; justify-content: center; border-top: 1px dashed #ccc; padding-top: 8mm; }}

  /* flex column + align-items:center, not text-align:center - text-align
     only centers inline content, and it silently fails to center these
     fixed-width *block* images once their shrink-wrapped container ends up
     wider than the image itself (e.g. the backup QR's wrapping label text),
     leaving the QR looking left-shifted relative to the label under it. */
  .qr-block {{ display: flex; flex-direction: column; align-items: center; }}
  .qr-block img {{ display: block; background: #fff; padding: 3mm; border: 1px solid #ddd; border-radius: 3mm; }}
  .qr-block.large img {{ width: 65mm; height: 65mm; }}
  .qr-block:not(.large):not(.small) img {{ width: 42mm; height: 42mm; }}
  .qr-block.small img {{ width: 32mm; height: 32mm; }}
  .qr-label {{ margin: 3mm 0 0; font-size: 12pt; font-weight: 600; }}
  .qr-label span {{ display: block; font-weight: 400; font-size: 8pt; color: #777; max-width: 55mm; margin: 1mm auto 0; }}

  .sheet-footer {{ text-align: center; color: #999; font-size: 7pt; margin-top: 6mm; }}

  @media print {{ @page {{ size: A4 portrait; margin: 0; }} }}
</style>
</head>
<body>
{pages}
</body>
</html>
"""


def render_business_page(business: dict, cooldown_seconds: int) -> str:
    now_ms = int(time.time() * 1000)
    import datetime

    now_dt = datetime.datetime.now()

    card_token = build_card_issue_token(business, now_ms)
    stamp1 = build_stamp_token(business, 1, cooldown_seconds, now_ms)
    stamp2 = build_stamp_token(business, 2, cooldown_seconds, now_ms)
    stamp3 = build_stamp_token(business, 3, cooldown_seconds, now_ms)
    backup = build_supplier_backup(business, now_dt)

    business["_generated_tokens"] = {
        "card_issue": card_token,
        "stamp_1": stamp1,
        "stamp_2": stamp2,
        "stamp_3": stamp3,
        "backup": backup,
    }

    return PAGE_TEMPLATE.format(
        brand_color=business["brandColor"],
        icon_emoji=ICON_EMOJI.get(business["logoIndex"], "\U0001F3EA"),
        name=business["name"],
        stamps_required=business["stampsRequired"],
        add_card_qr=qr_data_uri(card_token),
        stamp1_qr=qr_data_uri(stamp1),
        stamp2_qr=qr_data_uri(stamp2),
        stamp3_qr=qr_data_uri(stamp3),
        backup_qr=qr_data_uri(backup),
        business_id=business["businessId"],
    )


# --------------------------------------------------------------------------
# PDF rendering via headless Chrome (same technique used elsewhere in this
# repo's marketing-asset tooling this session)
# --------------------------------------------------------------------------


def render_pdf(html_path: Path, pdf_path: Path) -> None:
    subprocess.run(
        [
            CHROME_PATH,
            "--headless",
            "--disable-gpu",
            f"--print-to-pdf={pdf_path}",
            "--no-pdf-header-footer",
            "--print-to-pdf-no-header",
            f"file://{html_path}",
        ],
        check=True,
        capture_output=True,
    )


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------


def main():
    print(f"Loading seed file: {SEED_PATH}")
    seed = load_seed(SEED_PATH)
    cooldown_seconds = seed.get("cooldownSeconds", 10)

    print("Checking for businesses needing a new key pair...")
    ensure_keys(seed, SEED_PATH)

    OUTPUT_DIR.mkdir(exist_ok=True)

    pages = []
    generated_businesses = []
    for business_spec in seed["businesses"]:
        business = dict(business_spec)
        keys = business["keys"]
        business["businessId"] = keys["businessId"]
        business["_private_key_str"] = keys["privateKey"]
        business["_public_key_str"] = keys["publicKey"]
        private_key_obj, _ = load_keypair_from_seed(business)
        business["_private_key_obj"] = private_key_obj

        print(f"Generating assets for '{business['name']}' ({business['businessId']})...")
        pages.append(render_business_page(business, cooldown_seconds))
        generated_businesses.append(business)

    html = DOCUMENT_TEMPLATE.format(pages="\n".join(pages))
    html_path = OUTPUT_DIR / "express_test_pack.html"
    html_path.write_text(html, encoding="utf-8")
    print(f"Wrote {html_path}")

    pdf_path = OUTPUT_DIR / "express_test_pack.pdf"
    print(f"Rendering PDF via {CHROME_PATH} ...")
    render_pdf(html_path, pdf_path)
    print(f"Wrote {pdf_path}")

    # Dump the raw generated token JSON too, for the verification script and
    # for anyone who wants to inspect exactly what's inside each QR without
    # decoding the printed image.
    tokens_dump = {
        b["name"]: {
            "businessId": b["businessId"],
            **b["_generated_tokens"],
        }
        for b in generated_businesses
    }
    tokens_path = OUTPUT_DIR / "generated_tokens.json"
    with open(tokens_path, "w", encoding="utf-8") as f:
        json.dump(tokens_dump, f, indent=2)
    print(f"Wrote {tokens_path}")

    print(f"\nDone - {len(generated_businesses)} businesses.")


if __name__ == "__main__":
    sys.exit(main())
