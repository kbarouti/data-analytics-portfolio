# 💰 Customer & Revenue Analytics

## Business Problem

Understanding customer behavior and revenue distribution is critical for any business. This project performs **RFM segmentation** (Recency, Frequency, Monetary) and **Pareto analysis** on 100K+ e-commerce transactions to identify high-value customers, at-risk segments, and revenue concentration patterns.

**Target industry:** E-commerce, Retail, Finance, Big Tech (Amazon, L'Oréal)

---

## Dataset

**Brazilian E-Commerce by Olist** — [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

- **100K+ orders** from 2016–2018
- **8 relational tables:** orders, order_items, payments, customers, products, sellers, reviews, geolocation
- Multi-table JOIN analysis demonstrates relational database proficiency

---

## Key Findings

- **Top 20% of customers** generate approximately 65% of total revenue (Pareto principle confirmed)
- RFM segmentation reveals **5 distinct customer clusters**: Champions, Loyal, New, At Risk, Lost
- **"At Risk" segment** represents X% of customers — high-value customers showing declining engagement
- Product categories `bed_bath_table` and `health_beauty` drive the highest revenue
- Average customer review score: 4.1/5 — but drops to 3.2 for late deliveries

---

## Tech Stack

| Tool | Usage |
|------|-------|
| **SQL (SQLite)** | RFM with NTILE(), Pareto with cumulative Window Functions, multi-table JOINs |
| **Python** | pandas, plotly, seaborn for segmentation visualization |
| **Jupyter Notebook** | Interactive analysis |

---

## SQL Highlights

- **NTILE() Window Function** for RFM scoring (quintile segmentation)
- **Cumulative SUM() OVER()** for Pareto curve calculation
- **Multi-table JOINs** across 5+ tables
- **Cohort analysis** with date extraction and retention calculation
- **CASE WHEN** for customer segment labeling

---

## Project Structure

```
customer-revenue-analytics/
├── README.md
├── data/
│   └── olist.db                    ← SQLite database (8 tables)
├── sql/
│   └── customer_analysis.sql       ← RFM, Pareto, Cohort, Revenue queries
├── notebooks/
│   ├── 01_rfm_analysis.ipynb       ← RFM segmentation
│   └── 02_revenue_insights.ipynb   ← Pareto & business insights
└── visuals/
    ├── rfm_segments.png
    ├── pareto_curve.png
    ├── revenue_by_category.png
    └── rfm_heatmap.png
```

---

## How to Run

```bash
pip install pandas seaborn plotly jupyter
jupyter notebook notebooks/01_rfm_analysis.ipynb
```

---

## Author

**Kawtar Barouti** — Data Analyst / Analytics Engineer  
[Back to Portfolio](../README.md)
