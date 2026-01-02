# ecommerce-database-normalization-sql

# E-commerce Relational Database Implementation

A comprehensive SQL-based data engineering project focused on building a fully normalized relational database from raw E-commerce datasets. This project transforms unstructured transactional data into a high-integrity, queryable system optimized for business intelligence and analytics.

## 🚀 Project Overview
This project addresses the challenge of converting raw CSV data (inspired by the Olist Brazilian E-commerce dataset) into a professional-grade relational schema. It involves complex data cleaning, handling many-to-many relationships, and enforcing strict business logic via SQL constraints.

###
**SQL-based data engineering project focused on building a normalized relational database for E-commerce analytics. Features include schema design with complex foreign key constraints, data deduplication using window functions, and referential integrity management. Ideal for transforming raw CSV exports into a queryable, high-integrity database.**

* **Normalization & Schema Design:** Decomposed flat data into 9+ distinct entities (Customers, Orders, Products, Sellers, etc.) to achieve 3rd Normal Form (3NF).
* **Data Deduplication:** Implemented advanced cleaning scripts using **Window Functions** (`ROW_NUMBER()`) and PostgreSQL-specific **CTID** filtering to remove redundant geolocation and review records.
* **Referential Integrity:** * Applied `PRIMARY KEY` and `FOREIGN KEY` constraints post-cleaning.
    * Utilized `ON DELETE CASCADE` and `ON UPDATE CASCADE` for automated data synchronization.
* **Integrity Checks:** Added `CHECK` constraints to ensure data validity (e.g., restricting `review_score` to a 1–5 range).
* **Orphan Management:** Scripted logic to identify and remove "orphan records" (e.g., order items referencing missing products) before finalizing the schema.
