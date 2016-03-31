CREATE proc AddExtraUnitToProduct
	@ProductCode nvarchar(50),
	@UnitCode nvarchar(50),
	@UnitCoeff decimal(16,8),
	@MesurementUnitDescription nvarchar(50)
as
	declare @ExtraProductUnitId int
begin

	set nocount on
				
	exec @ExtraProductUnitId = InsertProductUnit @UnitCode, @UnitCoeff, @MesurementUnitDescription					
					 
	if not @ExtraProductUnitId is null
	INSERT INTO [dbo].[PRODUCT_EXTRA_UNIT]
		 ([PRODUCT_ID]
		 ,[EXTRA_UNIT_ID])
		SELECT
		 PRODUCT_ID
		 ,@ExtraProductUnitId
		FROM PRODUCT
		WHERE CODE = @ProductCode
					 
	set nocount off

end
