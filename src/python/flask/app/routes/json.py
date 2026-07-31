from datetime import datetime, timezone

from flask import Blueprint, jsonify, request

bp = Blueprint('json', __name__)

# Canonical /json payload. See contracts/rest/canonical-payloads.md.
#
# The previous implementation generated two uuid.uuid4() values per item --
# 2000 random UUIDs per request -- which is work no other implementation did.
# That, not Flask, is what produced its 47 req/s on this scenario.
DEFAULT_ITEMS = 1000
MAX_ITEMS = 10000
CANONICAL_CREATED_AT = '2026-01-01T00:00:00Z'


def canonical_item(i: int) -> dict:
    """Item content is a pure function of the index: no randomness, no clock."""
    return {
        'id': i,
        'uuid': f'00000000-0000-0000-0000-{i:012d}',
        'name': f'Item {i}',
        'email': f'item{i}@benchmark.local',
        'createdAt': CANONICAL_CREATED_AT,
        'isActive': i % 2 == 0,
    }


def item_count() -> int:
    """
    Parse ?n=. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
    serialization ranking is taken at n=100.
    """
    raw = request.args.get('n')
    if raw is None:
        return DEFAULT_ITEMS
    try:
        n = int(raw)
    except (TypeError, ValueError):
        return DEFAULT_ITEMS
    if n < 0:
        return DEFAULT_ITEMS
    return min(n, MAX_ITEMS)


@bp.route('/json')
def json_endpoint():
    """JSON serialization endpoint - returns n canonical objects."""
    n = item_count()
    # The envelope timestamp is the only clock-dependent field and is excluded
    # from the parity hash.
    return jsonify({
        'items': [canonical_item(i) for i in range(n)],
        'count': n,
        'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    })
