"""Build ecommerce.db (SQLite) from the Olist CSVs.

Usage:
    python src/build_db.py            # uses data/raw/*.csv if present
    python src/build_db.py --download # downloads the CSVs first

The CSVs are NOT committed to the repo (see .gitignore): they are
~60 MB raw. They come from the official Olist mirror on GitHub
(olist/work-at-olist-data, datasets/), which mirrors the Kaggle
dataset "Brazilian E-Commerce Public Dataset by Olist"
(olistbr/brazilian-ecommerce, CC BY-NC-SA 4.0).

The built ecommerce.db is also NOT committed (it is ~30 MB).
Re-run this script to rebuild it from scratch.
"""
import argparse
import sqlite3
import sys
import urllib.request
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
DB = ROOT / "ecommerce.db"
SCHEMA = ROOT / "schema.sql"

BASE_URL = ("https://raw.githubusercontent.com/olist/work-at-olist-data"
            "/master/datasets/{name}.csv")

FILES = {
    "customers": "olist_customers_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}


def download():
    RAW.mkdir(parents=True, exist_ok=True)
    for table, fname in FILES.items():
        dest = RAW / fname
        if dest.exists() and dest.stat().st_size > 0:
            print(f"exists: {fname}")
            continue
        url = BASE_URL.format(name=fname[:-4])
        print(f"downloading {url} ...")
        urllib.request.urlretrieve(url, dest)
        print(f"  -> {dest} ({dest.stat().st_size / 1e6:.1f} MB)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--download", action="store_true")
    args = ap.parse_args()
    if args.download:
        download()

    missing = [f for f in FILES.values() if not (RAW / f).exists()]
    if missing:
        print("Missing CSVs:", missing)
        print("Run: python src/build_db.py --download")
        sys.exit(1)

    if DB.exists():
        DB.unlink()
    con = sqlite3.connect(DB)
    con.executescript(SCHEMA.read_text(encoding="utf-8"))

    counts = {}
    for table, fname in FILES.items():
        df = pd.read_csv(RAW / fname, low_memory=False)
        # The translation file ships with a UTF-8 BOM.
        df.columns = [c.lstrip("\ufeff") for c in df.columns]
        df.to_sql(table, con, if_exists="append", index=False)
        counts[table] = len(df)
        print(f"{table}: {len(df):,} rows")

    con.commit()
    # Quick integrity check: delivered orders must have payments.
    cur = con.execute(
        "SELECT COUNT(*) FROM orders WHERE order_status = 'delivered'")
    print(f"delivered orders: {cur.fetchone()[0]:,}")
    con.execute("PRAGMA integrity_check").fetchone()
    con.close()
    print(f"Built {DB} ({DB.stat().st_size / 1e6:.1f} MB)")
    print("Row counts:", counts)


if __name__ == "__main__":
    main()
