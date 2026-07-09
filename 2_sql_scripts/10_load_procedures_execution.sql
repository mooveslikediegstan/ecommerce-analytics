-- ============================================================================
-- 10. EXECUTE LOADING PROCEDURES (AFTER IMPORTING DATA)
-- ============================================================================
 
EXEC [dw].[sp_Load_Dimension_Customers];
EXEC [dw].[sp_Load_Dimension_Products];
EXEC [dw].[sp_Load_Dimension_Sellers];
EXEC [dw].[sp_Load_Fact_Sales];

 
 