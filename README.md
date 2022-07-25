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

NorthwindStaging veritabanı, NorthwindDW veritabanının olası şeması dikkate alınarak oluşturuldu. Örneğin hiçbir relation'u olmayan CustomerCustomerDemo ve CustomerDemographics tabloları bu veritabanına alınmadılar. Onun dışında Northwind veritabanındaki oluşturma scriptlerinden büyük ölçüde faydalanıldı. Gerekli oluşturma scriptini [NorthwindStaging.sql](./NorthwindStaging.sql) içerisinde bulabilirsiniz.


## Northwind to NorthwindStaging için SSIS paketi oluşturulur.

Northwind veritabanındaki verileri incremental olarak NorthiwndStaging veritabanına SSIS ile taşınır. 

Yeni bir veri Northwind.Orders tablosuna geldiği zaman NorthwindStaging.Orders tablosundan çekilen Primary Key'ler içerisinde olamayan Key direk olarak Staging tablosuna yazılıyor, bu kontrol ise Lookup ile yapılıyor. Bu süreç yeni veriler içindir ve direk insert edilir. 

Update için ise Max(NorthwindStaging.Orders.ModifiedDate) değeri bulunduktan sonra bu değerden büyük olan Northwind.Orders verileri sonradan güncellenen verilerdir. Bunun için bu veriler NorthwindStaging.Orders tablosunda güncellenir.

Silinen veriler için ise NorthwindStaging.Orders tablosunda olan ve Northwind.Orders tablosunda olmayan veriler bulunur, bu veriler direk olarak silinir. 

Bu tüm süreç SSIS paketi içerisinde NorthwindgToStaging.dtsx modülü içerisinde yürütülüyor. Değişken isimlendirmeleri olabildiğince açık olduğundan bu anlatımdan sonra anlaşılacağını düşünüyorum.

## NorthwindDW oluşturulur

Bunun için ise NorthwindStaging tablosundaki oluşturma scriptleri kullanılır. fakat NorthwindStaging tablosunda relationlar oluşturulmamıştı, bu tabloda bu ilişkilerde eklenir. Northwind veri tabanımızdaki tek transaction Order yapımız olduğu için tek Fact tablomuz Order oluyor. Bunun için Fact.Orders oluşturulur. Diğer tablolar bunun etrafında Dimension tabloları olarak oluşturulur. Ayrıca Fact.Order üzerinde text olarak tutulan kargolama bilgileride ayrı bir veritabanına taşınır. Yine ilgili oluşturma scripti [NorthwindDW.sql](./NorthwindDW.sql) içerisinde bulunabilir. 

Dim.Date tablosundaki verileri oluşturmak için TSQL kod parçası ilgili sql dosyasının sonunda yer almaktadır.


## NorthwindStaging to NorthwindDW için SSIS paketi oluşturulur.
