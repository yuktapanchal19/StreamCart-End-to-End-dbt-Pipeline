{% docs streamcart_pipeline %}

# StreamCart dbt Pipeline

The StreamCart dbt project transforms raw e-commerce JSON data into
clean staging models, reusable intermediate transformations, and
business-ready KPI mart models.

## Layers

Staging → Intermediate → Marts

## Staging

Cleans and standardizes raw StreamCart order and product data.

## Intermediate

Enriches order data with product information and creates
customer-level aggregations.

## Marts

Provides business-ready customer, order, revenue, product,
and channel performance models.

## Owner

Data Engineering

{% enddocs %}