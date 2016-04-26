create proc #CreateTariffInternal
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@CustomerCode nvarchar(50),
	@TariffInfoId int output
as
	declare @OperationId int,
	declare @TariffId int
begin
	set nocount on

	select @OperationId = OPERATION_ID from OPERATION where CODE = @OperationCode

	INSERT INTO [dbo].[TARIFF_INFO]
			([CODE]
			,[DESCRIPTION]
			,[TARIFF]
			,[UNIT_ID]
			,[MEASUREMENT_UNIT_ID]
			,[CURRENCY_ID]
			--,[SERVICE_ACCOUNT]
			,[CREATE_USER]
			,[CREATE_TIMESTAMP]
			,[UPDATE_USER]
			,[UPDATE_TIMESTAMP])
		SELECT
			@TariffInfoCode
			,@TariffInfoDescr
			,@TariffInfoTariff
			,UNIT_ID
			,NULL --MEASUREMENT_UNIT_ID
			,CURRENCY_ID
			--,SERVICE_ACCOUNT nvarchar(50)
			,'sys'
			,getdate()
			,'sys'
			,getdate()
	FROM
		UNIT u, CURRENCY c
		WHERE u.CODE = @UnitCode AND c.CODE = @CurrencyCode

	select @TariffInfoId = SCOPE_IDENTITY();
		
	INSERT INTO [dbo].[TARIFF]
			   ([TARIFF_FILE_ID]
			   ,[OPERATION_ID]
			   ,[TARIFF_INFO_ID]
			   ,[STATUS]
			   ,[PERIOD_FROM]
			   ,[PERIOD_TO]
			   ,[CREATE_USER]
			   ,[CREATE_TIMESTAMP]
			   ,[UPDATE_USER]
			   ,[UPDATE_TIMESTAMP])
		 SELECT
			   TARIFF_FILE_ID
			   ,@OperationId
			   ,TARIFF_INFO_ID
			   ,0
			   ,'1-JAN-2016' -- PERIOD_FROM
			   ,'1-JAN-2022' -- PERIOD_TO
			   ,'sys'
			   ,getdate()
			   ,'sys'
			   ,getdate()
	FROM TARIFF_INFO ti, TARIFF_FILE tf
	WHERE ti.CODE = @TariffInfoCode AND tf.REFERENCE = 'CRI_TARIFF'

	select @TariffId = SCOPE_IDENTITY();

	if @CustomerCode is not null
		INSERT INTO [dbo].[TARIFF_CUSTMER]
			([TARIFF_ID]
			,[COMPANY_ID])
		SELECT
			@TariffId,
			COMPANYNR
		FROM COMPANY WHERE CODE = @CustomerCode
	
	set nocount off
	
	return @TariffId
	
end
go

create proc #AddRange
	declare @TariffInfoId int,
	declare @Tariff decimal (18,3),
	declare @RangeFrom decimal (38,3),
	declare @RangeTo decimal (38,8),
	declare @UnitCode nvarchar(50),
	declare @MeasurementUnitCode  nvarchar(50)
as
	declare @UnitId int
	declare @MeasurementUnitId int
	declare @TariffRangeId int
begin

	select @UnitId = UNIT_ID from UNIT where CODE = @UnitCode
	select @MeasurementUnitId = UNIT_ID from UNIT where CODE = @MeasurementUnitCode

	INSERT INTO [dbo].[TARIFF_RANGE]
		 ([TARIFF]
		 ,[RANGE_FROM]
		 ,[RANGE_TO]
		 ,[UNIT_ID]
		 ,[MEASUREMENT_UNIT_ID]
		 ,[CREATE_USER]
		 ,[CREATE_TIMESTAMP]
		 ,[UPDATE_USER]
		 ,[UPDATE_TIMESTAMP])
	 VALUES
		 (@Tariff
		 ,@RangeFrom
		 ,@RangeTo
		 ,@UnitId
		 ,@MeasurementUnitId
		 ,'sys'
		 ,getdate()
		 ,'sys'
		 ,getdate())		
		 
	SELECT @TariffRangeId = SCOPE_IDENTITY();
					 
	INSERT INTO [dbo].[TARIFF_INFO_RANGE]
		 ([TARIFF_INFO_ID]
		 ,[TARIFF_RANGE_ID])
	 VALUES
		 (@TariffInfoId
		 ,@TariffRangeId)					 

end	
go

create proc #CreateTariff
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@OperationType nvarchar(10),
	@TariffInfoId int output
as
	declare @TariffId int,
begin
	exec @TariffId = #CreateTariffInternal @TariffInfoCode, @TariffInfoDescr, @TariffInfoTariff, @UnitCode, @CurrencyCode, @OperationCode, @TariffInfoId output
	if CHARINDEX(N'D', @OperationType) > 0
		INSERT INTO [dbo].[DISCHARGING_TARIFF]
			 ([DISCHARGING_TARIFF_ID]
			 ,[STOCK_INFO_ID]
			 ,[CREATE_USER]
			 ,[CREATE_TIMESTAMP]
			 ,[UPDATE_USER]
			 ,[UPDATE_TIMESTAMP])
		 VALUES
			 (@TariffId
			 ,NULL --STOCK_INFO_ID
			 ,'sys'
			 ,getdate()
			 ,'sys'
			 ,getdate())
		 
	if CHARINDEX(N'L', @OperationType) > 0
		INSERT INTO [dbo].[LOADING_TARIFF]
			 ([LOADING_TARIFF_ID]
			 ,[STOCK_INFO_ID]
			 ,[CREATE_USER]
			 ,[CREATE_TIMESTAMP]
			 ,[UPDATE_USER]
			 ,[UPDATE_TIMESTAMP])
		 VALUES
			 (@TariffId
			 ,NULL --STOCK_INFO_ID
			 ,'sys'
			 ,getdate()
			 ,'sys'
			 ,getdate())

	if CHARINDEX(N'V', @OperationType) > 0
		INSERT INTO [dbo].[VAS_TARIFF]
					 ([VAS_TARIFF_ID]
					 ,[CREATE_USER]
					 ,[CREATE_TIMESTAMP]
					 ,[UPDATE_USER]
					 ,[UPDATE_TIMESTAMP])
			 VALUES
					 (@TariffId
					 ,'sys'
					 ,getdate()
					 ,'sys'
					 ,getdate())
					 
	if CHARINDEX(N'S', @OperationType) > 0
		INSERT INTO [dbo].[STOCK_CHANGE_TARIFF]
					 ([STOCK_CHANGE_TARIFF_ID]
					 ,[CREATE_USER]
					 ,[CREATE_TIMESTAMP]
					 ,[UPDATE_USER]
					 ,[UPDATE_TIMESTAMP])
			 VALUES
					 (@TariffId
					 ,'sys'
					 ,getdate()
					 ,'sys'
					 ,getdate())

	if CHARINDEX(N'A', @OperationType) > 0
		INSERT INTO [dbo].[ADDITIONAL_TARIFF]
					 ([ADDITIONAL_TARIFF_ID]
					 ,[CREATE_USER]
					 ,[CREATE_TIMESTAMP]
					 ,[UPDATE_USER]
					 ,[UPDATE_TIMESTAMP])
			 VALUES
					 (@TariffId
					 ,'sys'
					 ,getdate()
					 ,'sys'
					 ,getdate())		 
end
go

declare @TariffInfoId int;
exec #CreateTariff 'TSD2WH', 'Discharging into warehouse', 0, 'PIECE', 'EUR', 'DISCH_OPER_CODE', 'D', @TariffInfoId output
exec #AddRange  @TariffInfoId, 10, null, 3000, 'KG', null
exec #AddRange  @TariffInfoId, 50, 3000.01, 8000, 'KG', null
exec #AddRange  @TariffInfoId, 75, 8000.01, null, 'KG', null

