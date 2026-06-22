#!/usr/bin/env python3
"""
Program to pull IP addresses from MW3 2023 Call of Duty server
This tool is designed for multiplayer matches and pulls home IP connected to the Call of Duty server
Author: Your Name
Date: 2025-09-19
"""

import sqlite3
import argparse
from datetime import datetime
from typing import List, Tuple

# ------------------------------------------------------------------
# Configuration (defaults, can be overridden via CLI)
# ------------------------------------------------------------------
DEFAULT_DATABASE_PATH = "mw3_2023.db"
DEFAULT_TABLE_NAME = "matches"
DEFAULT_SERVER_NAME = "call_of_duty"
HOME_IP_FIELD = "home_ip"

# ------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------
def init_db(db_path: str, table_name: str) -> None:
    """Create the database and table if they do not exist."""
    create_sql = f"""
    CREATE TABLE IF NOT EXISTS {table_name} (
        match_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server TEXT NOT NULL,
        match_time TIMESTAMP,
        home_ip TEXT,
        other_ips TEXT,
        status TEXT
    )
    """
    with sqlite3.connect(db_path) as conn:
        conn.execute(create_sql)
        conn.commit()
    print(f"Database {db_path} is ready (table: {table_name}).")

def fetch_matches(db_path: str, table_name: str, server_name: str) -> List[Tuple]:
    """Fetch matches for the given server, newest first."""
    query = f"""
    SELECT match_id, server, match_time, home_ip, other_ips, status
    FROM {table_name}
    WHERE server = ?
    ORDER BY match_time DESC
    """
    with sqlite3.connect(db_path) as conn:
        cursor = conn.execute(query, (server_name,))
        rows = cursor.fetchall()
    return rows

def format_row(row: Tuple) -> str:
    """Format a single DB row for printing/writing."""
    match_id, server, match_time, home_ip, other_ips, status = row
    time_str = (
        match_time if isinstance(match_time, str) else
        match_time.strftime("%Y-%m-%d %H:%M:%S") if match_time else ""
    )
    return f"{match_id:<10}|{server:<20}|{time_str:<25}|{home_ip or '':<20}|{other_ips or '':<30}|{status or '':<15}"

def write_results_to_file(filename: str, server_name: str, rows: List[Tuple]) -> None:
    """Write the fetched rows to a text file."""
    header = f"{'Match ID':<10}|{'Server':<20}|{'Time':<25}|{'Home IP':<20}|{'Other IPs':<30}|{'Status':<15}"
    sep = "-" * len(header)
    with open(filename, "w", encoding="utf-8") as f:
        f.write(f"Home IPs from {server_name} Server\n")
        f.write(f"Generated at: {datetime.now()}\n")
        f.write(header + "\n")
        f.write(sep + "\n")
        for row in rows:
            f.write(format_row(row) + "\n")

# ------------------------------------------------------------------
# Main program
# ------------------------------------------------------------------
def pull_home_ips(
    db_path: str = DEFAULT_DATABASE_PATH,
    table_name: str = DEFAULT_TABLE_NAME,
    server_name: str = DEFAULT_SERVER_NAME,
    out_file: str = "home_ips.txt",
) -> None:
    """Pull home IP addresses from the specified server and save/display them."""
    rows = fetch_matches(db_path, table_name, server_name)

    print(f"\n=== Home IPs from {server_name} Server ===")
    header = f"{'Match ID':<10}|{'Server':<20}|{'Time':<25}|{'Home IP':<20}|{'Other IPs':<30}|{'Status':<15}"
    print(header)
    print("-" * len(header))
    if not rows:
        print("No matches found.")
    else:
        for row in rows:
            print(format_row(row))

    write_results_to_file(out_file, server_name, rows)
    print(f"\nResults written to {out_file}")

# ------------------------------------------------------------------
# CLI entry point
# ------------------------------------------------------------------
def parse_args():
    p = argparse.ArgumentParser(description="Pull home IPs from MW3 matches DB")
    p.add_argument("--db", default=DEFAULT_DATABASE_PATH, help="Path to SQLite database")
    p.add_argument("--table", default=DEFAULT_TABLE_NAME, help="Table name")
    p.add_argument("--server", default=DEFAULT_SERVER_NAME, help="Server name to filter")
    p.add_argument("--out", default="home_ips.txt", help="Output text file")
    p.add_argument("--init-db", action="store_true", help="Create DB and table if missing")
    return p.parse_args()

if __name__ == "__main__":
    args = parse_args()
    if args.init_db:
        init_db(args.db, args.table)
    pull_home_ips(db_path=args.db, table_name=args.table, server_name=args.server, out_file=args.out)
