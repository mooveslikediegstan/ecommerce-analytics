-- ============================================================================
-- 6. POPULATE CALENDAR WITH THE NEXT 20 YEARS
-- ============================================================================
 
DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate DATE = '2030-12-31';
DECLARE @CurrentDate DATE = @StartDate;
DECLARE @Counter INT = 1;
 
WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO [dw].[Dim_Calendar] (
        date_key,
        complete_date,
        date_year,
        date_month,
        month_name,
        day_of_month,
        date_weekday,
        date_weekday_name,
        date_quarter,
        date_yearweek,
        is_weekend
    )
    VALUES (
        @Counter,
        @CurrentDate,
        YEAR(@CurrentDate),
        MONTH(@CurrentDate),
        FORMAT(@CurrentDate, 'MMMM', 'pt-BR'),
        DAY(@CurrentDate),
        DATEPART(DW, @CurrentDate),
        FORMAT(@CurrentDate, 'dddd', 'pt-BR'),
        DATEPART(QUARTER, @CurrentDate),
        DATEPART(WEEK, @CurrentDate),
        CASE WHEN DATEPART(DW, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END
    );
 
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    SET @Counter = @Counter + 1;
END
GO

PRINT 'Calendar table populated.';

-- Verify load completion
SELECT TOP 10 * FROM [dw].[Dim_Calendar] ORDER BY date_key;
GO