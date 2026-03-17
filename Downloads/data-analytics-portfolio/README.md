# 📦 Supply Chain Performance Analytics

## Business Problem

In industrial and logistics environments, late deliveries directly impact customer satisfaction, production schedules, and operational costs. This project analyzes **180,000+ supply chain orders** to identify the root causes of delivery delays and provide actionable recommendations for logistics optimization.

**Target industry:** Aerospace (Safran, Airbus), Industrial (Schneider Electric), Energy (Total)

---

## Dataset

**DataCo Smart Supply Chain** — [Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

- **180,519 orders** across multiple markets and regions
- Features: order date, shipping date, delivery status, shipping mode, customer segment, product category, sales amount, profit, region
- Late delivery risk flag for each order

---

## Key Findings

- **54.8% of all orders** (98,977 out of 180,519) face late delivery risk
- **First Class** shipping has the worst delay rate at **95.3%** — counter-intuitively the most expensive mode performs worst
- **Second Class** follows at **76.6%**, while Standard Class is lowest at **38.1%**
- Delay rates are **consistent across all customer segments** (Consumer, Corporate, Home Office) — the heatmap shows the problem is systemic to shipping mode, not customer type
- **Central America** and **Western Europe** are the most impacted regions by volume (~15K late deliveries each)
- **South Asia** has the highest delay rate at **56.3%**
- Monthly trend shows oscillation between 52–57% with no clear seasonal improvement
- Total revenue impacted: **$33M** across all orders

---

## Tech Stack

| Tool | Usage |
|------|-------|
| **Python** | Data exploration, cleaning, visualization (pandas, seaborn, matplotlib) |
| **SQL (SQLite)** | Advanced analytics: Window Functions, CTEs, aggregations |
| **Jupyter Notebook** | Interactive analysis and documentation |

---

## SQL Highlights

- **Window Functions:** `RANK() OVER()` for region delay ranking
- **CTEs:** Monthly time-series analysis of delay evolution
- **CASE WHEN:** Order size segmentation for volume/delay correlation
- **Multi-dimensional GROUP BY:** Shipping mode × customer segment cross-analysis

---

## Project Structure

```
supply-chain-analytics/
├── README.md
├── data/
│   └── supply_chain.db          ← SQLite database
├── sql/
│   └── supply_chain_analysis.sql ← 4+ commented queries
├── notebooks/
│   ├── 01_exploration.ipynb      ← EDA & cleaning
│   └── 02_visualizations.ipynb   ← Charts & insights
└── visuals/
    ├── late_rate_by_shipping.png
    ├── heatmap_mode_segment.png
    ├── monthly_trend.png
    └── top_regions.png
```

---

## Visualizations

![Late Rate by Shipping Mode](visuals/late_rate_by_shipping.png)

![Monthly Delay Trend](visuals/monthly_trend.png)

---

## How to Run

```bash
# Install dependencies
pip install pandas seaborn matplotlib jupyter

# Launch notebook
jupyter notebook notebooks/01_exploration.ipynb
```

---

## Author

**Kawtar Barouti** — Data Analyst / Analytics Engineer  
[Back to Portfolio](../README.md)
