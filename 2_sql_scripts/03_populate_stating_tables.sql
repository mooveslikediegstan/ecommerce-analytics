USE Ecommerce_DW;
GO

DECLARE @filepath VARCHAR(500) = 'C:\Users\Administrador\OneDrive\Programming\08_DataAnalystPath\Projeto_Ecommerce_Vendas\1_raw_data\'; --change it to your own
DECLARE @sql     NVARCHAR(MAX);

-- Orders
SET @sql = N'BULK INSERT [staging].[stg_orders] FROM ''' + @filepath + 'olist_orders_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Orders loaded';

-- Customers
SET @sql = N'BULK INSERT [staging].[stg_customers] FROM ''' + @filepath + 'olist_customers_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Customers loaded';

-- Products
SET @sql = N'BULK INSERT [staging].[stg_products] FROM ''' + @filepath + 'olist_products_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Products loaded';

-- Order Items
SET @sql = N'BULK INSERT [staging].[stg_order_items] FROM ''' + @filepath + 'olist_order_items_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Order Items loaded';

-- Payments
SET @sql = N'BULK INSERT [staging].[stg_payments] FROM ''' + @filepath + 'olist_order_payments_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Payments loaded';

-- Reviews
SET @sql = N'BULK INSERT [staging].[stg_reviews] FROM ''' + @filepath + 'olist_order_reviews_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', FORMAT = ''CSV'', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Reviews loaded';

-- Sellers
SET @sql = N'BULK INSERT [staging].[stg_sellers] FROM ''' + @filepath + 'olist_sellers_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', FORMAT = ''CSV'', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Sellers loaded';

-- Geolocation
SET @sql = N'BULK INSERT [staging].[geolocation] FROM ''' + @filepath + 'olist_geolocation_dataset.csv'' WITH (FIRSTROW=2, FIELDTERMINATOR='','', FORMAT = ''CSV'', ROWTERMINATOR=''0x0a'', CODEPAGE=''65001'')';
EXEC sp_executesql @sql;
PRINT 'Geolocation loaded';

PRINT '\nAll tables loaded!';