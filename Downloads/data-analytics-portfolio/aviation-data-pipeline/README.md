# ✈️ Aviation Data Pipeline — Flight Delay Analytics

## Business Problem

Flight delays cost the aviation industry billions annually and impact customer satisfaction, crew scheduling, and airport operations. This project builds a **complete ETL pipeline** from raw CSV data to an interactive dashboard, demonstrating end-to-end data engineering and analytics capabilities.

**Target industry:** Aerospace (Safran, Airbus, Air France), Aviation analytics

---

## Architecture

```
CSV Dataset (5M+ rows)
       │
       ▼
Python ETL Script (extract → transform → load)
       │
       ▼
SQLite Database (normalized: fact + dimensions)
       │
       ▼
SQL Analytics (advanced queries)
       │
       ▼
Interactive Dashboard (Plotly HTML / Power BI)
```

---

## Dataset

**Flight Delay & Cancellation 2019–2023** — [Kaggle](https://www.kaggle.com/datasets/patrickzel/flight-delay-and-cancellation-dataset-2019-2023)

- **5M+ flight records** across US airlines
- Features: airline, origin/destination, scheduled/actual times, delay causes, cancellations
- Period: 2019–2023 (includes COVID-19 impact)

---

## Key Findings

- **Summer months** (June–August) show ~28% higher delay rates than winter
- Top 3 most delayed airlines identified with specific route-level patterns
- **Weather** and **carrier delays** are the dominant causes across all airports
- COVID-19 period (2020) shows dramatic drop in flights but higher per-flight delay rates
- Top 20 most problematic routes identified with >1000 flights and highest avg delays

---

## Tech Stack

| Tool | Usage |
|------|-------|
| **Python** | ETL pipeline with logging, error handling, data transformation |
| **SQLite** | Normalized database (star schema: fact_flights + dim_airlines + dim_airports) |
| **SQL** | Advanced analytics: RANK(), CTEs, seasonal analysis |
| **Plotly / Power BI** | Interactive dashboard with KPIs, filters, charts |

---

## Project Structure

```
aviation-data-pipeline/
├── README.md
├── data/
│   └── aviation.db                ← SQLite database (star schema)
├── etl/
│   └── etl_pipeline.py            ← Complete ETL script
├── sql/
│   └── aviation_analysis.sql      ← 5+ analytical queries
├── dashboard/
│   └── dashboard.html             ← Plotly interactive dashboard
└── visuals/
    ├── delay_by_airline.png
    ├── seasonal_analysis.png
    ├── top_routes.png
    └── pipeline_architecture.png
```

---

## How to Run

```bash
# 1. Run ETL pipeline
cd etl
python etl_pipeline.py

# 2. Launch analysis notebook or dashboard
jupyter notebook notebooks/analysis.ipynb
# OR open dashboard/dashboard.html in browser
```

---

## Author

**Kawtar Barouti** — Data Analyst / Analytics Engineer  
[Back to Portfolio](../README.md)
