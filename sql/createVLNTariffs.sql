INSERT INTO [dbo].[SERVICE_ACCOUNT]
           ([ACCOUNT]
           ,[DESCRIPTION]
           ,[INTERNAL_COMPANY_ID]
           ,[DIRECTION]
           ,[CREATE_USER]
           ,[CREATE_TIMESTAMP]
           ,[UPDATE_USER]
           ,[UPDATE_TIMESTAMP])
     SELECT
           '700007' -- ACCOUNT, nvarchar(250)
           ,'Containerhandling' -- DESCRIPTION, nvarchar(250)
           ,c.COMPANYNR -- INTERNAL_COMPANY_ID
           ,1 -- DIRECTION, int
           ,'sys'
           ,getdate()
           ,'sys'
           ,getdate()
	FROM COMPANY c
		WHERE c.CODE = 'IC_AXL'

go

create proc CreateTariffInternal
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@MeasurementUnitCode  nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@CustomerCode nvarchar(50),
	@ServiceAccount nvarchar(50),
	@TariffFileReference nvarchar(250)
as
	declare @OperationId int
	declare @TariffId int
	declare @MeasurementUnitId int
begin
	set nocount on

	select @OperationId = [OPERATION_ID] from [OPERATION] where [CODE] = @OperationCode;
	if (IsNull(@MeasurementUnitCode,'')!='')
		select @MeasurementUnitId = [UNIT_ID] from [UNIT] where [CODE] = @MeasurementUnitCode;

	INSERT INTO [dbo].[TARIFF_INFO]
			([CODE]
			,[DESCRIPTION]
			,[TARIFF]
			,[UNIT_ID]
			,[MEASUREMENT_UNIT_ID]
			,[CURRENCY_ID]
			,[SERVICE_ACCOUNT]
			,[CREATE_USER]
			,[CREATE_TIMESTAMP]
			,[UPDATE_USER]
			,[UPDATE_TIMESTAMP])
		SELECT
			@TariffInfoCode
			,@TariffInfoDescr
			,@TariffInfoTariff
			,UNIT_ID
			,@MeasurementUnitId
			,CURRENCY_ID
			,@ServiceAccount
			,'sys'
			,getdate()
			,'sys'
			,getdate()
	FROM
		UNIT u, CURRENCY c
		WHERE u.CODE = @UnitCode AND c.CODE = @CurrencyCode;

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
			   ,'1-JAN-2050' -- PERIOD_TO
			   ,'sys'
			   ,getdate()
			   ,'sys'
			   ,getdate()
	FROM TARIFF_INFO ti, TARIFF_FILE tf
	WHERE ti.CODE = @TariffInfoCode AND tf.REFERENCE = @TariffFileReference;

	select @TariffId = SCOPE_IDENTITY();

	if @CustomerCode is not null
		INSERT INTO [dbo].[TARIFF_CUSTOMER]
			([TARIFF_ID]
			,[COMPANY_ID])
		SELECT
			@TariffId,
			COMPANYNR
		FROM COMPANY WHERE CODE = @CustomerCode;
	
	set nocount off;
	
	return @TariffId;
	
end
go

create proc CreateTariff
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@MeasurementUnitCode  nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@OperationType nvarchar(10),
	@CustomerCode nvarchar(50),
	@ServiceAccount nvarchar(50),
	@TariffFileReference nvarchar(250),
	@ProductCode nvarchar(50),
	@TransportTypeCode nvarchar(10)
as
	declare @TariffId int
	declare @StockInfoConfigId int
	declare @StockInfoId int
	declare @InternalCompanyId int
	declare @TransportTypeId int
begin
	exec @TariffId = CreateTariffInternal @TariffInfoCode, @TariffInfoDescr, @TariffInfoTariff, @UnitCode, @MeasurementUnitCode, @CurrencyCode,
		@OperationCode, @CustomerCode, @ServiceAccount, @TariffFileReference

	if @ProductCode is not null
	begin
		select @InternalCompanyId = INTERNAL_COMPANY_ID from TARIFF_FILE where REFERENCE = @TariffFileReference

		INSERT INTO [dbo].[STOCK_INFO_CONFIG]
				   ([INTERNAL_COMPANY_ID]
				   ,[PRODUCT_ID]
				   ,[STATUS]
				   ,[CREATE_USER]
				   ,[CREATE_TIMESTAMP]
				   ,[UPDATE_USER]
				   ,[UPDATE_TIMESTAMP])
			 SELECT
				   @InternalCompanyId 
				   ,PRODUCT_ID
				   ,0 -- STATUS (0 available, 1 blocked)
				   ,'sys'
				   ,GETDATE()
				   ,'sys'
				   ,GETDATE()
			FROM PRODUCT
			WHERE CODE = @ProductCode

		select @StockInfoConfigId = SCOPE_IDENTITY();

		INSERT INTO [dbo].[STOCK_INFO]
			   ([STOCK_INFO_CONFIG_ID]
			   ,[CREATE_USER]
			   ,[CREATE_TIMESTAMP]
			   ,[UPDATE_USER]
			   ,[UPDATE_TIMESTAMP])
		 VALUES
			   (@StockInfoConfigId
			   ,'sys'
			   ,GETDATE()
			   ,'sys'
			   ,GETDATE())

		select @StockInfoId = SCOPE_IDENTITY();
	end

	if CHARINDEX(N'D', @OperationType) > 0
	begin
		INSERT INTO [dbo].[DISCHARGING_TARIFF]
			 ([DISCHARGING_TARIFF_ID]
			 ,[STOCK_INFO_ID]
			 ,[CREATE_USER]
			 ,[CREATE_TIMESTAMP]
			 ,[UPDATE_USER]
			 ,[UPDATE_TIMESTAMP])
		 VALUES
			 (@TariffId
			 ,@StockInfoId
			 ,'sys'
			 ,getdate()
			 ,'sys'
			 ,getdate())

	    if (@TransportTypeCode is not null)
		begin
			select @TransportTypeId = TRANSPORT_TYPE_ID from TRANSPORT_TYPE
				where CODE = @TransportTypeCode and INTERNAL_COMPANY_NR = @InternalCompanyId
			if (@TransportTypeId is null)
				select @TransportTypeId = TRANSPORT_TYPE_ID from TRANSPORT_TYPE
				where CODE = @TransportTypeCode and INTERNAL_COMPANY_NR is null
			if (@TransportTypeId is not null)
				INSERT INTO [dbo].[DISCHARGING_TARIFF_TRANSPORT_TYPE]
					   ([DISCHARGING_TARIFF_ID]
					   ,[TRANSPORT_TYPE_ID])
				VALUES (@TariffId
					   ,@TransportTypeId)
		end
	end
		 
	if CHARINDEX(N'L', @OperationType) > 0
	begin
		INSERT INTO [dbo].[LOADING_TARIFF]
			 ([LOADING_TARIFF_ID]
			 ,[STOCK_INFO_ID]
			 ,[CREATE_USER]
			 ,[CREATE_TIMESTAMP]
			 ,[UPDATE_USER]
			 ,[UPDATE_TIMESTAMP])
		 VALUES
			 (@TariffId
			 ,@StockInfoId
			 ,'sys'
			 ,getdate()
			 ,'sys'
			 ,getdate())

	    if (@TransportTypeCode is not null)
		begin
			select @TransportTypeId = TRANSPORT_TYPE_ID from TRANSPORT_TYPE
				where CODE = @TransportTypeCode and INTERNAL_COMPANY_NR = @InternalCompanyId
			if (@TransportTypeId is null)
				select @TransportTypeId = TRANSPORT_TYPE_ID from TRANSPORT_TYPE
				where CODE = @TransportTypeCode and INTERNAL_COMPANY_NR is null
			if (@TransportTypeId is not null)
				INSERT INTO [dbo].[LOADING_TARIFF_TRANSPORT_TYPE]
					   ([LOADING_TARIFF_ID]
					   ,[TRANSPORT_TYPE_ID])
				VALUES (@TariffId
					   ,@TransportTypeId)
		end
	end

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

	--if CHARINDEX(N'A', @OperationType) > 0
	--	INSERT INTO [dbo].[ADDITIONAL_TARIFF]
	--				 ([ADDITIONAL_TARIFF_ID]
	--				 ,[CREATE_USER]
	--				 ,[CREATE_TIMESTAMP]
	--				 ,[UPDATE_USER]
	--				 ,[UPDATE_TIMESTAMP])
	--		 VALUES
	--				 (@TariffId
	--				 ,'sys'
	--				 ,getdate()
	--				 ,'sys'
	--				 ,getdate())		 
end
go

exec CreateTariff
	@TariffInfoCode = 'DCYB',
	@TariffInfoDescr = 'Discharging Container in Yard',
	@TariffInfoTariff = 15,
	@UnitCode = 'PCS',
	@MeasurementUnitCode  = null,
	@CurrencyCode = 'EUR',
	@OperationCode = '2C01',
	@OperationType = 'D',
	@CustomerCode = null,
	@ServiceAccount = '700007',
	@TariffFileReference = 'Discharging',
	@ProductCode = 'CNT',
	@TransportTypeCode = 'BACO'

exec CreateTariff
	@TariffInfoCode = 'DCYT',
	@TariffInfoDescr = 'Discharging Container in Yard',
	@TariffInfoTariff = 15,
	@UnitCode = 'PCS',
	@MeasurementUnitCode  = null,
	@CurrencyCode = 'EUR',
	@OperationCode = '2C01',
	@OperationType = 'D',
	@CustomerCode = null,
	@ServiceAccount = '700007',
	@TariffFileReference = 'Discharging',
	@ProductCode = 'CNT',
	@TransportTypeCode = 'TRCO'

exec CreateTariff
	@TariffInfoCode = 'LCYB',
	@TariffInfoDescr = 'Loading Container from Yard',
	@TariffInfoTariff = 15,
	@UnitCode = 'PCS',
	@MeasurementUnitCode  = null,
	@CurrencyCode = 'EUR',
	@OperationCode = '3C01',
	@OperationType = 'L',
	@CustomerCode = null,
	@ServiceAccount = '700007',
	@TariffFileReference = 'Loading',
	@ProductCode = 'CNT',
	@TransportTypeCode = 'BACO'

exec CreateTariff
	@TariffInfoCode = 'LCYT',
	@TariffInfoDescr = 'Loading Container from Yard',
	@TariffInfoTariff = 15,
	@UnitCode = 'PCS',
	@MeasurementUnitCode  = null,
	@CurrencyCode = 'EUR',
	@OperationCode = '3C01',
	@OperationType = 'L',
	@CustomerCode = null,
	@ServiceAccount = '700007',
	@TariffFileReference = 'Loading',
	@ProductCode = 'CNT',
	@TransportTypeCode = 'TRCO'
	
drop proc CreateTariff
drop proc CreateTariffInternal