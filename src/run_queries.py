"""Run every query in sql/ against ecommerce.db and save the outputs.

Usage:
    python src/build_db.py      # first, once
    python src/run_queries.py   # then this

Writes:
    results/<query>.csv   one CSV per query (same stem as the .sql file)
    results.json          headline numbers used by the README
    plots/*.svg           three charts built from the query results

Re-running reproduces the same files (queries are deterministic).
"""
import json
import sqlite3
from pathlib import Path

import matplotlib
import pandas as pd

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "ecommerce.db"
SQL_DIR = ROOT / "sql"
RESULTS = ROOT / "results"
PLOTS = ROOT / "plots"


def run_all():
    if not DB.exists():
        raise SystemExit("ecommerce.db not found — run: python src/build_db.py")
    RESULTS.mkdir(exist_ok=True)
    PLOTS.mkdir(exist_ok=True)
    con = sqlite3.connect(DB)
    frames = {}
    for path in sorted(SQL_DIR.glob("*.sql")):
        sql = path.read_text(encoding="utf-8")
        df = pd.read_sql_query(sql, con)
        frames[path.stem] = df
        out = RESULTS / f"{path.stem}.csv"
        df.to_csv(out, index=False)
        print(f"{path.name}: {len(df)} rows -> {out.name}")
    con.close()
    return frames


def headline(frames):
    monthly = frames["01_monthly_revenue"]
    category = frames["02_revenue_by_category"]
    state = frames["03_revenue_by_state"]
    payments = frames["06_payment_methods"]
    delivery = frames["07_delivery_performance"]
    repeat = frames["09_repeat_customers"]
    con = sqlite3.connect(DB)
    q = lambda s: con.execute(s).fetchone()[0]
    total_revenue = float(monthly["revenue_brl"].sum())
    total_orders = int(monthly["orders"].sum())
    summary = {
        "dataset": {
            "name": "Brazilian E-Commerce Public Dataset by Olist",
            "source": "https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce",
            "license": "CC BY-NC-SA 4.0",
            "period": "2016-09-04 to 2018-10-17",
            "tables": {
                "customers": int(q("SELECT COUNT(*) FROM customers")),
                "orders": int(q("SELECT COUNT(*) FROM orders")),
                "order_items": int(q("SELECT COUNT(*) FROM order_items")),
                "order_payments": int(q("SELECT COUNT(*) FROM order_payments")),
                "order_reviews": int(q("SELECT COUNT(*) FROM order_reviews")),
                "products": int(q("SELECT COUNT(*) FROM products")),
            },
            "delivered_orders": int(
                q("SELECT COUNT(*) FROM orders WHERE order_status='delivered'")),
            "unique_customers": int(
                q("SELECT COUNT(DISTINCT customer_unique_id) FROM customers")),
        },
        "total_revenue_brl_delivered": round(total_revenue, 2),
        # 96,478 orders are marked delivered; 1 of them has no payment
        # record, so the revenue-backed order count is 96,477.
        "delivered_orders": int(
            q("SELECT COUNT(*) FROM orders WHERE order_status='delivered'")),
        "delivered_orders_with_payment_record": total_orders,
        "aov_brl_delivered": round(total_revenue / total_orders, 2),
        "avg_review_score": round(
            float(q("SELECT AVG(review_score) FROM order_reviews")), 3),
        "top_category": {
            "name": str(category.iloc[0]["category"]),
            "revenue_brl": round(float(category.iloc[0]["item_revenue_brl"]), 2),
            "share_pct": round(float(category.iloc[0]["revenue_share_pct"]), 2),
        },
        "top_state": {
            "name": str(state.iloc[0]["state"]),
            "revenue_brl": round(float(state.iloc[0]["revenue_brl"]), 2),
        },
        "top_payment_method": {
            "name": str(payments.iloc[0]["payment_type"]),
            "share_pct": round(float(payments.iloc[0]["revenue_share_pct"]), 2),
        },
        "delivery": {
            "avg_delivery_days": round(
                float(delivery["avg_delivery_days"].mean()), 1),
            "avg_delay_days": round(
                float(delivery["avg_delay_days"].mean()), 1),
            "pct_late": round(float(delivery["pct_late"].mean()), 1),
        },
        "repeat_customers_pct": round(
            float(repeat.loc[repeat["order_bucket"] != "1 order",
                             "pct_customers"].sum()), 1),
        "best_month": {
            "month": str(monthly.loc[monthly["revenue_brl"].idxmax(), "month"]),
            "revenue_brl": round(float(monthly["revenue_brl"].max()), 2),
        },
    }
    con.close()
    (ROOT / "results.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print("results.json written")
    return summary


def charts(frames):
    plt.rcParams.update({"font.size": 10})
    monthly = frames["01_monthly_revenue"]
    fig, ax = plt.subplots(figsize=(9, 4))
    ax.plot(monthly["month"], monthly["revenue_brl"], marker="o", ms=3)
    ax.set_title("Monthly revenue (delivered orders, BRL)")
    ax.set_ylabel("Revenue (BRL)")
    ax.tick_params(axis="x", rotation=45)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(PLOTS / "monthly_revenue.svg")
    plt.close(fig)

    cat = frames["02_revenue_by_category"].head(10).iloc[::-1]
    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.barh(cat["category"], cat["item_revenue_brl"])
    ax.set_title("Top 10 categories by item revenue (BRL)")
    ax.set_xlabel("Item revenue (BRL)")
    fig.tight_layout()
    fig.savefig(PLOTS / "revenue_by_category.svg")
    plt.close(fig)

    rev = frames["08_review_score_by_category"].head(10).iloc[::-1]
    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.barh(rev["category"], rev["avg_score"])
    ax.set_title("Top 10 categories by average review score")
    ax.set_xlabel("Average review score (1-5)")
    ax.set_xlim(3.5, 5)
    fig.tight_layout()
    fig.savefig(PLOTS / "review_score_by_category.svg")
    plt.close(fig)
    print("plots written")


if __name__ == "__main__":
    frames = run_all()
    summary = headline(frames)
    charts(frames)
    print(json.dumps(summary, indent=2, ensure_ascii=False))
