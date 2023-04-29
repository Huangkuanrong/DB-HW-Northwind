-- 找出和最貴的產品同類別的所有產品
-- Find all products in the same category as the most expensive product.
SELECT *
FROM Products
WHERE CategoryID = (SELECT CategoryID
                    FROM Products
                    WHERE UnitPrice = (SELECT MAX(UnitPrice)
                                       FROM Products));

-- 找出和最貴的產品同類別最便宜的產品
-- Find the cheapest product in the same category as the most expensive product.
SELECT *
FROM Products
WHERE CategoryID = (SELECT CategoryID
                    FROM Products
                    WHERE UnitPrice = (SELECT MAX(UnitPrice)
                                       FROM Products))
  AND UnitPrice = (SELECT MIN(UnitPrice)
                   FROM Products
                   WHERE CategoryID = (SELECT CategoryID
                                       FROM Products
                                       WHERE UnitPrice = (SELECT MAX(UnitPrice)
                                                          FROM Products)));

-- 計算出上面類別最貴和最便宜的兩個產品的價差
-- Calculate the price difference between the most expensive and cheapest products in the same category as above.
SELECT MAX(UnitPrice) - MIN(UnitPrice) AS PriceDifference
FROM Products
WHERE CategoryID = (SELECT CategoryID
                    FROM Products
                    WHERE UnitPrice = (SELECT MAX(UnitPrice)
                                       FROM Products));

-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶
-- Find all customers located in the city of customers who have not placed any orders.
SELECT *
FROM Customers
WHERE City IN (SELECT City
               FROM Customers
               WHERE CustomerID NOT IN (SELECT CustomerID
                                        FROM Orders));

-- 找出第 5 貴跟第 8 便宜的產品的產品類別
-- Find the category of the 5th most expensive and 8th cheapest products.
SELECT CategoryID, CategoryName
FROM Categories
WHERE CategoryID IN (SELECT CategoryID
                     FROM Products
                     ORDER BY UnitPrice DESC
                     OFFSET 4 ROWS FETCH NEXT 1 ROW ONLY
                     UNION
                     SELECT CategoryID
                     FROM Products
                     ORDER BY UnitPrice
                     OFFSET 7 ROWS FETCH NEXT 1 ROW ONLY);

-- 找出誰買過第 5 貴跟第 8 便宜的產品
-- Find who bought the 5th most expensive and 8th cheapest products.
WITH expensive_products AS (SELECT ProductID
                            FROM Products
                            ORDER BY UnitPrice DESC
                            OFFSET 4 ROWS FETCH NEXT 1 ROW ONLY),
     cheap_products AS (SELECT ProductID
                        FROM Products
                        ORDER BY UnitPrice
                        OFFSET 7 ROWS FETCH NEXT 1 ROW ONLY),
     buyer_data AS (SELECT CustomerID
                    FROM Orders
                    WHERE OrderID IN (SELECT OrderID
                                      FROM [Order Details]
                                      WHERE ProductID IN (SELECT ProductID
                                                          FROM expensive_products
                                                          UNION
                                                          SELECT ProductID
                                                          FROM cheap_products)))
SELECT CustomerID, CompanyName
FROM Customers
WHERE CustomerID IN (SELECT CustomerID
                     from buyer_data);

-- SELECT CategoryID, CategoryName
-- FROM Categories
-- WHERE CategoryID IN (
--   SELECT CategoryID
--   FROM (
--     SELECT ProductID, UnitPrice,
--       ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS expensive_rank,
--       ROW_NUMBER() OVER (ORDER BY UnitPrice) AS cheap_rank
--     FROM Products
--   ) p
--   WHERE p.expensive_rank = 5 OR p.cheap_rank = 8
--   GROUP BY CategoryID
--   HAVING COUNT(*) = 2
-- );

-- 找出誰賣過第 5 貴跟第 8 便宜的產品
-- Find who sold the 5th most expensive and 8th cheapest products.
WITH expensive_products AS (SELECT ProductID
                            FROM Products
                            ORDER BY UnitPrice DESC
                            OFFSET 4 ROWS FETCH NEXT 1 ROW ONLY),
     cheap_products AS (SELECT ProductID
                        FROM Products
                        ORDER BY UnitPrice
                        OFFSET 7 ROWS FETCH NEXT 1 ROW ONLY)
SELECT Suppliers.SupplierID, Suppliers.CompanyName
FROM Products
         JOIN Suppliers ON Products.SupplierID = Suppliers.SupplierID
WHERE Products.ProductID IN (SELECT ProductID
                             FROM expensive_products
                             UNION
                             SELECT ProductID
                             FROM cheap_products);

-- 找出 13 號星期五的訂單 (惡魔的訂單)
-- Find orders placed on Friday the 13th.
SELECT *
FROM Orders
WHERE DAY(OrderDate) = 13
  AND FORMAT(OrderDate, 'dddd') = 'Friday';

-- 找出誰訂了惡魔的訂單
-- Find who placed the orders on Friday the 13th.
SELECT CustomerID, CompanyName
FROM Customers
WHERE CustomerID IN (SELECT CustomerID
                     FROM Orders
                     WHERE DAY(OrderDate) = 13
                       AND FORMAT(OrderDate, 'dddd') = 'Friday');

-- 找出惡魔的訂單裡有什麼產品
-- Find what products are included in the orders placed on Friday the 13th.
SELECT p.ProductID, p.ProductName
FROM Products p
         JOIN [Order Details] od ON p.ProductID = od.ProductID
         JOIN Orders o ON od.OrderID = o.OrderID
WHERE DAY(o.OrderDate) = 13
  AND FORMAT(o.OrderDate, 'dddd') = 'Friday';

-- 列出從來沒有打折 (Discount) 出售的產品
-- List all products that have never been sold with a discount.
SELECT *
FROM Products
WHERE ProductID IN (SELECT ProductID
                    FROM [Order Details]
                    WHERE Discount = 0);

-- 列出購買非本國的產品的客戶
-- List all customers who have purchased products that are not from their country.
SELECT DISTINCT c.CustomerID, c.CompanyName
FROM Customers c
         JOIN Orders o ON c.CustomerID = o.CustomerID
         JOIN [Order Details] od ON o.OrderID = od.OrderID
         JOIN Products p ON od.ProductID = p.ProductID
         JOIN Suppliers s ON p.SupplierID = s.SupplierID AND c.Country <> s.Country
WHERE c.CustomerID = o.CustomerID
ORDER BY c.CustomerID;

-- 列出在同個城市中有公司員工可以服務的客戶
-- List all customers who can be serviced by company employees in the same city.
SELECT c.CustomerID, c.CompanyName, c.City, e.City
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN Employees e ON o.EmployeeID = e.EmployeeID
WHERE c.City = e.City

-- 列出那些產品沒有人買過
-- List all products that have never been purchased.
SELECT ProductID, ProductName
FROM Products
WHERE ProductID NOT IN (SELECT ProductID
                        FROM [Order Details]
                        WHERE OrderID NOT IN (SELECT OrderID
                                              FROM Orders));

----------------------------------------------------------------------------------------

-- 列出所有在每個月月底的訂單
-- List all orders at the end of each month.
SELECT *
FROM Orders
WHERE OrderDate IN (SELECT MAX(OrderDate)
                    FROM Orders
                    GROUP BY MONTH(OrderDate));

-- 列出每個月月底售出的產品
-- List products sold at the end of each month.
SELECT ProductID, ProductName
FROM Products
WHERE ProductID IN (SELECT ProductID
                    FROM [Order Details]
                    WHERE OrderID IN (SELECT OrderID
                                      FROM Orders
                                      WHERE OrderDate IN (SELECT MAX(OrderDate)
                                                          FROM Orders
                                                          GROUP BY MONTH(OrderDate))))

-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶
-- Find the top three customers who have purchased any of the three most expensive products.
WITH t1 AS
         (SELECT c.*,
                 od.*,
                 od.UnitPrice * od.Quantity * (1 - od.Discount) AS Total
          FROM Customers c
                   INNER JOIN Orders o ON o.CustomerID = c.CustomerID
                   INNER JOIN [Order Details] od ON od.OrderID = o.OrderID),
     t2 AS
         (SELECT TOP 3 ProductID
          FROM [Order Details]
          ORDER BY UnitPrice DESC)
SELECT TOP 3 CustomerID
FROM t1
WHERE ProductID IN (SELECT ProductID
                    FROM t2)
GROUP BY CustomerID
ORDER BY COUNT(*) DESC;

-- 找出有敗過銷售金額前三高個產品的前三個大客戶
-- Find the top three customers who have purchased the three products with the highest sales amounts.
WITH t1 AS
         (SELECT c.*,
                 od.*,
                 od.UnitPrice * od.Quantity * (1 - od.Discount) AS Total
          FROM Customers c
                   INNER JOIN Orders o ON o.CustomerID = c.CustomerID
                   INNER JOIN [Order Details] od ON od.OrderID = o.OrderID)
SELECT TOP 3 CustomerID
FROM t1
WHERE ProductID IN (SELECT TOP 3 ProductID
                    FROM t1
                    GROUP BY ProductID
                    ORDER BY SUM(Total) DESC)
GROUP BY CustomerID
ORDER BY SUM(Total) DESC;

-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶
-- Find the top three customers who have purchased products in the same category as the three products with the highest sales amounts.
WITH t1 AS
         (SELECT c.*,
                 od.*,
                 od.UnitPrice * od.Quantity * (1 - od.Discount) AS Total
          FROM Customers c
                   INNER JOIN Orders o ON o.CustomerID = c.CustomerID
                   INNER JOIN [Order Details] od ON od.OrderID = o.OrderID)
SELECT TOP 3 CustomerID
FROM t1
WHERE ProductID IN (SELECT DISTINCT ProductID
                    FROM t1
                    WHERE ProductID IN (SELECT TOP 3 ProductID
                                        FROM t1
                                        GROUP BY ProductID
                                        ORDER BY SUM(Total) DESC))
GROUP BY CustomerID
ORDER BY SUM(Total) DESC;

-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額
-- List the names of customers whose total spending is higher than the average spending of all customers, along with their total spending.
SELECT c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CompanyName
HAVING SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) >
       (SELECT AVG(Total)
        FROM (SELECT c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
              FROM Customers c
                       INNER JOIN Orders o ON c.CustomerID = o.CustomerID
                       INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
              GROUP BY c.CustomerID, c.CompanyName) AS t);

-- 列出最熱銷的產品，以及被購買的總金額
-- List the best-selling product and the total amount purchased.
SELECT TOP 1 ProductID, SUM(UnitPrice * Quantity * (1 - Discount)) AS Total
FROM [Order Details]
GROUP BY ProductID
ORDER BY SUM(UnitPrice * Quantity * (1 - Discount)) DESC;

-- 列出最少人買的產品
-- List the product with the least number of purchases.
SELECT TOP 1 ProductID, COUNT(*) AS Total
FROM [Order Details]
GROUP BY ProductID
ORDER BY COUNT(*);

-- 列出最沒人要買的產品類別 (Categories)
-- List the product category with the least demand.
SELECT TOP 1 CategoryID, COUNT(*) AS Total
FROM Products
GROUP BY CategoryID
ORDER BY COUNT(*);

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)
-- List customers who have purchased the most amount of products from the best supplier, along with the purchase amounts (including purchases from other suppliers).
SELECT TOP 1 c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
WHERE od.ProductID IN (SELECT TOP 1 ProductID
                       FROM [Order Details]
                       GROUP BY ProductID
                       ORDER BY SUM(UnitPrice * Quantity * (1 - Discount)) DESC)
GROUP BY c.CustomerID, c.CompanyName
ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC;

-- 列出那些產品沒有人買過
-- List products that have never been purchased.
SELECT ProductID
FROM Products
WHERE ProductID NOT IN (SELECT DISTINCT ProductID
                        FROM [Order Details]);

-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額
-- List customers who do not have a fax number and their total spending.
SELECT c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
WHERE c.Fax IS NULL
GROUP BY c.CustomerID, c.CompanyName;

-- 列出每一個城市消費的產品種類數量
-- List the number of different products purchased in each city.
SELECT c.City, COUNT(DISTINCT od.ProductID) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City;

-- 列出目前沒有庫存的產品在過去總共被訂購的數量
-- List the total number of past orders for products that are currently out of stock.
SELECT od.ProductID, SUM(od.Quantity) AS Total
FROM [Order Details] od
         INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE p.UnitsInStock = 0
GROUP BY od.ProductID;

-- 列出目前沒有庫存的產品
-- List all products that are currently out of stock.
SELECT *
FROM Products
WHERE UnitsInStock = 0;

-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額
-- List the customers without a fax number and their total spending.
SELECT c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
WHERE c.Fax IS NULL
GROUP BY c.CustomerID, c.CompanyName;

-- 列出每一個城市消費的產品種類數量
-- List the number of product categories purchased in each city.
SELECT c.City, COUNT(DISTINCT p.CategoryID) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
         INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.City;

-- 列出目前沒有庫存的產品在過去總共被訂購的數量
-- List the total number of orders for products that are currently out of stock.
SELECT od.ProductID, SUM(od.Quantity) AS Total
FROM [Order Details] od
         INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE p.UnitsInStock = 0
GROUP BY od.ProductID;

-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過
-- List the customers who have ordered products that are currently out of stock in the past.
SELECT DISTINCT c.CustomerID, c.CompanyName
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
         INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE p.UnitsInStock = 0;

-- 列出每位員工的下屬的業績總金額
-- List the total performance of each employee's subordinates.
SELECT e.EmployeeID, e.FirstName, e.LastName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Employees e
         INNER JOIN Orders o ON e.EmployeeID = o.EmployeeID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;

-- 列出每家貨運公司運送最多的那一種產品類別與總數量
-- List the product category and total quantity that each shipping company has delivered the most.
SELECT TOP 1 s.CompanyName, p.CategoryID, SUM(od.Quantity) AS Total
FROM Shippers s
         INNER JOIN Orders o ON s.ShipperID = o.ShipVia
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
         INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY s.CompanyName, p.CategoryID
ORDER BY SUM(od.Quantity) DESC;

-- 列出每一個客戶買最多的產品類別與金額
-- List the product category and amount spent for each customer's most purchased product.
SELECT c.CustomerID, c.CompanyName, p.CategoryID, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
         INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CompanyName, p.CategoryID;

-- 列出每一個客戶買最多的那一個產品與購買數量
-- List the most purchased product and its quantity for each customer.
SELECT c.CustomerID, c.CompanyName, p.ProductName, SUM(od.Quantity) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
         INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CompanyName, p.ProductName;

-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間
-- List the delivery time for the most recent order for each city.
SELECT c.City, MAX(o.ShippedDate) AS ShippedDate
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.City;

-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距
-- List the fifth and tenth highest spending customers and the difference in their spending.
SELECT TOP 1 c.CustomerID, c.CompanyName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Total
FROM Customers c
         INNER JOIN Orders o ON c.CustomerID = o.CustomerID
         INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC;
