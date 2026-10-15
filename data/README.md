# Dataset Source: Brazilian E-Commerce Public Dataset by Olist

Due to file size best practices in Git repositories, the raw CSV files (~120 MB uncompressed) are not stored directly in this folder.

## 📥 Official Download Link
You can download the complete raw dataset directly from Kaggle:
* **[Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)**

## 📋 CSV-to-PostgreSQL Table Mapping
Once downloaded and extracted, run `sql/01_schema_setup.sql` to create the relational tables in PostgreSQL (`public` schema) and import each Kaggle CSV file into its corresponding table:

| Kaggle CSV File Name | PostgreSQL Table (`01_schema_setup.sql`) | Usage in Analytical Pipeline |
| :--- | :--- | :--- |
| `olist_orders_dataset.csv` | `public.orders` | Core order timestamps, status filtering (`delivered`), and SLA calculations |
| `olist_order_items_dataset.csv` | `public.order_items` | Central fact granularity (`Fact_Order_Items`), item prices, and freight |
| `olist_order_payments_dataset.csv` | `public.order_payments` | Total payment value (`monetary` calculation in `03_rfm_segmentation.sql`) |
| `olist_customers_dataset.csv` | `public.customers` | Customer unique identifiers and macro-region mapping (`Dim_Customers`) |
| `olist_products_dataset.csv` | `public.products` | Product dimensions and category lookup keys (`Dim_Products`) |
| `olist_sellers_dataset.csv` | `public.sellers` | Seller origin locations for cross-state route analysis (`Dim_Sellers`) |
| `product_category_name_translation.csv` | `public.product_category_name_translation` | Portuguese-to-English category translation (`02_data_cleaning.sql`) |
| `olist_order_reviews_dataset.csv` | `public.order_reviews` | Relational schema completeness and customer feedback constraints |
| `olist_geolocation_dataset.csv` | `public.geolocation` | Zip code coordinate reference log |