USE AdventureWorks2022;
GO

-- ============================================
-- SP1: Top Productos Vendidos
-- ============================================


CREATE PROCEDURE usp_BuscarCliente
    @nombre NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.CustomerID,
        p.FirstName,
        p.LastName,
        p.MiddleName,
        e.EmailAddress,
        pp.PhoneNumber,
        a.AddressLine1,
        a.City,
        sp.Name AS StateProvince,
        cr.Name AS Country
    FROM Sales.Customer c
    INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN Person.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID
    LEFT JOIN Person.PersonPhone pp ON p.BusinessEntityID = pp.BusinessEntityID
    LEFT JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
    LEFT JOIN Person.Address a ON bea.AddressID = a.AddressID
    LEFT JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
    LEFT JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
    WHERE p.FirstName LIKE '%' + @nombre + '%'
       OR p.LastName LIKE '%' + @nombre + '%'
    ORDER BY p.LastName, p.FirstName;
END
GO

CREATE PROCEDURE usp_GetTopProductos
    @top INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@top)
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        ps.Name AS SubcategoryName,
        SUM(sod.OrderQty) AS TotalQuantitySold,
        SUM(sod.LineTotal) AS TotalRevenue,
        AVG(sod.UnitPrice) AS AveragePrice
    FROM Production.Product p
    INNER JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    GROUP BY p.ProductID, p.Name, pc.Name, ps.Name
    ORDER BY TotalRevenue DESC;
END
GO

CREATE PROCEDURE usp_GetDetalleProducto
    @productId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        p.ProductNumber,
        pc.Name AS CategoryName,
        ps.Name AS SubcategoryName,
        p.Color,
        p.Size,
        p.Weight,
        p.ListPrice,
        p.StandardCost,
        SUM(sod.OrderQty) AS TotalUnitsSold,
        SUM(sod.LineTotal) AS TotalRevenue,
        COUNT(DISTINCT sod.SalesOrderID) AS NumberOfOrders
    FROM Production.Product p
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    WHERE p.ProductID = @productId
    GROUP BY 
        p.ProductID, p.Name, p.ProductNumber, pc.Name, ps.Name,
        p.Color, p.Size, p.Weight, p.ListPrice, p.StandardCost;
END
GO

CREATE PROCEDURE usp_GetVentasPorPeriodo
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CONVERT(DATE, soh.OrderDate) AS Fecha,
        COUNT(DISTINCT soh.SalesOrderID) AS NumeroOrdenes,
        SUM(soh.TotalDue) AS VentaTotal,
        AVG(soh.TotalDue) AS PromedioVenta,
        COUNT(DISTINCT soh.CustomerID) AS ClientesUnicos
    FROM Sales.SalesOrderHeader soh
    WHERE soh.OrderDate BETWEEN @fechaInicio AND @fechaFin
    GROUP BY CONVERT(DATE, soh.OrderDate)
    ORDER BY Fecha;
END
GO

CREATE PROCEDURE usp_GetVentasPorCategoria
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        pc.Name AS Categoria,
        COUNT(DISTINCT sod.SalesOrderID) AS NumeroOrdenes,
        SUM(sod.OrderQty) AS UnidadesVendidas,
        SUM(sod.LineTotal) AS VentaTotal,
        AVG(sod.UnitPrice) AS PrecioPromedio
    FROM Production.ProductCategory pc
    INNER JOIN Production.ProductSubcategory ps ON pc.ProductCategoryID = ps.ProductCategoryID
    INNER JOIN Production.Product p ON ps.ProductSubcategoryID = p.ProductSubcategoryID
    INNER JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    GROUP BY pc.Name
    ORDER BY VentaTotal DESC;
END
GO

CREATE PROCEDURE usp_GetResumenCliente
    @customerId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.CustomerID,
        p.FirstName,
        p.LastName,
        e.EmailAddress,
        COUNT(soh.SalesOrderID) AS TotalOrdenes,
        SUM(soh.TotalDue) AS TotalGastado,
        AVG(soh.TotalDue) AS PromedioOrden,
        MAX(soh.OrderDate) AS UltimaCompra,
        MIN(soh.OrderDate) AS PrimeraCompra
    FROM Sales.Customer c
    INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN Person.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID
    LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    WHERE c.CustomerID = @customerId
    GROUP BY c.CustomerID, p.FirstName, p.LastName, e.EmailAddress;
END
GO