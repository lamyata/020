INSERT INTO [dbo].[TARIFF_FILE]
	([DESCRIPTION]
	,[REFERENCE]
	,[STATUS]
	,[INTERNAL_COMPANY_ID]
	,[OPERATION_TYPE_ID]
	,[CREATE_USER]
	,[CREATE_TIMESTAMP]
	,[UPDATE_USER]
	,[UPDATE_TIMESTAMP])
SELECT TOP 1
	'CRI Tariffs'
	,'CRI_TARIFF'
	,0
	,COMPANYNR
	,NULL -- OPERATION_TYPE_ID
	,'sys'
	,getdate()
	,'sys'
	,getdate()
FROM COMPANY c
WHERE c.CODE = 'CRI'
go

create proc #CreateTariff
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50)
as
	declare @OperationId int
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
	FROM TARIFF_INFO ti, TARIFF_FILE tf, OPERATION op
	WHERE ti.CODE = @TariffInfoCode AND tf.REFERENCE = 'CRI_TARIFF'

	return SCOPE_IDENTITY();
end

go

declare @TariffId int
exec @TariffId = #CreateTariff 'DCTR2WH', 'Discharging into warehouse (ex-truck/container)', 3.99, 'PALLET', 'EUR', 'DISCH_OPER_CODE'
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
				 
exec @TariffId = #CreateTariff 'LDEXWH2TR', 'Loading ex-warehouse (into truck/container)', 3.39, 'PALLET', 'EUR', 'LOAD_OPER_CODE'
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
				 
exec @TariffId = #CreateTariff 'SKUCHANGEAFTER72HRS', 'VAS - SKU Change (after 72 hrs or more)', 5.5, 'PALLET', 'EUR', 'VAS_OPER_CODE'
	INSERT INTO [dbo].[VAS_TARIFF]
			   ([VAS_TARIFF_ID]
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

exec @TariffId = #CreateTariff 'WTHRZBB', 'Weatherizing Big Bags', 4.9, 'BIGBAG', 'EUR', 'ADDITIONAL_OPER_CODE'
	INSERT INTO [dbo].[ADDITIONAL_TARIFF]
			   ([ADDITIONAL_TARIFF_ID]
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
				 