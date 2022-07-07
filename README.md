# Northwind BI

Bu repo, Northwind DB kullanılarak geliştirilien Business Intelligence çözümlerini içerir. Araç seti olarak Microsoftun araçları olan SQL Server, SSIS, SSAS, SSRS ve Power BI kullanılır.

# Adımlar

1. Northiwnd veritabanı oluşturulur.
2. NorthiwndStaging veritabanı Northwind veritabanı şemasının neredeyse birebir aynısı olarak oluşturulur. 
3. Northwind veritabanındaki verileri incremental olarak NorthiwndStaging veritabanına SSIS ile taşınır
   - many-to-many ilişkiler için Northwind veritabanında PK olmadığı için güncelliğin takibi çok zorlaşıyor. Bu kötü implemantasyon sebebi ile m-m tablolar insert edilmeden önce truncate edilir.
4. NorthwindDW isminde veri ambarımızı oluşturacak veritabanı oluşturulur.

