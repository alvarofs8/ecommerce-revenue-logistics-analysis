# DAX Measures Catalog & Calculation Logic

All business metrics in the semantic model are centralized in a dedicated calculation table (`_Measures`) and organized into logical **Display Folders** to ensure maintainability and self-service usability.

---

## 01. Financials

Metrics evaluating commercial scale, gross merchandise value (GMV), net product revenue, and order-level ticket size.

### `Total Revenue`

* **Format:** Currency (`R$ #,0.00`)
* **Description:** Total Gross Merchandise Value (GMV) billed across delivered orders, including both product price and shipping freight.

```dax
Total Revenue = 
SUM(Fact_Order_Items[total_item_value])
```

### `Product Sales`

* **Format:** Currency (`R$ #,0.00`)
* **Description:** Net revenue generated strictly from product prices, excluding freight charges.

```dax
Product Sales = 
SUM(Fact_Order_Items[item_price])
```

### `Freight Value`

* **Format:** Currency (`R$ #,0.00`)
* **Description:** Total shipping and carrier costs paid across all order items.

```dax
Freight Value = 
SUM(Fact_Order_Items[freight_value])
```

### `Total Orders`

* **Format:** Whole Number (`#,0`)
* **Description:** Distinct count of delivered orders. Because `Fact_Order_Items` operates at the order-item grain, `DISTINCTCOUNT` prevents multi-item orders from inflating order volume.

```dax
Total Orders = 
DISTINCTCOUNT(Fact_Order_Items[order_id])
```

### `Average Order Value`

* **Format:** Currency (`R$ #,0.00`)
* **Description:** Average revenue spent per unique order (AOV).

```dax
Average Order Value = 
DIVIDE(
    [Total Revenue], 
    [Total Orders], 
    0
)
```

---

## 02. Logistics

Order-grain fulfillment metrics. Because `Fact_Order_Items` is at the item grain while delivery timestamps exist at the order grain, these measures use DAX iterators (`AVERAGEX`, `MEDIANX`) over `VALUES(Fact_Order_Items[order_id])` to avoid weighting multi-item orders more heavily.

### `Avg Delivery Days`

* **Format:** Decimal Number (`0.00`)
* **Description:** True order-level average number of days elapsed between purchase date and customer delivery date.

```dax
Avg Delivery Days = 
AVERAGEX(
    KEEPFILTERS(VALUES(Fact_Order_Items[order_id])),
    CALCULATE(MAX(Fact_Order_Items[actual_delivery_days]))
)
```

### `Median Days`

* **Format:** Decimal Number (`0.00`)
* **Description:** Median delivery duration across unique orders. Used inside custom Report Page Tooltips alongside Avg Delivery Days to provide a robust central tendency metric against right-skewed cross-state route outliers.

```dax
Median Days = 
MEDIANX(
    KEEPFILTERS(VALUES(Fact_Order_Items[order_id])),
    CALCULATE(MAX(Fact_Order_Items[actual_delivery_days]))
)
```

### `Avg Days Ahead of SLA`

* **Format:** Decimal Number (`0.00`)
* **Description:** Average number of days an order is delivered before the promised estimated delivery date. The raw SQL variance (`delivery_date - estimated_delivery_date`) is inverted (`* -1`) so positive numbers intuitively represent days ahead of schedule.

```dax
Avg Days Ahead of SLA = 
AVERAGEX(
    VALUES(Fact_Order_Items[order_id]),
    VAR _raw_variance = CALCULATE(MAX(Fact_Order_Items[delivery_variance_days]))
    RETURN
    IF(
        NOT ISBLANK(_raw_variance),
        _raw_variance * -1
    )
)
```

### `On-Time Delivery Rate`

* **Format:** Percentage (`0.0%`)
* **Description:** Proportion of distinct orders delivered on or before the estimated SLA date (`delivery_variance_days <= 0`).

```dax
On-Time Delivery Rate = 
VAR OrdersDeliveredOnTime = 
    CALCULATE(
        DISTINCTCOUNT(Fact_Order_Items[order_id]),
        Fact_Order_Items[delivery_variance_days] <= 0
    )
RETURN
DIVIDE(OrdersDeliveredOnTime, [Total Orders], 0)
```

---

## 03. Time Intelligence

Period-over-period growth comparisons leveraging the dedicated `Dim_Calendar` date table.

### `Revenue Prior Month`

* **Format:** Currency (`R$ #,0.00`)
* **Description:** Total revenue shifted one month backward using `DATEADD` over the continuous `Dim_Calendar[Date]` column.

```dax
Revenue Prior Month = 
CALCULATE(
    [Total Revenue],
    DATEADD(Dim_Calendar[Date], -1, MONTH)
)
```

### `Revenue MoM Growth %`

* **Format:** Percentage (`0.0%`)
* **Description:** Month-over-Month (MoM) relative revenue growth rate.

```dax
Revenue MoM Growth % = 
DIVIDE(
    [Total Revenue] - [Revenue Prior Month],
    [Revenue Prior Month],
    0
)
```

---

## 04. Customer Insights (RFM & Retention)

Customer-grain KPIs evaluated over `Dim_Customers[customer_unique_id]` to track actual physical buyers across repeat orders.

### `Total Unique Customers`

* **Format:** Whole Number (`#,0`)
* **Description:** Total distinct physical buyers (`customer_unique_id`), decoupled from order-specific `customer_id` keys.

```dax
Total Unique Customers = 
DISTINCTCOUNT(Dim_Customers[customer_unique_id])
```

### `Champions Count`

* **Format:** Whole Number (`#,0`)
* **Description:** Number of unique customers classified in the top behavioral RFM tier (Champions: `r_score >= 4`, `f_score >= 2`, `m_score >= 4`).

```dax
Champions Count = 
CALCULATE(
    DISTINCTCOUNT(Dim_Customers[customer_unique_id]),
    Dim_Customers[customer_segment] = "Champions"
)
```

### `One-Time Buyers %`

* **Format:** Percentage (`0.0%`)
* **Description:** Share of unique customers who have placed only a single order (`frequency = 1`) across the entire historical dataset.

```dax
One-Time Buyers % = 
VAR OneTimers = 
    CALCULATE(
        DISTINCTCOUNT(Dim_Customers[customer_unique_id]),
        Dim_Customers[frequency] = 1
    )
RETURN
DIVIDE(OneTimers, [Total Unique Customers], 0)
```