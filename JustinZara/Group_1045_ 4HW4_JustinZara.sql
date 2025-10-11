USE WideWorldImporters;

--Proposition 1 Get salespeople who made orders on the latest date
SELECT OuterQuery.SalespersonPersonID , OuterQuery.CustomerID, OuterQuery.OrderDate
FROM Sales.Orders OuterQuery
WHERE OuterQuery.OrderDate = (
	SELECT MAX(InnerQuery.OrderDate) AS LatestOrderDate
	FROM Sales.Orders AS InnerQuery
)
ORDER BY OuterQuery.SalespersonPersonID;
--This query can be used by businesses to keep track of employees that make the most sales in the latest date.

--Proposition 2 Get customers who had invoices from 2016
SELECT i.InvoiceDate, i.CustomerID
FROM Sales.Invoices i
WHERE i.CustomerID IN (
	SELECT i.CustomerID 
	FROM Sales.Invoices
	WHERE YEAR(i.InvoiceDate) = '2016'
);
--This query can be used by businesses to identify the number of customers who have invoices on a given year.

--Proposition 3 Select people who have picked orders
SELECT p.PersonID, p.FullName 
FROm Application.People AS p
WHERE EXISTS (
SELECT 1
FROM Sales.Orders AS o
WHERE o.PickedByPersonID = p.PersonID
);
--this query can be used by businesses to identify the type of people that pick orders.

--proposition 4 Select the expected delivery date of customer after january 1 2015
SELECT o.ExpectedDeliveryDate, o.CustomerID
FROM Sales.Orders AS o
where o.OrderDate IN (
 SELECT o.OrderDate
 FROM Sales.Orders as o
 WHERE o.OrderDate >= '2015-01-01' AND o.OrderDate < '2016-01-01'
);
--this query can be used to identify whether or not delivery times are improving during a certain year

--proposition 5 Find stock items from suppliers who provide more than 70 stock items in total.
SELECT si.StockItemName, si.SupplierID 
FROM Warehouse.StockItems si
WHERE si.SupplierID IN (
	SELECT si.SupplierID
	FROM Warehouse.StockItems si
	GROUP BY SupplierID
	HAVING COUNT(StockItemID) > 70
)
ORDER BY si.SupplierID;
--this can help businesses identify which suppliers have a large range of products

--Proposition 6: SELECT top 5 customers who made the most orders in 2016
WITH CustomersIn2016 AS (
	SELECT o.CustomerID, COUNT(o.OrderID) AS TotalOrders
	FROM Sales.Orders o
	WHERE YEAR(o.OrderDate) = 2016
	GROUP BY o.CustomerID 
)
SELECT TOP 5 ci.CustomerID, ci.TotalOrders 
FROM CustomersIn2016 as ci
ORDER BY ci.TotalORders DESC;
--This can be used  by businesses to identify the most active customers ion a given year

--proposition 7: SELECT the total sales of each salesperson in 2016
WITH SalesByPerson AS (
	SELECT o.SalespersonPersonID,
	SUM(ol.Quantity * ol.UnitPrice) AS TotalSales
	FROM Sales.Orders as o
	JOIN Sales.OrderLines as ol
	ON o.OrderID = ol.orderID
	WHERE YEAR(o.OrderDate) = 2016
	GROUP BY o.SalespersonPersonID 
)
SELECT sbp.SalespersonPersonID ,sbp.TotalSales
FROM SalesByPerson AS sbp
ORDER BY sbp.TotalSales DESC;
--this proposition can be used to track which salesperson makes the most sales in a given yaer

--proposition 8 get the top 3 stock items with the greatest total quantity in 2013
WITH ItemSales AS (
	SELECT ol.StockItemID, SUM(ol.Quantity) as TotalQuantity
	FROM Sales.OrderLines ol
	JOIN Sales.Orders o 
	ON ol.OrderID =o.OrderID 
	WHERE YEAR(o.OrderDate) = 2013
	GROUP BY ol.StockItemID
)
SELECT TOP 3 isa.stockItemID, si.StockItemName 
FROM ItemSales AS isa
INNER JOIN Warehouse.StockItems as si
ON si.StockItemID = isa.StockItemID
ORDER BY isa.TotalQuantity DESC;
--Helps business analyze sales trends.

--Proposition 9 Compute Average Order Value per Customer
WITH CustomerSales AS (
    SELECT  o.CustomerID, SUM(ol.Quantity * ol.UnitPrice) AS TotalSpent, COUNT(DISTINCT o.OrderID) AS TotalOrders
    FROM Sales.Orders AS o
    JOIN Sales.OrderLines AS ol
    ON o.OrderID = ol.OrderID
    GROUP BY o.CustomerID
)
SELECT c.CustomerName, cs.TotalSpent, cs.TotalOrders, (cs.TotalSpent / cs.TotalOrders) AS AvgOrderValue
FROM CustomerSales AS cs
JOIN Sales.Customers AS c
ON cs.CustomerID = c.CustomerID
ORDER BY AvgOrderValue DESC;
--This can be used by businesses to determine how much each customer usually spends per order

--proposition 10 Get customers who placed orders but have no invoices
WITH CustomersWithOrders AS (
    SELECT DISTINCT o.CustomerID
    FROM Sales.Orders AS o
)
SELECT c.CustomerID, c.CustomerName
FROM Sales.Customers AS c
JOIN CustomersWithOrders AS co
ON c.CustomerID = co.CustomerID
WHERE c.CustomerID NOT IN (
    SELECT DISTINCT i.CustomerID
    FROM Sales.Invoices AS i
)
ORDER BY c.CustomerName;
--This can be used by businesses to make siure all orders have an invoice.
