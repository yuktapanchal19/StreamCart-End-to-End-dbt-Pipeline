# StreamCart — End-to-End dbt Pipeline

An end-to-end **Data Engineering project built with dbt Core and Snowflake** to transform nested JSON e-commerce data into clean, tested, and analytics-ready datasets.

## 🚀 Project Overview

StreamCart is an omni-channel retail platform where customer orders and product data are stored as nested JSON in the raw layer.

This project demonstrates how **dbt Core** can be used to build a structured data transformation pipeline from raw data to business-ready analytics models.

### Data Flow

```text
Raw JSON Data
     ↓
Staging
     ↓
Intermediate
     ↓
Mart / KPI Models
     ↓
Analytics-Ready Data
```

## 🛠️ Tech Stack

* **dbt Core**
* **Snowflake**
* **SQL**
* **Jinja**
* **Python**
* **dbt-utils**
* **dbt-expectations**
* **Git & GitHub**

## ✨ Key Features

* Nested JSON extraction and array flattening
* Data cleaning and deduplication
* Jinja templating and custom macros
* Intermediate and KPI mart models
* Incremental models for performance optimization
* Seeds for reference data
* Snapshots with **SCD Type 2** history
* Generic, singular, and package-based data quality tests
* Source freshness checks
* dbt documentation and lineage
* Hooks and audit logging

The project works with `raw_orders` and `raw_products` source tables containing nested JSON data.

## 📂 Project Structure

```text
StreamCart/
│
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
│
├── macros/
├── seeds/
├── snapshots/
├── tests/
├── dbt_project.yml
├── packages.yml
└── README.md
```

## ▶️ Getting Started

Install the required dbt packages:

```bash
dbt deps
```

Load seed data:

```bash
dbt seed
```

Run the models:

```bash
dbt run
```

Run data quality tests:

```bash
dbt test
```

Run snapshots:

```bash
dbt snapshot
```

Build the complete project:

```bash
dbt build
```

Generate documentation:

```bash
dbt docs generate
dbt docs serve
```

> **Note:** Do not commit `profiles.yml`, credentials, API keys, or other sensitive configuration files.

## 👩‍💻 Author

**Yukta Panchal**

*Data Engineering | SQL | Python | Snowflake | dbt*
