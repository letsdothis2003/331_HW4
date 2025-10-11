USE WideWorldImporters

/*
 * 1. The items that have a higher price than the average unitPrice of all items
 *  The inner query calculates the average price of all items
 *  The outer query filters out all items that have a higher than average price
 */
SELECT 
    si.StockItemID,
    si.StockItemName,
    si.UnitPrice
FROM Warehouse.StockItems si
WHERE UnitPrice > (
    SELECT AVG(UnitPrice) 
    FROM Warehouse.StockItems si2
);

/*
 * 2. The latest order from each customer 
 *  The inner query calculates the most recent order from the customer,
 *  The outer query joins that specific date's order with a customer name
 */
SELECT 
    o.OrderID,
    o.CustomerID,
    c.CustomerName,
    o.OrderDate
FROM Sales.Orders o
INNER JOIN Sales.Customers c
    ON o.CustomerID = c.CustomerID
WHERE o.OrderDate  = (
    SELECT MAX(o2.OrderDate)
    FROM Sales.Orders o2
    WHERE o2.CustomerID = o.CustomerID
)
order by o.customerID;

/*
 * 3: Customers who have never placed an order
 *  The inner query uses not exists to see which customers do not have any attributed orders
 *  The outer query searches for the customer's information
 */
SELECT
	c.CustomerID,
	c.CustomerName
FROM
	Sales.Customers c
WHERE
	NOT EXISTS (
	SELECT
		1
	FROM
		Sales.Orders o
	WHERE
		o.CustomerID = c.CustomerID )
ORDER BY
	c.CustomerName;

/*
 * 4: Customers who have placed more than 10 orders
 *  The inner query counts the number of orders for each customer
 *  The outer query filters out customers with more than 10 orders
 */
SELECT
	c.CustomerID,
	c.CustomerName
FROM
	Sales.Customers AS c
WHERE
	(
	SELECT
		COUNT(*)
	FROM
		Sales.Orders AS o
	WHERE
		o.CustomerID = c.CustomerID
) > 10
ORDER BY
	c.CustomerName;

/*
 * 5: Find the customers that have ordered a specific product
 *  The inner query joins Sales.Invoices that contains customer information with Sales.InvoiceLines which contains the product information
 * 		then filters out the invoice lines that contain the declared StockItemID
 *  The outer query retrieves the customer's information from the filtered invoices
 */
DECLARE @StockItemID INT = 79;
SELECT
	c.CustomerID,
	c.CustomerName,
	c.PhoneNumber
FROM
	Sales.Customers c
WHERE
	c.CustomerID IN (
	SELECT
		i.CustomerID
	FROM
		Sales.Invoices i
	INNER JOIN Sales.InvoiceLines il
        ON
		i.InvoiceID = il.InvoiceID
	WHERE
		il.StockItemID = @StockItemID
)
ORDER BY
	CustomerID;

/*
 * 6: Best selling products
 *  The CTE ProductSales sums the total quantity sold for each item
 *  The outer query sorts the the results by amount sold
 */
WITH ProductSales AS (
    SELECT
        il.StockItemID,
        si.StockItemName,
        SUM(il.Quantity) AS TotalSold
    FROM Sales.InvoiceLines il
    INNER JOIN Warehouse.StockItems si 
        ON il.StockItemID = si.StockItemID 
    GROUP BY il.StockItemID, si.StockItemName
)
SELECT *
FROM ProductSales
ORDER BY TotalSold DESC;

/*
 * 6: Top Salespersons
 *  The CTE SalespersonSales sums the total sales of each sales person from their invoices 
 *  The outer query sorts by the most amount sold
 */
WITH SalespersonSales AS (
    SELECT
        e.PersonID AS SalespersonID,
        e.FullName,
        SUM(il.Quantity * il.UnitPrice) AS TotalSales
    FROM Application.People e
    INNER JOIN Sales.Invoices i
        ON e.PersonID = i.SalespersonPersonID
    INNER JOIN Sales.InvoiceLines il
        ON i.InvoiceID = il.InvoiceID
    WHERE e.IsEmployee = 1 AND e.IsSalesperson = 1
    GROUP BY e.PersonID, e.FullName
)
SELECT *
FROM SalespersonSales
ORDER BY TotalSales DESC;

/*
 * 7: Top Customers by Average Spend
 *  The CTE CustomerOrderTotals sums the calculated total sales of each customer, and selects the customer ID and name.
 *  The outer query calculates the average of the total sales and sorts by highest average
 */
WITH CustomerOrderTotals AS (
    SELECT
        i.CustomerID,
        c.CustomerName,
        SUM(il.Quantity * il.UnitPrice) AS OrderTotal
    FROM Sales.Invoices i
    INNER JOIN Sales.InvoiceLines il
        ON i.InvoiceID = il.InvoiceID
    INNER JOIN Sales.Customers c 
        ON i.CustomerID = c.CustomerID 
    GROUP BY i.InvoiceID, i.CustomerID, c.CustomerName
)
SELECT 
    cot.CustomerID,
    cot.CustomerName,
    AVG(cot.OrderTotal) AS AvgOrderValue
FROM CustomerOrderTotals cot
GROUP BY cot.CustomerID, cot.CustomerName
ORDER BY AvgOrderValue DESC;

/*
 * 8: Customers who have an invoice on Black Friday 2015 but not 2016
 *  The two CTE's filter out every customer that has placed an order during Black Friday in their respective years.
 *  The outer query uses a left join and filters out the nulls to see who hasn't placed an order in 2016 Black Friday
 */
WITH Customers2015 AS (
    SELECT DISTINCT
        i.CustomerID
    FROM Sales.Invoices i
    WHERE i.InvoiceDate = '2015-11-27'
),
Customers2016 AS (
    SELECT DISTINCT
        i.CustomerID
    FROM Sales.Invoices i
    WHERE i.InvoiceDate = '2016-11-26'
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber
FROM Sales.Customers c
INNER JOIN Customers2015 c15 
    ON c.CustomerID = c15.CustomerID
LEFT JOIN Customers2016 c16 
    ON c.CustomerID = c16.CustomerID
WHERE c16.CustomerID IS NULL
ORDER BY c.CustomerName;

/*
 * 9. The items that have a higher price than the average unitPrice of all items, and how many have been sold in total
 *  The CTE AvgPrice computes the average price of all of the items in the warehouse
 *  The outer query inner joins with the invoice lines to calculate the total number sold, 
 *  and cross joins with the average price to filter out the items with a higher average price
 */
WITH AvgPrice AS (
SELECT
	AVG(UnitPrice) AS AveragePrice
FROM
	Warehouse.StockItems
)
SELECT
	si.StockItemID,
	si.StockItemName,
	si.UnitPrice,
	SUM(il.Quantity) AS TotalQuantitySold
FROM
	Warehouse.StockItems si
INNER JOIN Sales.InvoiceLines il 
    ON
	si.StockItemID = il.StockItemID
CROSS JOIN AvgPrice
WHERE
	si.UnitPrice > AvgPrice.AveragePrice
GROUP BY
	si.StockItemID,
	si.StockItemName,
	si.UnitPrice
ORDER BY
	TotalQuantitySold DESC;

/*
 * 10. The Total number of sales per month each year
 *  The CTE MonthlySales computes the sum of sales and groups them by month and year
 *  The outer query sorts the results in chronological order
 */
WITH MonthlySales AS (
    SELECT
        YEAR(i.InvoiceDate) AS Year,
        MONTH(i.InvoiceDate) AS Month,
        SUM(il.Quantity * il.UnitPrice) AS TotalSales
    FROM Sales.Invoices i
    INNER JOIN Sales.InvoiceLines il
        ON i.InvoiceID = il.InvoiceID
    GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
)
SELECT *
FROM MonthlySales
ORDER BY Year, Month;





