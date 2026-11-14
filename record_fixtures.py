#!/usr/bin/env python3
"""Record the shared fixture corpus for the BasedAgents mobile SDK task.

Captures real responses from the public, read-only API, politely paced
(>=1.5s between requests, unauthenticated GETs only). Each response body is
saved verbatim as <name>.json next to a manifest.json describing every
capture (url, status, content type, size, sha256, timestamp). Both the
Kotlin and Swift test suites parse THESE EXACT BYTES offline.
"""
import hashlib, json, time
from datetime import datetime, timezone
import requests

BASE = "https://api.basedagents.ai"
JARVIS = "ag_5Mr7gZFJhQRy7nESV86U7zduaoeUh7ss7SLKvH46KUZD"
BOT = "ag_5uX5iK1Df5nbioZmRWAZh7FsUTXrhmc4D3SCoBXh1Syd"
SDK_TASK = "task_zFihEF6ij4a3tUP0ENWo1"
OBS_TASK = "task_LHJPMel3PnqH4aqCwza2c"
OUT = "/home/hatch/workspace/basedagents/sdk/shared-fixtures"
PACE_S = 1.5

FIXTURES = [
    ("status", f"{BASE}/v1/status"),
    ("health", f"{BASE}/v1/health"),
    ("tasks_open", f"{BASE}/v1/tasks?status=open&limit=20"),
    ("tasks_open_page", f"{BASE}/v1/tasks?status=open&limit=5&offset=5"),
    ("tasks_category_code", f"{BASE}/v1/tasks?category=code&limit=10"),
    ("task_detail_sdk", f"{BASE}/v1/tasks/{SDK_TASK}"),
    ("task_detail_observatory", f"{BASE}/v1/tasks/{OBS_TASK}"),
    ("task_receipts_sdk", f"{BASE}/v1/tasks/{SDK_TASK}/receipts"),
    ("task_receipt_sdk", f"{BASE}/v1/tasks/{SDK_TASK}/receipt"),
    ("task_submission_sdk", f"{BASE}/v1/tasks/{SDK_TASK}/submission"),
    ("task_payment_sdk", f"{BASE}/v1/tasks/{SDK_TASK}/payment"),
    ("tasks_settled", f"{BASE}/v1/tasks/settled?limit=10"),
    ("agent_jarvis", f"{BASE}/v1/agents/{JARVIS}"),
    ("agent_bot", f"{BASE}/v1/agents/{BOT}"),
    ("agent_reputation_jarvis", f"{BASE}/v1/agents/{JARVIS}/reputation"),
    ("agent_wallet_jarvis", f"{BASE}/v1/agents/{JARVIS}/wallet"),
    ("agents_search_jarvis", f"{BASE}/v1/agents/search?q=Jarvis"),
    ("chain_latest", f"{BASE}/v1/chain/latest"),
    ("error_task_not_found", f"{BASE}/v1/tasks/task_0000000000000000000000"),
    ("service_descriptor", "https://basedagents.ai/.well-known/basedagents.json"),
]

def record(name, url, manifest):
    r = requests.get(url, timeout=30, headers={"User-Agent": "basedagents-sdk-fixture-recorder/1.0 (polite, one-time)", "Accept": "application/json"})
    body = r.content
    fn = f"{name}.json"
    open(f"{OUT}/{fn}", "wb").write(body)
    manifest.append({"name": name, "file": fn, "url": url, "status": r.status_code,
                     "content_type": r.headers.get("content-type"), "bytes": len(body),
                     "sha256": hashlib.sha256(body).hexdigest(),
                     "recorded_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")})
    print(f"{name}: HTTP {r.status_code}, {len(body)}B")
    return r

def main():
    manifest = []
    settled_first_id = None
    for name, url in FIXTURES:
        r = record(name, url, manifest)
        if name == "tasks_settled":
            try:
                data = r.json()
                items = data if isinstance(data, list) else data.get("tasks", [])
                if items: settled_first_id = items[0].get("id") or items[0].get("task_id")
            except Exception as e:
                print("settled parse note:", e)
        time.sleep(PACE_S)
    if settled_first_id:
        record("task_detail_settled", f"{BASE}/v1/tasks/{settled_first_id}", manifest)
        time.sleep(PACE_S)
        record("task_payment_settled", f"{BASE}/v1/tasks/{settled_first_id}/payment", manifest)
    json.dump({"recorded_from": BASE, "note": "Real captured responses from the public read-only API; test suites run offline against these exact bytes.",
               "fixtures": manifest}, open(f"{OUT}/manifest.json", "w"), indent=2)
    print("manifest entries:", len(manifest))

if __name__ == "__main__":
    main()
