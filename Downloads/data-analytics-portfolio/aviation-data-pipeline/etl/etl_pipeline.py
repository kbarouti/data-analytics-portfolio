"""
============================================================================
Aviation Flight Delay — ETL Pipeline
============================================================================
Author:  Kawtar Barouti
Purpose: Extract, Transform, Load flight delay data into a normalized
         SQLite database for analytics and dashboard visualization.

Architecture:
    CSV (raw data) → Python ETL → SQLite (star schema)

Usage:
    python etl_pipeline.py

    Optional arguments:
    --input  : path to input CSV (default: ../data/flights.csv)
    --output : path to output SQLite DB (default: ../data/aviation.db)
============================================================================
"""

import pandas as pd
import sqlite3
import logging
import argparse
import sys
import os
from datetime import datetime

# ---- CONFIGURATION ----
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)-8s | %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger('ETL_Pipeline')


# ============================================================================
# EXTRACT
# ============================================================================
def extract(filepath: str) -> pd.DataFrame:
    """
    Extract raw data from CSV file.
    Handles encoding issues and provides basic validation.
    """
    logger.info(f'📥 EXTRACT — Reading from: {filepath}')

    if not os.path.exists(filepath):
        logger.error(f'File not found: {filepath}')
        sys.exit(1)

    try:
        df = pd.read_csv(filepath, low_memory=False)
        logger.info(f'   Extracted {len(df):,} rows × {len(df.columns)} columns')
        logger.info(f'   Memory usage: {df.memory_usage(deep=True).sum() / 1024**2:.1f} MB')
        logger.info(f'   Columns: {list(df.columns[:10])}...')
        return df

    except Exception as e:
        logger.error(f'Extraction failed: {e}')
        sys.exit(1)


# ============================================================================
# TRANSFORM
# ============================================================================
def transform(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean and transform raw flight data:
    - Remove duplicates
    - Parse dates and extract time features
    - Create delay categories
    - Normalize text fields
    - Handle missing values
    """
    logger.info(f'🔄 TRANSFORM — Processing {len(df):,} rows...')
    initial_rows = len(df)

    # --- Step 1: Remove duplicates ---
    df = df.drop_duplicates()
    removed = initial_rows - len(df)
    if removed > 0:
        logger.info(f'   Removed {removed:,} duplicate rows')

    # --- Step 2: Parse dates ---
    if 'FL_DATE' in df.columns:
        df['FL_DATE'] = pd.to_datetime(df['FL_DATE'], errors='coerce')
        logger.info(f'   Date range: {df["FL_DATE"].min()} → {df["FL_DATE"].max()}')

    # --- Step 3: Extract time features ---
    if 'FL_DATE' in df.columns and df['FL_DATE'].dtype == 'datetime64[ns]':
        df['year'] = df['FL_DATE'].dt.year
        df['month'] = df['FL_DATE'].dt.month
        df['day_of_week'] = df['FL_DATE'].dt.dayofweek  # 0=Monday
        df['day_name'] = df['FL_DATE'].dt.day_name()
        df['quarter'] = df['FL_DATE'].dt.quarter

    # --- Step 4: Create delay categories ---
    if 'ARR_DELAY' in df.columns:
        df['delay_category'] = pd.cut(
            df['ARR_DELAY'].fillna(0),
            bins=[-9999, -15, 0, 15, 60, 120, 99999],
            labels=['Early (>15min)', 'On Time', 'Minor (0-15)', 'Moderate (15-60)', 'Major (60-120)', 'Severe (120+)']
        )

        # Binary delay flag (>15 min)
        df['is_delayed'] = (df['ARR_DELAY'] > 15).astype(int)

    # --- Step 5: Normalize text fields ---
    text_cols = ['AIRLINE', 'ORIGIN', 'DEST']
    for col in text_cols:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip().str.upper()

    # --- Step 6: Create route column ---
    if 'ORIGIN' in df.columns and 'DEST' in df.columns:
        df['route'] = df['ORIGIN'] + ' → ' + df['DEST']

    # --- Step 7: Handle missing values summary ---
    null_pct = (df.isnull().sum() / len(df) * 100).round(1)
    high_nulls = null_pct[null_pct > 5]
    if len(high_nulls) > 0:
        logger.info(f'   Columns with >5% nulls: {dict(high_nulls)}')

    logger.info(f'   Transform complete: {len(df):,} rows, {len(df.columns)} columns')
    return df


# ============================================================================
# LOAD
# ============================================================================
def load(df: pd.DataFrame, db_path: str) -> None:
    """
    Load transformed data into SQLite database with star schema:
    - fact_flights (main fact table)
    - dim_airlines (airline dimension)
    - dim_airports (airport dimension)
    """
    logger.info(f'📤 LOAD — Writing to: {db_path}')

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # --- Fact table ---
        df.to_sql('fact_flights', conn, if_exists='replace', index=False)
        logger.info(f'   ✓ fact_flights: {len(df):,} rows')

        # --- Dimension: Airlines ---
        if 'AIRLINE' in df.columns:
            airlines = df[['AIRLINE']].drop_duplicates().reset_index(drop=True)
            airlines['airline_id'] = airlines.index + 1
            airlines.to_sql('dim_airlines', conn, if_exists='replace', index=False)
            logger.info(f'   ✓ dim_airlines: {len(airlines)} airlines')

        # --- Dimension: Airports ---
        if 'ORIGIN' in df.columns and 'DEST' in df.columns:
            origins = df[['ORIGIN']].rename(columns={'ORIGIN': 'airport_code'})
            dests = df[['DEST']].rename(columns={'DEST': 'airport_code'})
            airports = pd.concat([origins, dests]).drop_duplicates().reset_index(drop=True)
            airports['airport_id'] = airports.index + 1
            airports.to_sql('dim_airports', conn, if_exists='replace', index=False)
            logger.info(f'   ✓ dim_airports: {len(airports)} airports')

        # --- Create indexes for query performance ---
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_flights_airline ON fact_flights(AIRLINE)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_flights_origin ON fact_flights(ORIGIN)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_flights_dest ON fact_flights(DEST)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_flights_date ON fact_flights(FL_DATE)')
        logger.info('   ✓ Indexes created')

        conn.commit()
        conn.close()
        logger.info(f'   Load complete! Database size: {os.path.getsize(db_path) / 1024**2:.1f} MB')

    except Exception as e:
        logger.error(f'Load failed: {e}')
        sys.exit(1)


# ============================================================================
# VALIDATE
# ============================================================================
def validate(db_path: str) -> None:
    """Run validation queries to ensure data integrity."""
    logger.info('✅ VALIDATE — Running integrity checks...')

    conn = sqlite3.connect(db_path)

    checks = {
        'Total flights': 'SELECT COUNT(*) FROM fact_flights',
        'Total airlines': 'SELECT COUNT(*) FROM dim_airlines',
        'Total airports': 'SELECT COUNT(*) FROM dim_airports',
        'Date range': "SELECT MIN(FL_DATE) || ' → ' || MAX(FL_DATE) FROM fact_flights",
        'Null delay pct': "SELECT ROUND(100.0 * SUM(CASE WHEN ARR_DELAY IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) FROM fact_flights",
    }

    for label, query in checks.items():
        try:
            result = pd.read_sql(query, conn).iloc[0, 0]
            logger.info(f'   {label}: {result}')
        except Exception as e:
            logger.warning(f'   {label}: FAILED — {e}')

    conn.close()
    logger.info('   Validation complete!')


# ============================================================================
# MAIN
# ============================================================================
def main():
    parser = argparse.ArgumentParser(description='Aviation Flight Delay ETL Pipeline')
    parser.add_argument('--input', default='../data/flights.csv', help='Input CSV path')
    parser.add_argument('--output', default='../data/aviation.db', help='Output SQLite DB path')
    args = parser.parse_args()

    logger.info('=' * 60)
    logger.info('   AVIATION FLIGHT DELAY — ETL PIPELINE')
    logger.info(f'   Started at {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    logger.info('=' * 60)

    start = datetime.now()

    # Run pipeline
    raw_data = extract(args.input)
    clean_data = transform(raw_data)
    load(clean_data, args.output)
    validate(args.output)

    elapsed = (datetime.now() - start).total_seconds()
    logger.info(f'\n🎉 Pipeline complete in {elapsed:.1f} seconds')
    logger.info(f'   Output: {args.output}')


if __name__ == '__main__':
    main()
