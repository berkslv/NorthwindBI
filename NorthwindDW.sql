
USE master
GO
if exists (select * from sysdatabases where name='NorthwindDW')
		drop database NorthwindDW
GO

CREATE DATABASE NorthwindDW
GO

USE NorthwindDW
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Fact')
  BEGIN
    EXEC ('CREATE SCHEMA Fact;');
  END;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Dim')
  BEGIN
    EXEC ('CREATE SCHEMA Dim;');
  END;

DROP TABLE IF EXISTS [Fact].[Orders]
CREATE TABLE [Fact].[Orders] (
	OrderKey int UNIQUE NOT NULL,
	OrderParentKey int NOT NULL,
	CustomerKey [nchar](5) NULL,
	EmployeeKey int NULL,
	ProductKey int NULL,
	ShipKey int NULL,
	ShipperKey int NULL,
	OrderDateKey int NULL,
	RequiredDateKey int NULL,
	ShippedDateKey int NULL,
	UnitPrice money NULL,
	Quantity smallint NULL,
	Discount real NULL,
	Freight money NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (OrderKey)
); 

DROP TABLE IF EXISTS [Dim].[Customers]
CREATE TABLE [Dim].[Customers] (
	CustomerKey [nchar](5) UNIQUE NOT NULL,
	CompanyName nvarchar(40) NOT NULL,
	ContactName nvarchar(30) NULL,
	ContactTitle nvarchar(30) NULL,
	Address nvarchar(60) NULL,
	City nvarchar(15) NULL,
	Region nvarchar(15) NULL,
	PostalCode nvarchar(10) NULL,
	Country nvarchar(15) NULL,
	Phone nvarchar(24) NULL,
	Fax nvarchar(24) NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerKey)
)


DROP TABLE IF EXISTS [Dim].[Employees]
CREATE TABLE [Dim].[Employees] (
	EmployeeKey int UNIQUE NOT NULL,
	LastName nvarchar(20) NOT NULL,
	FirstName nvarchar(10) NOT NULL,
	Title nvarchar(30) NULL,
	TitleOfCourtesy nvarchar(25) NULL,
	BirthDate datetime NULL,
	HireDate datetime NULL,
	Address nvarchar(60) NULL,
	City nvarchar(15) NULL,
	Region nvarchar(15) NULL,
	PostalCode nvarchar(10) NULL,
	Country nvarchar(15) NULL,
	HomePhone nvarchar(24) NULL,
	Extension nvarchar(4) NULL,
	Notes ntext NULL,
	ReportsTo int NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Employees PRIMARY KEY CLUSTERED (EmployeeKey)
)

DROP TABLE IF EXISTS [Dim].[EmployeeTerritories]
CREATE TABLE [Dim].[EmployeeTerritories] (
	EmployeeTerritoryKey int UNIQUE NOT NULL,
	EmployeeKey int NOT NULL,
	TerritoryKey [nvarchar](20) NOT NULL,
	ModifiedDate DateTime NOT NULL,
)

DROP TABLE IF EXISTS [Dim].[Territories]
CREATE TABLE [Dim].[Territories] (
	TerritoryKey [nvarchar](20) UNIQUE NOT NULL,
	TerritoryDescription nchar(50) NOT NULL,
	RegionKey int NOT NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Territories PRIMARY KEY CLUSTERED (TerritoryKey)
)


DROP TABLE IF EXISTS [Dim].[Regions]
CREATE TABLE [Dim].[Regions] (
	RegionKey int UNIQUE NOT NULL,
	RegionDescription nchar(50) NOT NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Regions PRIMARY KEY CLUSTERED (RegionKey)
)


DROP TABLE IF EXISTS [Dim].[Products]
CREATE TABLE [Dim].[Products] (
	ProductKey int IDENTITY(1,1) NOT NULL,
	ProductAlternateKey int NOT NULL,
	SupplierKey int NULL, 
	CategoryKey int NULL,
	ProductName nvarchar(40) NOT NULL,
	QuantityPerUnit nvarchar(20) NULL,
	UnitPrice money NULL,
	UnitsInStock smallint NULL,
	UnitsOnOrder smallint NULL,
	ReorderLevel smallint NULL,
	Discontinued bit NOT NULL,
	StartDate datetime NOT NULL,
	EndDate datetime NOT NULL DEFAULT DATETIMEFROMPARTS(9999,12,31,23,59,59,0),
	Status bit NOT NULL DEFAULT 1,
	CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (ProductKey)
)


DROP TABLE IF EXISTS [Dim].[Categories]
CREATE TABLE [Dim].[Categories] (
	CategoryKey int UNIQUE NOT NULL,
	CategoryName nvarchar(15) NOT NULL,
	Description ntext NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryKey)
)

DROP TABLE IF EXISTS [Dim].[Suppliers]
CREATE TABLE [Dim].[Suppliers] (
	SupplierKey int UNIQUE NOT NULL,
	CompanyName nvarchar(40) NOT NULL,
	ContactName nvarchar(30) NULL,
	ContactTitle nvarchar(30) NULL,
	Address nvarchar(60) NULL,
	City nvarchar(15) NULL,
	Region nvarchar(15) NULL,
	PostalCode nvarchar(10) NULL,
	Country nvarchar(15) NULL,
	Phone nvarchar(24) NULL,
	Fax nvarchar(24) NULL,
	HomePage ntext NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Suppliers PRIMARY KEY CLUSTERED (SupplierKey)
)


DROP TABLE IF EXISTS [Dim].[Date]
CREATE TABLE [Dim].[Date] (
	DateKey int NOT NULL UNIQUE,
	FullDateKey Date NOT NULL,
	DayNumberOfMonth int NOT NULL,
	DayNumberOfWeek int NOT NULL,
	DayNumberOfYear int NOT NULL,
	MonthNumber int NOT NULL,
	YearNumber int NOT NULL,
	CONSTRAINT PK_Date PRIMARY KEY CLUSTERED (DateKey)
)

DROP TABLE IF EXISTS [Dim].[Ship]
CREATE TABLE [Dim].[Ship] (
	ShipKey int IDENTITY(1,1) NOT NULL,
	Name nvarchar(40) NULL,
	Address nvarchar(60) NULL,
	City nvarchar(15) NULL,
	Region nvarchar(15) NULL,
	PostalCode nvarchar(10) NULL,
	Country nvarchar(15) NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Ship PRIMARY KEY CLUSTERED (ShipKey)
)

DROP TABLE IF EXISTS [Dim].[Shippers]
CREATE TABLE [Dim].[Shippers] (
	ShipperKey int UNIQUE NOT NULL,
	CompanyName nvarchar(40) NOT NULL,
	Phone nvarchar(24) NULL,
	ModifiedDate DateTime NOT NULL,
	CONSTRAINT PK_Shippers PRIMARY KEY CLUSTERED (ShipperKey)
)
GO

------------------------------------------------------ Relationships

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerKey)
      REFERENCES [Dim].[Customers] (CustomerKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_Employees FOREIGN KEY (EmployeeKey)
      REFERENCES [Dim].[Employees] (EmployeeKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_Products FOREIGN KEY (ProductKey)
      REFERENCES [Dim].[Products] (ProductKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_Ship FOREIGN KEY (ShipKey)
      REFERENCES [Dim].[Ship] (ShipKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_Shipper FOREIGN KEY (ShipperKey)
      REFERENCES [Dim].[Shippers] (ShipperKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_OrderDate FOREIGN KEY (OrderDateKey)
      REFERENCES [Dim].[Date] (DateKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_RequiredDate FOREIGN KEY (RequiredDateKey)
      REFERENCES [Dim].[Date] (DateKey)
;

ALTER TABLE [Fact].[Orders]
   ADD CONSTRAINT FK_Orders_ShippedDate FOREIGN KEY (ShippedDateKey)
      REFERENCES [Dim].[Date] (DateKey)
;

ALTER TABLE [Dim].[EmployeeTerritories]
   ADD CONSTRAINT FK_EmployeeTerritories_Employee FOREIGN KEY (EmployeeKey)
      REFERENCES [Dim].[Employees] (EmployeeKey)
;

ALTER TABLE [Dim].[EmployeeTerritories]
   ADD CONSTRAINT FK_EmployeeTerritories_Territories FOREIGN KEY (TerritoryKey)
      REFERENCES [Dim].[Territories] (TerritoryKey)
;

ALTER TABLE [Dim].[Territories]
   ADD CONSTRAINT FK_Territories_Regions FOREIGN KEY (RegionKey)
      REFERENCES [Dim].[Regions] (RegionKey)
;

ALTER TABLE [Dim].[Products]
   ADD CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierKey)
      REFERENCES [Dim].[Suppliers] (SupplierKey)
;

ALTER TABLE [Dim].[Products]
   ADD CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryKey)
      REFERENCES [Dim].[Categories] (CategoryKey)
;


/**** Dim.Date veri ekleme ****/
DECLARE @i int;
DECLARE @MinDateFromDB int;
DECLARE @MaxDateFromDB int;
DECLARE @MinDate date;
DECLARE @MaxDate date;
DECLARE @Date date;
-- For Insert
DECLARE @DateKey int;
DECLARE @FullDateKey date;
DECLARE @DayNumberOfWeek int;
DECLARE @DayNumberOfMonth int;
DECLARE @DayNumberOfYear int;
DECLARE @MonthNumber int;
DECLARE @YearNumber int;

-- Minimum va Maximum date'ler çekilir.
SET @MaxDateFromDB = (SELECT (DATEPART(YEAR, max(RequiredDate)) + 1) FROM Northwind.dbo.Orders)
SET @MinDateFromDB = (SELECT (DATEPART(YEAR, min(OrderDate)) - 1) FROM Northwind.dbo.Orders)

-- MaxDate ile MinDate arasındaki farkın günü alınır. +- 1 ile hesaplanır. Artık yıl +1 ile hesaplanmıştır.
SET @i = ((@MaxDateFromDB - @MinDateFromDB) * 365) + 1

-- Base date oluşturulur, üzerinden işlem yapılacak.
SET @MinDate = DATEFROMPARTS(@MinDateFromDB, 1, 1)

WHILE @i > 0
BEGIN
	SET @DateKey = convert(int, replace(convert(varchar(20), @MinDate), '-',''));
	SET @FullDateKey = @MinDate;
	SET @DayNumberOfWeek = DATEPART(WEEKDAY, @MinDate);
	SET @DayNumberOfMonth = DATEPART(DAY, @MinDate);
	SET @DayNumberOfYear = DATEPART(DAYOFYEAR, @MinDate);
	SET @MonthNumber = DATEPART(MONTH, @MinDate);
	SET @YearNumber = DATEPART(YEAR, @MinDate);

	INSERT INTO NorthwindDW.Dim.Date
           (DateKey
           ,FullDateKey
           ,DayNumberOfMonth
           ,DayNumberOfWeek
           ,DayNumberOfYear
           ,MonthNumber
           ,YearNumber)
     VALUES
           (@DateKey
           ,@FullDateKey
           ,@DayNumberOfMonth
           ,@DayNumberOfWeek
           ,@DayNumberOfYear
           ,@MonthNumber
           ,@YearNumber)
		

	SET @MinDate = DATEADD(DAY, 1, @MinDate)
    SET @i = @i - 1
END

