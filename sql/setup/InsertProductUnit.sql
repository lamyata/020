create proc InsertProductUnit
	@UnitCode nvarchar(50),
	@UnitCoeff decimal(16,8),
	@MesurementUnitDescription nvarchar(50)
as
	declare @DefaultMeasurementUnitId int
begin

	set nocount on;

	select @DefaultMeasurementUnitId = MEASUREMENT_UNIT_ID from MEASUREMENT_UNIT where [DESCRIPTION] = @MesurementUnitDescription

	INSERT INTO [dbo].[PRODUCT_UNIT]
		 ([UNIT_ID]
		 ,[COEF]
		 ,[CREATE_USER]
		 ,[CREATE_TIMESTAMP]
		 ,[UPDATE_USER]
		 ,[UPDATE_TIMESTAMP]
		 ,[DEFAULT_MEASUREMENT_UNIT_ID])
		SELECT
		 UNIT_ID
		 ,@UnitCoeff
		 ,'script'
		 ,getdate()
		 ,'script'
		 ,getdate()
		 ,@DefaultMeasurementUnitId
		FROM
			UNIT u
		WHERE
			u.CODE = @UnitCode

	return SCOPE_IDENTITY();

	set nocount off;

end
