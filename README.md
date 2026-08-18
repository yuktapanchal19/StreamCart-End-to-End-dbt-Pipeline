# StreamCart — End-to-End dbt Pipeline

## Project Overview

StreamCart is an end-to-end dbt Core data transformation project for an
omni-channel retail platform.

The project transforms raw JSON order and product data into cleaned staging
models, reusable intermediate models, and business-ready KPI marts.

### Pipeline Architecture

```text
Raw Sources
    ↓
Staging
    ↓
Intermediate
    ↓
Marts