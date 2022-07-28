# Northwind BI

Bu repo, Northwind DB kullanılarak geliştirilien Business Intelligence çözümlerini içerir. Araç seti olarak Microsoftun araçları olan SQL Server, SSIS, SSAS, SSRS ve Power BI kullanılır.

# Süreç

## Northiwnd veritabanı oluşturulur.

Northwind veritabanının aslında UpdatedDate gibi bir alan yok, fakat SSIS üzerinden güncellenen verileri kontrol etmek için bunun gibi bir alana ihtiyaç var. Bu sebeple DB oluşturma scripti olan [Northwind.sql](./Northwind.sql) üzerinde asıl Northwind scripti dışında bazı eklemeler yaptım.

İlk olarak Her tablo için UpdatedDate (DateTime) alanı ekledim, daha sonra tablo üzerinde güncelleme yapıldığında otomatik olarak bu alanı güncellemesi için Trigger oluşturdum. Bir tablo için örnek aşağıdaki gibidir.

```sql
ALTER TABLE Products
ADD "ModifiedDate" DateTime NOT NULL DEFAULT GETDATE()
GO

CREATE TRIGGER ProductsAfterUpdateSetModifiedDate ON Products
   FOR UPDATE
   AS
   BEGIN
      UPDATE Products
      SET dbo.Products.ModifiedDate = GETDATE()
      FROM inserted
      WHERE Products.ProductID = inserted.ProductID
   END
GO
```

Ek olarak Primary key içermeyen Order Details ve Employee Territories tablolarına PK eklenir, bunu SSIS içerisinde incremental load yapabilmek için ekliyoruz.

## NorthwindStaging veritabanı oluşturulur.

NorthwindStaging veritabanı, Olası NorthwindDW veritabanının olası şeması dikkate alınarak oluşturuldu. Northwind veritabanındaki oluşturma scriptlerinden büyük ölçüde faydalanıldı. Gerekli oluşturma scriptini [NorthwindStaging.sql](./NorthwindStaging.sql) içerisinde bulabilirsiniz.

## Northwind to NorthwindStaging için SSIS paketi oluşturulur.

Northwind veritabanındaki verileri incremental olarak NorthiwndStaging veritabanına SSIS ile taşınır.

Yeni bir veri Northwind.Orders tablosuna geldiği zaman NorthwindStaging.Orders tablosundan çekilen Primary Key'ler içerisinde olamayan Key direk olarak Staging tablosuna yazılıyor, bu kontrol ise Lookup ile yapılıyor. Bu süreç yeni veriler içindir ve direk insert edilir.

Update için ise Max(NorthwindStaging.Orders.ModifiedDate) değeri bulunduktan sonra bu değerden büyük olan Northwind.Orders verileri sonradan güncellenen verilerdir. Bunun için bu veriler NorthwindStaging.Orders tablosunda güncellenir.

Silinen veriler için ise NorthwindStaging.Orders tablosunda olan ve Northwind.Orders tablosunda olmayan veriler bulunur, bu veriler direk olarak silinir.

Bu tüm süreç SSIS paketi içerisinde NorthwindgToStaging.dtsx modülü içerisinde yürütülüyor. Değişken isimlendirmeleri olabildiğince açık olduğundan bu anlatımdan sonra anlaşılacağını düşünüyorum.

## NorthwindDW oluşturulur

Bunun için ise NorthwindStaging tablosundaki oluşturma scriptleri kullanılır. Northwind veri tabanımızdaki tek transaction Order yapımız olduğu için tek Fact tablomuz Order oluyor. Bunun için Fact.Orders oluşturulur. Diğer tablolar bunun etrafında Dimension tabloları olarak oluşturulur. Ayrıca Fact.Order üzerinde text olarak tutulan kargolama bilgileride ayrı bir veritabanına taşınır. Yine ilgili oluşturma scripti [NorthwindDW.sql](./NorthwindDW.sql) içerisinde bulunabilir.

Dim.Date tablosundaki verileri oluşturmak için TSQL kod parçası ilgili sql dosyasının sonunda yer almaktadır.

SCD yapımızı ele almak için Dim tablolarına `StartDate`, `EndDate` ve `Status` sutünları eklenir, ayrıca silinme durumunu ele almak için staging tablosunda olduğu gibi `IsDeleted` alanı eklenir, ayrıca silinen veriler için `EndDate` alanı silinme tarihi olarak işaretlenerek `EndDate` alanı silinme tarihiyle doldurulur.

## NorthwindStaging to NorthwindDW için SSIS paketi oluşturulur.

# SCD

- [x] Insert

Yeni eklenen veriler ilk önce ODS katmanına yazılır, ODS katmanından DW katmanına aktarılır.

- [x] Update

Güncel veriler için ilk olarak verinin güncel hali için yeni bir insert yapılır, bu eklenen kayıtta `StartDate`, bir önceki kayıtta `EndDate`, ODS katmanındaki `ModifiedDate` ile eşleştirilir. Eski kayıt için status 0 yapılır, yeni kayıtta status 1 olur, varsayılandır.

| ProductKey | ProductAlternateKey | UnitPrice | StartDate               | EndDate                 | Status |
| ---------- | ------------------- | --------- | ----------------------- | ----------------------- | ------ |
| 1          | 21                  | 2         | 2022-07-26 10:26:00.000 | 2022-07-26 10:30:00.000 | 0      |
| 2          | 21                  | 5         | 2022-07-26 10:30:00.000 | 2022-07-26 10:50:00.000 | 0      |
| 3          | 21                  | 10        | 2022-07-26 10:50:00.000 | 9999-12-30 23:59:00.000 | 1      |

- [ ] Delete

Silinme tarihi tutulmadığı için, silinme durumunda `EndDate` alanı `GETDATE()` ile doldurulur, status 0 yapılır.

| ProductKey | ProductAlternateKey | UnitPrice | StartDate               | EndDate                 | Status |
| ---------- | ------------------- | --------- | ----------------------- | ----------------------- | ------ |
| 1          | 21                  | 5         | 2022-07-26 10:26:00.000 | 2022-07-26 10:30:00.000 | 0      |
| 2          | 21                  | 10        | 2022-07-26 10:30:00.000 | 2022-07-26 10:45:00.000 | 0      |


Test

```sql
SELECT * FROM [NorthwindDW].[Dim].[Products] ORDER BY ProductKey DESC
select * from [NorthwindODS].[dbo].[Products] ORDER BY ProductID DESC
select * from [Northwind].[dbo].[Products] ORDER BY ProductID DESC

  SELECT TOP 1  * from [NorthwindDW].[Dim].[Products]
  WHERE [ProductAlternateKey] = 82
  ORDER BY [StartDate] DESC 

INSERT INTO [Northwind].[dbo].[Products]
           ([ProductName]
           ,[SupplierID]
           ,[CategoryID]
           ,[QuantityPerUnit]
           ,[UnitPrice]
           ,[UnitsInStock]
           ,[Discontinued]
           )
     VALUES
           ('Dertom'
			,1
			,1
			,'10 boxes x 20 bags'
			,15
			,50
           ,0
           )
GO


UPDATE [Northwind].[dbo].[Products]
   SET [ProductName] = 'Terbaz'
 WHERE ProductID = 82

 DELETE FROM [Northwind].[dbo].[Products]
 WHERE ProductID = 82

 DELETE FROM [NorthwindODS].[dbo].[Products]
 WHERE ProductID IN (80)
 
DELETE FROM [NorthwindDW].[Dim].[Products]
 WHERE ProductAlternateKey IN (82)
```

DECLARE @LatestDate DATETIME

SELECT @LatestDate = (SELECT MAX(ModifiedDate) FROM NorthwindODS.dbo.[Employees])

IF @LatestDate IS NOT NULL
	SELECT od.OrderDetailID AS OrderKey
		,[CustomerID] AS CustomerKey
		,[EmployeeID] AS EmployeeKey
		,[ProductID] AS ProductKey
		,(SELECT DateKey FROM NorthwindDW.Dim.Date d WHERE CONVERT(DATE, o.OrderDate) = d.FullDateKey) AS OrderDateKey
		,(SELECT DateKey FROM NorthwindDW.Dim.Date d WHERE CONVERT(DATE, o.RequiredDate) = d.FullDateKey) AS RequiredDateKey
		,(SELECT DateKey FROM NorthwindDW.Dim.Date d WHERE CONVERT(DATE, o.ShippedDate) = d.FullDateKey) AS ShippedDateKey
		,[ShipVia]
		,[ShipName]
		,[ShipAddress]
		,[ShipCity]
		,[ShipRegion]
		,[ShipPostalCode]
		,[ShipCountry]
		,[UnitPrice]
		,[Quantity]
		,[Discount]
		,[Freight]
		,(Quantity * UnitPrice) - (Discount * (Quantity * UnitPrice)) AS Total
		,od.[ModifiedDate]
	FROM NorthwindODS.dbo.Orders o
	LEFT JOIN NorthwindODS.dbo.[Order Details] od ON o.OrderID = od.OrderID
	WHERE od.ModifiedDate > @LatestDate
ELSE 
	SELECT od.OrderDetailID AS OrderKey
		,[CustomerID] AS CustomerKey
		,[EmployeeID] AS EmployeeKey
		,[ProductID] AS ProductKey
		,(SELECT DateKey FROM NorthwindDW.Dim.Date d WHERE CONVERT(DATE, o.OrderDate) = d.FullDateKey) AS OrderDateKey
		,(SELECT DateKey FROM NorthwindDW.Dim.Date d WHERE CONVERT(DATE, o.RequiredDate) = d.FullDateKey) AS RequiredDateKey
		,(SELECT DateKey FROM NorthwindDW.Dim.Date d WHERE CONVERT(DATE, o.ShippedDate) = d.FullDateKey) AS ShippedDateKey
		,[ShipVia]
		,[ShipName]
		,[ShipAddress]
		,[ShipCity]
		,[ShipRegion]
		,[ShipPostalCode]
		,[ShipCountry]
		,[UnitPrice]
		,[Quantity]
		,[Discount]
		,[Freight]
		,(Quantity * UnitPrice) - (Discount * (Quantity * UnitPrice)) AS Total
		,od.[ModifiedDate]
	FROM NorthwindODS.dbo.Orders o
	LEFT JOIN NorthwindODS.dbo.[Order Details] od ON o.OrderID = od.OrderID
	
[OLE DB Destination [63]] Error: SSIS Error Code DTS_E_OLEDBERROR.  An OLE DB error has occurred. Error code: 0x80004005.
An OLE DB record is available.  Source: "Microsoft SQL Server Native Client 11.0"  Hresult: 0x80004005  Description: "The statement has been terminated.".
An OLE DB record is available.  Source: "Microsoft SQL Server Native Client 11.0"  Hresult: 0x80004005  Description: "The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Orders_Customers". The conflict occurred in database "NorthwindDW", table "Dim.Customers", column 'CustomerKey'.".
