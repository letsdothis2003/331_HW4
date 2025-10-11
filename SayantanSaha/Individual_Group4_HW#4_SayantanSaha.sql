/* Chapter 4 Queries */

/* Query 1 - Stock Items Above Average Price (All-Time)
Functional Specification
- Compute overall average UnitPrice from Warehouse.StockItems.
- Filter stock items where UnitPrice > (overall average).
- Return basic item details; sort by UnitPrice desc then name.
*/
SELECT StockItemID, StockItemName, UnitPrice
FROM WideWorldImporters.Warehouse.StockItems
WHERE UnitPrice > (
  SELECT AVG(UnitPrice)
  FROM WideWorldImporters.Warehouse.StockItems
)
ORDER BY UnitPrice DESC, StockItemName;

/* Query 2 - Customers With At Least One Order
Functional Specification
- Subquery gets distinct CustomerID values from Sales.Orders.
- Keep customers whose CustomerID appears in that set (IN).
- Output id and name; sort by name.
*/
SELECT CustomerID, CustomerName
FROM WideWorldImporters.Sales.Customers
WHERE CustomerID IN (
  SELECT DISTINCT CustomerID
  FROM WideWorldImporters.Sales.Orders
)
ORDER BY CustomerName;

/* Query 3 - Customers With At Least One Invoice
Functional Specification
- Use EXISTS to test if a matching row exists in Sales.Invoices.
- Match on c.CustomerID = i.CustomerID.
- Output id and name; sort by name.
*/
SELECT c.CustomerID, c.CustomerName
FROM WideWorldImporters.Sales.Customers AS c
WHERE EXISTS (
  SELECT 1
  FROM WideWorldImporters.Sales.Invoices AS i
  WHERE i.CustomerID = c.CustomerID
)
ORDER BY c.CustomerName;

/* Query 4 - Stock Items Sold At Least Once
Functional Specification
- Check existence of any InvoiceLines for each StockItemID.
- Keep items where a matching line exists (EXISTS).
- Output id and name; sort by name.
*/
SELECT si.StockItemID, si.StockItemName
FROM WideWorldImporters.Warehouse.StockItems AS si
WHERE EXISTS (
  SELECT 1
  FROM WideWorldImporters.Sales.InvoiceLines AS il
  WHERE il.StockItemID = si.StockItemID
)
ORDER BY si.StockItemName;

/* Query 5 - Orders With Customer Name (No JOIN)
Functional Specification
- Outer query: Sales.Orders.
- Scalar subquery fetches CustomerName by o.CustomerID.
- Return order id, customer name, order date; sort by date desc.
*/
SELECT o.OrderID,
       (SELECT c.CustomerName
        FROM WideWorldImporters.Sales.Customers AS c
        WHERE c.CustomerID = o.CustomerID) AS CustomerName,
       o.OrderDate
FROM WideWorldImporters.Sales.Orders AS o
ORDER BY o.OrderDate DESC, o.OrderID;

/* Chapter 5 Queries */

/* Query 6 - Active Customers From Invoices (Derived Table)
Functional Specification
- Derived table D: DISTINCT CustomerID from Sales.Invoices.
- Join D -> Sales.Customers to get names.
- Return id and name; sort by name.
*/
SELECT c.CustomerID, c.CustomerName
FROM (
  SELECT DISTINCT CustomerID
  FROM WideWorldImporters.Sales.Invoices
) AS d
JOIN WideWorldImporters.Sales.Customers AS c
  ON c.CustomerID = d.CustomerID
ORDER BY c.CustomerName;

/* Query 7 - Picked Orders Only (CTE)
Functional Specification
- CTE PickedOrders filters Sales.Orders where PickingCompletedWhen IS NOT NULL.
- Select from CTE; show basic columns.
- Sort by PickingCompletedWhen desc then OrderID.
*/
WITH PickedOrders AS (
  SELECT OrderID, CustomerID, PickingCompletedWhen
  FROM WideWorldImporters.Sales.Orders
  WHERE PickingCompletedWhen IS NOT NULL
)
SELECT OrderID, CustomerID, PickingCompletedWhen
FROM PickedOrders
ORDER BY PickingCompletedWhen DESC, OrderID;

/* Query 8 - Latest 100 Invoices (CTE)
Functional Specification
- CTE LatestInvoices selects TOP (100) by InvoiceDate desc, InvoiceID desc.
- Return id, customer, date from CTE.
- Keep same ordering as CTE.
*/
WITH LatestInvoices AS (
  SELECT TOP (100) InvoiceID, CustomerID, InvoiceDate
  FROM WideWorldImporters.Sales.Invoices
  ORDER BY InvoiceDate DESC, InvoiceID DESC
)
SELECT InvoiceID, CustomerID, InvoiceDate
FROM LatestInvoices
ORDER BY InvoiceDate DESC, InvoiceID DESC;

/* Query 9 - Short Item Name Using CROSS APPLY (Inline TE)
Functional Specification
- From Warehouse.StockItems.
- CROSS APPLY single-row VALUES to compute ShortName = LEFT(StockItemName, 12).
- Return id, full name, short name; sort by full name.
*/
SELECT si.StockItemID, si.StockItemName, v.ShortName
FROM WideWorldImporters.Warehouse.StockItems AS si
CROSS APPLY (VALUES (LEFT(si.StockItemName, 12))) AS v(ShortName)
ORDER BY si.StockItemName;

/* Query 10 - Most Recent Invoice Per Customer (OUTER APPLY)
Functional Specification
- From Sales.Customers.
- OUTER APPLY TOP (1) invoice for that customer ordered by InvoiceDate desc.
- Return customer + last invoice; sort by customer name.
*/
SELECT c.CustomerID, c.CustomerName, x.InvoiceID, x.InvoiceDate
FROM WideWorldImporters.Sales.Customers AS c
OUTER APPLY (
  SELECT TOP (1) i.InvoiceID, i.InvoiceDate
  FROM WideWorldImporters.Sales.Invoices AS i
  WHERE i.CustomerID = c.CustomerID
  ORDER BY i.InvoiceDate DESC, i.InvoiceID DESC
) AS x
ORDER BY c.CustomerName;
