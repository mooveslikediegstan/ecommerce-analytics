-- ============================================================================
-- 1. CREATE DATABASE AND SCHEMA
-- ============================================================================
 
USE master;
GO
 
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Ecommerce_DW')
BEGIN
    ALTER DATABASE Ecommerce_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Ecommerce_DW;
END
GO
 
CREATE DATABASE Ecommerce_DW
    COLLATE SQL_Latin1_General_CP1_CI_AS;
GO
 
USE Ecommerce_DW;
GO
 
-- Create schemas
CREATE SCHEMA [raw];-- Raw data
GO

PRINT 'Schema ''raw'' created';
GO

CREATE SCHEMA [staging];-- Processing data
GO

PRINT 'Schema ''staging'' created';
GO

CREATE SCHEMA [dw];-- Star Schema (dimensions and facts)
GO

PRINT 'Schema ''dw'' created';
GO