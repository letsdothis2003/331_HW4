USE WideWorldImporters;

-- Proposition 1: Return all orders placed on the latest day of activity
/* Finds all orders that happened on the most recent date in the database. */
SELECT OrderID, OrderDate, CustomerID, SalespersonPersonID
FROM Sales.Orders
WHERE OrderDate = (SELECT MAX(OrderDate) FROM Sales.Orders);

-- Proposition 2: Find customer(s) with the most orders and return their orders
/* Finds the customers with the highest number of orders.*/

SELECT O.CustomerID, O.OrderID, O.OrderDate, O.SalespersonPersonID
FROM Sales.Orders O
WHERE O.CustomerID IN (
    SELECT TOP 1 WITH TIES CustomerID
    FROM Sales.Orders
    GROUP BY CustomerID
    ORDER BY COUNT(*) DESC
);

--Proposition 3 – Customers With Gaps of >180 Days Between Orders
/* Detects customers who had a long inactivity gap.*/
SELECT DISTINCT O1.CustomerID, C.CustomerName
FROM Sales.Orders O1
JOIN Sales.Customers C ON O1.CustomerID = C.CustomerID
WHERE EXISTS (
    SELECT 1
    FROM Sales.Orders O2
    WHERE O2.CustomerID = O1.CustomerID
      AND O2.OrderDate < O1.OrderDate
      AND DATEDIFF(DAY, O2.OrderDate, O1.OrderDate) > 180
);


-- Proposition 4: Customers who have placed more than 20 orders
/* Finds customers who are very active — specifically, those with more than 20 orders.*/

SELECT C.CustomerID, C.CustomerName, COUNT(O.OrderID) AS TotalOrders
FROM Sales.Customers C
JOIN Sales.Orders O
    ON C.CustomerID = O.CustomerID
GROUP BY C.CustomerID, C.CustomerName
HAVING COUNT(O.OrderID) > 20
ORDER BY TotalOrders DESC;

-- Proposition 5: Orders placed on each customer’s last active day

SELECT O.CustomerID, O.OrderID, O.OrderDate
FROM Sales.Orders O
WHERE O.OrderDate = (
    SELECT MAX(O2.OrderDate)
    FROM Sales.Orders O2
    WHERE O2.CustomerID = O.CustomerID
);

-- Proposition 6:Customers who placed an order in 2015 using a CTE

WITH Customers2015 AS (
    SELECT DISTINCT O.CustomerID
    FROM Sales.Orders O
    WHERE YEAR(O.OrderDate) = 2015
)
SELECT C.CustomerID, C.CustomerName
FROM Sales.Customers C
JOIN Customers2015 CT
    ON C.CustomerID = CT.CustomerID;

-- Proposition 7:-- Items priced above category average

SELECT P.StockItemID, P.StockItemName, P.UnitPrice, P.SupplierID
FROM Warehouse.StockItems P
WHERE P.UnitPrice > (
    SELECT AVG(P2.UnitPrice)
    FROM Warehouse.StockItems P2
    WHERE P2.UnitPackageID = P.UnitPackageID
);

-- Proposition 8: -- Customers from the same city as CustomerID = 10 using CROSS APPLY

SELECT C.CustomerID, C.CustomerName
FROM Sales.Customers C
CROSS APPLY (
    SELECT DeliveryCityID
    FROM Sales.Customers
    WHERE CustomerID = 10
) AS RefCity
WHERE C.DeliveryCityID = RefCity.DeliveryCityID;

--Proposotion 9: Compare IN vs EXISTS
/* Shows two different ways to ask the same question: “Which customers have placed orders?”*/
-- Using IN
SELECT CustomerID, CustomerName
FROM Sales.Customers
WHERE CustomerID IN (SELECT CustomerID FROM Sales.Orders);

-- Using EXISTS
SELECT C.CustomerID, C.CustomerName
FROM Sales.Customers C
WHERE EXISTS (SELECT 1
              FROM Sales.Orders O
              WHERE O.CustomerID = C.CustomerID);

-- Propostion 10: All orders that were handled by EmployeeID = 3
/* Lists orders handled by employee 3.*/
SELECT O.OrderID, O.OrderDate, O.CustomerID
FROM Sales.Orders O
WHERE O.SalespersonPersonID = (
    SELECT PersonID
    FROM Application.People
    WHERE PersonID = 3
);




