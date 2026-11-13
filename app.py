"""Streamlit dashboard: SQL business analytics for Brazilian Olist e-commerce.

Run:
    python src/build_db.py      # once, builds ecommerce.db from the CSVs
    python src/run_queries.py   # once, writes results/ + results.json
    streamlit run app.py

The dashboard runs the SQL in sql/ live against ecommerce.db
(SQLite) and shows the KPIs, charts and the SQL behind each chart.
If the database is missing, it shows the setup steps instead.
"""
import sqlite3
from pathlib import Path

import pandas as pd
import streamlit as st

ROOT = Path(__file__).resolve().parent
DB = ROOT / "ecommerce.db"
SQL_DIR = ROOT / "sql"

st.set_page_config(page_title="Olist E-commerce Analytics", layout="wide")
st.title("Brazilian E-commerce Analytics — Olist")
st.write(
    "SQL business analytics on the Olist marketplace (2016–2018): "
    "99,441 orders, 96,478 delivered, R$ 15.4M revenue. "
    "Every chart below is produced by a SQL query in `sql/`."
)


@st.cache_resource
def get_connection():
    return sqlite3.connect(DB, check_same_thread=False)


def run_query(name):
    sql = (SQL_DIR / f"{name}.sql").read_text(encoding="utf-8")
    return pd.read_sql_query(sql, get_connection()), sql


if not DB.exists():
    st.warning(
        "ecommerce.db not found. Build it first:\n\n"
        "```\npython src/build_db.py --download\n"
        "python src/run_queries.py\n```\n\n"
        "The raw CSVs (~60 MB) and the database are not committed to "
        "the repo; see README.md for the data source."
    )
    st.stop()

con = get_connection()
total_revenue = con.execute(
    "SELECT ROUND(SUM(p.payment_value), 2) FROM order_payments p "
    "JOIN orders o USING (order_id) WHERE o.order_status = 'delivered'"
).fetchone()[0]
aov = con.execute(
    "SELECT ROUND(AVG(p.payment_value), 2) FROM order_payments p "
    "JOIN orders o USING (order_id) WHERE o.order_status = 'delivered'"
).fetchone()[0]
avg_score = con.execute(
    "SELECT ROUND(AVG(review_score), 2) FROM order_reviews").fetchone()[0]
late = con.execute(
    "SELECT ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date "
    "> order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 1) "
    "FROM orders WHERE order_status = 'delivered' "
    "AND order_delivered_customer_date IS NOT NULL").fetchone()[0]

c1, c2, c3, c4 = st.columns(4)
c1.metric("Revenue (delivered)", f"R$ {total_revenue:,.0f}")
c2.metric("Avg order value", f"R$ {aov:,.2f}")
c3.metric("Avg review score", f"{avg_score} / 5")
c4.metric("Late deliveries", f"{late}%")

monthly, sql_monthly = run_query("01_monthly_revenue")
st.subheader("Monthly revenue")
st.line_chart(monthly.set_index("month")["revenue_brl"])
with st.expander("Show the SQL"):
    st.code(sql_monthly, language="sql")

cat, sql_cat = run_query("02_revenue_by_category")
st.subheader("Revenue by category (top 10)")
st.bar_chart(cat.head(10).set_index("category")["item_revenue_brl"])
with st.expander("Show the SQL"):
    st.code(sql_cat, language="sql")

col1, col2 = st.columns(2)
with col1:
    st.subheader("Payment methods")
    pay, _ = run_query("06_payment_methods")
    st.dataframe(pay, use_container_width=True)
with col2:
    st.subheader("Delivery performance by year")
    dlv, _ = run_query("07_delivery_performance")
    st.dataframe(dlv, use_container_width=True)

st.subheader("Repeat customers vs one-time customers")
rep, sql_rep = run_query("09_repeat_customers")
st.dataframe(rep, use_container_width=True)
with st.expander("Show the SQL"):
    st.code(sql_rep, language="sql")

st.subheader("RFM segments")
rfm, _ = run_query("10_rfm_segmentation")
st.dataframe(rfm, use_container_width=True)

st.subheader("Review score by category")
rev, _ = run_query("08_review_score_by_category")
st.bar_chart(rev.head(10).set_index("category")["avg_score"])

st.caption(
    "Source: Brazilian E-Commerce Public Dataset by Olist "
    "(Kaggle, CC BY-NC-SA 4.0). Educational analysis — not an "
    "official Olist report. See README.md for methods and limits."
)
