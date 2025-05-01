#!/usr/bin/env python3
"""
generate_sample_logs.py
-----------------------
Quick‐n-dirty synthetic log generator for the Iceberg demo.

Usage
------
# create 500 lines in ./sample.log (default)
python generate_sample_logs.py  

# create 1 000 lines and write directly to /tmp/mylogs.log
python generate_sample_logs.py --count 1000 --out /tmp/mylogs.log
"""
import argparse, random, ipaddress, datetime as dt, pathlib

# ------------------------------------------------------------------ config ---
USER_AGENTS = [
    # desktop
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/123.0.6312.86 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_2) AppleWebKit/605.1.15 "
    "(KHTML, like Gecko) Version/17.0 Safari/605.1.15",
    # mobile
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/123.0.6312.86 Mobile Safari/537.36",
    # tablet
    "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
    "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
]

PATHS = [
    "/",
    "/index.html",
    "/login",
    "/logout",
    "/assets/logo.png",
    "/api/v1/purchase",
    "/dashboard",
    "/content/article-42",
]

STATUSES = [200, 200, 200, 301, 404, 500]  # weighted toward 200
SIZES    = [432, 1024, 2048, 4096, 8192, 16384]

# -------------------------------------------------------------- helpers ------
def random_ip() -> str:
    return str(ipaddress.IPv4Address(random.randint(0, 2**32 - 1)))

def random_timestamp(start: dt.datetime, end: dt.datetime) -> str:
    """Return [dd/MMM/yyyy:HH:mm:ss +0000] inside brackets."""
    delta = end - start
    ts = start + dt.timedelta(seconds=random.randint(0, int(delta.total_seconds())))
    return ts.strftime("%d/%b/%Y:%H:%M:%S +0000")

def make_line() -> str:
    ip = random_ip()
    ts = random_timestamp(START_TS, END_TS)
    path = random.choice(PATHS)
    ua  = random.choice(USER_AGENTS)
    status = random.choice(STATUSES)
    size   = random.choice(SIZES)
    return (
        f'{ip} - - [{ts}] "GET {path} HTTP/1.1" {status} {size} "-" "{ua}"'
    )

# ------------------------------------------------------------------ main -----
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--count", "-n", type=int, default=500,
                        help="Number of lines to generate (default 500)")
    parser.add_argument("--out", "-o", type=pathlib.Path, default=pathlib.Path("sample.log"),
                        help="Output file path (default ./sample.log)")
    args = parser.parse_args()

    START_TS = dt.datetime(2025, 4, 20, tzinfo=dt.timezone.utc)
    END_TS   = dt.datetime(2025, 4, 27, tzinfo=dt.timezone.utc)

    args.out.write_text("\n".join(make_line() for _ in range(args.count)) + "\n")
    print(f"✅ Wrote {args.count} lines to {args.out}")
