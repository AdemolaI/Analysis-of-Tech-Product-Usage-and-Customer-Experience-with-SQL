-- Solve Real-World Data Problems with SQL. 
-- ============================================
 /*
 -Summarizing Customer Data for Leadership by Combining Aggregate Functions with CTEs
 - CASE 1. Create CTE that agregates the number of users by customer
*/
WITH num_users AS(
SELECT 
	customerid,
    SUM(numberofusers) AS total_users
FROM 
	subscriptions
GROUP BY 
	customerid
)

-- compute the average of all the summed values
SELECT 
	AVG(total_users) AS average_users
FROM 
	num_users;
    
-- =============================================================================
/*
- Case 2. Calculating descriptive statistics for monthly revenue by product using CTE
Business Problem:
Using a CTE and the subscriptions and products tables, calculate the:
* ﻿﻿minimum monthly revenue: min_rev
* ﻿﻿maximum monthly revenue: max_rev
* ﻿﻿average monthly revenue: avg_rev
* ﻿﻿standard deviation of monthly revenue: std_dev_rev
for each product, ProductName
*/
WITH monthly_revs AS(
SELECT 
	p.productname, 
    DATE_TRUNC('month', orderdate) AS ordermonth,
	SUM(revenue) AS revenue
FROM subscriptions AS s
JOIN products AS p
ON s.productid = p.productid
WHERE s.orderdate BETWEEN '2022-1-1' AND '2022-12-31'
GROUP BY DATE_TRUNC('month', orderdate), productname
)

SELECT 
	productname,
	MIN(revenue) as min_rev,
	MAX(revenue) as max_rev,
	AVG(revenue) as avg_rev,
	STDDEV(revenue) as std_dev_rev
FROM 
	monthly_revs
GROUP BY 
	productname;
    
-- =============================================================================
/*
- CASE 3. Exploring variable distribution with CTE
Business Problem:
Using a CTE and the [frontendevent] log table, find the distribution of users across 
the number of times the email link was clicked per user.
In other words, count the number of users, [num_users], in each 
num_link_clicks category (one click, two clicks, three clicks,..) using
[eventid = 5] to track link clicks.
*/
WITH c AS(
SELECT 
	userid,
	count(*) AS num_link_clicks
FROM frontendeventlog AS f
WHERE eventid = 5
GROUP BY userid
)

SELECT 
	num_link_clicks, 
    COUNT(*) AS num_users
FROM c
GROUP BY num_link_clicks;

-- =============================================================================
/*
Case 4. Payment funnel analysis with multiple CTEs
Business Problem:
Count the number of subscriptions in each [paymentfunnelstage] 
by incorporating the the [maxstatus] reached and [currentstatus] 
per subscription. Use the [paymentstatuslog] and [subscriptions] tables.
*/
WITH max_status AS(
SELECT
	subscriptionid,
	MAX(statusid) as maxstatus
FROM 
	paymentstatuslog
GROUP BY subscriptionid
)
,
funnel_stage AS(
SELECT
	s.subscriptionid,
	CASE WHEN maxstatus = 1 THEN 'PaymentWidgetOpened'
		WHEN maxstatus = 2 THEN 'PaymentEntered'
		WHEN m.maxstatus = 3 AND currentstatus = 0 THEN 'User Error with Payment Submission'
		WHEN maxstatus = 3 AND currentstatus != 0 THEN 'Payment Submitted'
		WHEN maxstatus = 4 AND currentstatus = 0 THEN 'Payment Processing Error with Vendor'
		WHEN maxstatus = 4 AND currentstatus != 0 THEN 'Payment Success'
		WHEN maxstatus = 5 THEN 'Complete'
		WHEN maxstatus IS NULL THEN 'User did not start payment process'
	END AS paymentfunnelstage
FROM 
	subscriptions AS s
LEFT JOIN 
	max_status AS m
ON s.subscriptionid = m.subscriptionid
)

SELECT 
	paymentfunnelstage,
	COUNT(subscriptionid) AS subscriptions
FROM 
	funnel_stage
GROUP BY 
	paymentfunnelstage;
    
-- =============================================================================
-- Case 5. Recoding and Bucketing Values using CASE
SELECT 
	customerid, 
    SubscriptionID,
	CASE WHEN currentstatus = 5 THEN 'User Completed Payment Process'
		WHEN currentstatus = 0 THEN 'User is in error status'
		WHEN currentstatus IN (1, 2, 3, 4 ) THEN 'User is in Payment Process'
		WHEN currentstatus IS NULL THEN 'User has not interacted with payment widget'
	END AS UserPaymentStage
FROM 
	subscriptions;
    
-- =============================================================================
/*
-- Case 6. Creating Binary Columns with CASE
Business Problem:
Create a report using the subscriptions table that contains:
* customerid
* The total number of products for that customer, num_products
* The total number of users for that customer, total_users
* Binary column that flags 1 for those who meet one of the upsell_opportunity 
conditions using CASE. 
* The upsell _opportunity column should mark 1 for companies who have 
at least 5,000 users or only 1 product subscription. It should be marked 0 for all other customers.
*/
SELECT 
    customerid,
    COUNT(productid) AS num_products,
    SUM(numberofusers) AS total_users,
    CASE
        WHEN SUM(numberofusers) >= 5000 
            OR COUNT(subscriptionid) = 1
        THEN 1
        ELSE 0
    END AS upsell_opportunity 
FROM 
    subscriptions
GROUP BY 
    customerid;

-- =============================================================================
/*
-- CASE 7. Pivoting rows into aggregated columns with CASE
Business Problem:
Using the FrontendEventLog table and CASE, count the number of 
times a user completes the following events:
* ViewedHelpCenterPage (eventid = 1)
* ClickedFAQs (eventid = 2)
* ClickedContactSupport (eventid = 3)
* SubmittedTicket (eventid = 4)

* Filter the events with [eventtype = 'Customer Support] from the 
[frontendeventdefinitions] table to pull only the events related to customer support.
*/
SELECT
    userid,
    SUM(
        CASE 
            WHEN fl.eventid = 1 THEN 1
            ELSE 0
        END
    ) AS viewedhelpcenterpage,
    SUM(
        CASE 
            WHEN fl.eventid = 2 THEN 1
            ELSE 0
        END
    ) AS clickedfaqs,
    SUM(
        CASE 
            WHEN fl.eventid = 3 THEN 1
            ELSE 0
        END
    ) AS clickedcontactsupport,
    SUM(
        CASE 
            WHEN fl.eventid = 4 THEN 1
            ELSE 0
        END
    ) AS submittedticket
FROM 
    frontendeventlog AS fl
JOIN 
    frontendeventdefinitions AS f
    ON fl.eventid = f.eventid
WHERE 
    f.eventtype = 'Customer Support'
GROUP BY 
    userid;

-- =============================================================================
/*
CASE 8. Combine products tables with UNION
Business Problem:
Count the number of active subscriptions, [active = 1], that will expire in each year.
Get the code that aggregates the number of subscriptions by year.
Get the code for the [all_subscriptions] СТЕ.
*/

With all_subscriptions as(
SELECT
	subscriptionid,
	expirationdate
FROM 
	subscriptionsproduct1
WHERE
	active = 1

UNION ALL

SELECT
	subscriptionid,
	expirationdate
FROM 
	subscriptionsproduct2
WHERE
	active = 1
)

SELECT
	DATE_TRUNC('year', expirationdate) AS exp_year, 
	COUNT(*) AS subscriptions
FROM 
	all_subscriptions
GROUP BY 
	date_trunc('year', expirationdate);

-- =============================================================================
/*
-- CASE 9. Unpivoting columns into rows using UNION
Business problem: Analyzing Subscription Cancelation Reasons

Using UNION and the [cancelations] table, calculate the percent of 
canceled subscriptions that reported [Expensive] as one of their cancelation reasons.
Get the code that calculates the percentage.  
Get the code for the [all_cancelation_reasons] CTE.
*/
 
WITH all_cancelation_reasons AS(
SELECT 
    subscriptionid,
    cancelationreason1 AS cancelationreason
FROM
    cancelations

UNION

SELECT
    subscriptionid,
    cancelationreason2 AS cancelationreason
FROM
    cancelations

UNION

SELECT
    subscriptionid,
    cancelationreason3 AS cancelationreason
FROM
    cancelations
)

SELECT 
    CAST(COUNT(
        CASE WHEN cancelationreason = 'Expensive' 
        THEN subscriptionid END) AS float)
    /COUNT(DISTINCT subscriptionid) AS percent_expensive
FROM    
    all_cancelation_reasons;

-- =============================================================================
-- Case 10. Extract the data of users and `their corresponding admins using a SELF JOIN
SELECT
	users.name AS username,
    admin.name AS adminname
FROM
	users
LEFT JOIN
	users AS admin
ON user.adminid = admin.userid;

-- =============================================================================
/*
-- CASE 11. Using self joins to pull hierarchical relationships
Business problem: Pulling employee/manager data with a SELF JOIN

Create an email list from the [employees] table that 
includes the following columns for all employees under [department - ‘Sales’].
* employeeid
* employee_name
* manager_name
* contact_email (use the manager email if available and the employee email if not)
*/

SELECT
    employees.employeeid AS employeeid,
    employees.name AS employee_name,
    managers.name AS manager_name,
    CASE
        WHEN managers.email IS NOT NULL THEN managers.email
        WHEN managers.email IS NULL THEN employees.email
    END AS contact_email
FROM
    employees
LEFT JOIN
    employees AS managers
ON employees.managerid = managers.employeeid
WHERE employees.department = 'Sales';

-- -----------------------------------
-- ALTERNATIVE METHOD USING COALESCE 
-- -----------------------------------
SELECT
    employees.employeeid AS employeeid,
    employees.name AS employee_name,
    managers.name AS manager_name,
    COALESCE(managers.email, employees.email) AS contact_email
FROM
    employees
LEFT JOIN
    employees AS managers
ON employees.managerid = managers.employeeid
WHERE employees.department = 'Sales';

-- =============================================================================
/*
-- Case 12. Using Self Joins to Compare Rows Within the Same Table
Business problem: Comparing MoM Revenue

Get the code to create the [monthly_revenue] CTE that uses 
the [subscriptions] table and sums the total revenue by month. 
Use this code to create the CTE.
Using the [monthly_revenue] CTE joined to itself, pull a report that includes 
the following fields:
* [current _month]: the current month
* [previous _month]; the previous month from the current month
* [current revenue]: the monthly revenue of the current month
* [previous_revenue]: the monthly revenue of the previous month
*/

WITH monthly_revenue AS(
SELECT 
    DATE_TRUNC('month', orderdate) as order_month, 
    SUM(revenue) as monthly_revenue
FROM 
    subscriptions
GROUP BY 
    DATE_TRUNC('month', orderdate)
)

SELECT
    current.order_month AS current_month,
    previous.order_month AS previous_month,
    current.monthly_revenue AS current_revenue,
    previous.monthly_revenue AS previous_revenue
FROM
    monthly_revenue AS current
JOIN monthly_revenue AS previous
WHERE 
    (current.monthly_revenue > previous.monthly_revenue) 
    AND
    (DATEDIFF('month', 
    previous.order_month, current.order_month) = 1);

-- =============================================================================
-- Case 13. Find the data for the most recent sale per sales rep using a Window Function
WITH sale_ranks AS(
SELECT
	salesemployeeid,
    salesamount,
    salesdate,
    ROW_NUMBER() 
		OVER(PARTITION BY salesemployeeid 
        ORDER BY salesdate DESC) AS most_recent_sale
FROM
	sales
)

SELECT
	*
FROM
	sale_ranks
WHERE most_recent_sale = 1;

-- =============================================================================
/*
-- CASE 14. Tracking Running Totals with Window Functions
Business problem: Tracking Sales Quota Progress over Time
Calculate the running total of sales revenue, [running total], 
and the % of quota reached, [percent_quota], for each 
sales employee on each date they make a sale. Use the sales] 
and employees table to pull in and create the following fields:
* ﻿﻿salesemployeeid 
* saledate
* saleamount
* ﻿﻿quota
* ﻿﻿running_total
* ﻿﻿percent_quota
Order the final output by [salesemployeeid] and [saledate].

-- Three Questions to Ask:
    1. What do you want to calculate? Sum of saleamount
    2. What do you want to partition by? salesemployeeid since it is for 
    each sales rep
    3. Is order important? Yes, because we need to calculate the total in order of
    when the sales occur each day.
*/

SELECT
    s.salesemployeeid,
    s.saledate,
    s.saleamount,
    SUM(s.saleamount) 
        OVER(PARTITION BY s.salesemployeeid 
        ORDER BY s.saledate) AS running_total,
    CAST(SUM(s.saleamount) 
        OVER(PARTITION BY s.salesemployeeid 
        ORDER BY s.saledate)AS FLOAT) 
        / e.quota AS percent_quota
FROM 
    SALES AS s
JOIN employees AS e
ON s.salesemployeeid = e.employeeid
ORDER BY s.salesemployeeid, saledate;

-- =============================================================================
/*
-- CASE 15. Timestamp difference using LEAD()
Business problem: Tracking User Payment Funnel Times with LEAD()

Using the [paymentstatuslog] table, pull payment funnel data for 
[subscriptionid = 38844]. For each status timestamp, calculate 
the time difference between that timestamp the next chronological 
timestamp in order to show how long the user was in each status 
before moving to the next status. You can use the window function 
[lead()] to pull the next chronological timestamp.

Include the following columns:
* SubscriptionMovement is
* Subscriptionid
* Statusid
* MovementDate
* NextStatusMovementDate
* TimeinStatus

Three Questions to Ask:
    1. What do you want to calculate? next chronological timestamp from the
    current one using LEAD().
    LEAD() takes the next value based how you ordered your rows
    2. What do you want to partition by? subscriptionid in order to let SQL know that
    we want the calculation on the subscription level.
    3. Is order important? Yes, because we need to calculate the next timestamp 
    chronologically in the log. We need to order by movementdate to get all the status 
    change in order.
*/

SELECT
    statusmovementid,
    subscriptionid,
    statusid,
    movementdate,
    lead(movementdate, 1) 
        OVER(PARTITION BY subscriptionid 
        ORDER BY movementdate) AS nextstatusmovementdate,
    lead(movementdate, 1) 
        OVER(PARTITION BY subscriptionid 
        ORDER BY movementdate)
        - movementdate AS timeinstatus
FROM
    paymentstatuslog
WHERE 
	subscriptionid = 38844
ORDER BY 
	movementdate;

-- =============================================================================