![Main Data Model - Subscriptions and others](https://github.com/AdemolaI/Analysis-of-Tech-Product-Usage-and-Customer-Experience-with-SQL/assets/38536710/a84834eb-a6b0-4b91-b565-ce918cc5f487)


# Analysis of Tech Product Usage and Customer Experience with SQL

A tech company's product was analysed to discover insights on the product subscriptions, usage and customer experience to develop strategies to improve customer experience and boost revenue.
The analysis involves the application of different SQL methods to answer business questions.

## 1. Product Analysis in SQL with CTEs
	- Summarized Customer Data for Leadership by Combining Aggregate Functions with CTEs
	- Calculated descriptive statistics for monthly revenue by product using CTE
	- Exploring variable distribution with CTE
	- Analysed Payment Funnel to identify the furthest point in the payment process for customers using CTEs
        
## 2. Data Transformation in SQL with CASE
	- Recoded and Bucketed Values using CASE
	- Created Binary Columns with CASE
	- Pivoted rows into aggregated columns with CASE
        
## 3. Combining Multiple Data Sources in SQL with Union
	- Computed the number of active subscriptions that expire yearly, [active = 1].
	- Analyzed Subscription Cancelation Reasons by unpivoting columns into rows using UNION
        
## 4. Dealing with Hierarchical Data in SQL with SELF JOIN
	- Pulled employee/manager data based on hierarchical relationships with a SELF JOIN
	- Compared month-over-month (MoM) Revenue across to identify months when revenue was up using SELF JOIN.
        
## 5. Solving Advanced Problems in SQL with Window Functions
	- Extracted the data for the most recent sale per sales rep using Window Function- ROW_NUMBER()
	- Tracked Sales Quota Progress over Time by Running Totals using SUM()
	- Tracked User Payment Funnel Times by timestamp difference using LEAD()
