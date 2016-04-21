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
WHERE c.CODE = 'IC_VMHZP'
go

create proc #CreateTariffInternal
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
	FROM TARIFF_INFO ti, TARIFF_FILE tf
	WHERE ti.CODE = @TariffInfoCode AND tf.REFERENCE = 'CRI_TARIFF'

	set nocount off
	
	return SCOPE_IDENTITY();
end
go

create proc #CreateTariff
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@OperationType nvarchar(10)
as
	declare @TariffId int
begin
	exec @TariffId = #CreateTariffInternal @TariffInfoCode, @TariffInfoDescr, @TariffInfoTariff, @UnitCode, @CurrencyCode, @OperationCode
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

exec CreateOperation 'VRBB2BB','IC_VMHZP','VAS','Repacking Big bag to Big bag',' Repacking Big bag to Big bag'
exec CreateOperation 'VRBB2B025','IC_VMHZP','VAS','Repacking Big bag to 25kg bag','Repacking Big bag to 25kg bag'
exec CreateOperation 'VRB2DRUM','IC_VMHZP','VAS','Repacking bag to drum','Repacking bag to drum'
exec CreateOperation 'VRDRUM2B','IC_VMHZP','VAS','Repacking drum to bag','Repacking drum to bag'
exec CreateOperation 'VRB2IBC','IC_VMHZP','VAS','Repacking bag to IBC','Repacking bag to IBC'
exec CreateOperation 'VRIBC2B','IC_VMHZP','VAS','Repacking IBC to bag','Repacking IBC to bag'

insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s where o.CODE = 'VRBB2BB' and s.CODE = '24'
insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s where o.CODE = 'VRBB2B025' and s.CODE = '24'
insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s where o.CODE = 'VRB2DRUM' and s.CODE = '24'
insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s where o.CODE = 'VRDRUM2B' and s.CODE = '24'
insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s where o.CODE = 'VRB2IBC' and s.CODE = '24'
insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s where o.CODE = 'VRIBC2B' and s.CODE = '24'

insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRBB2BB'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRBB2B025'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRB2DRUM'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRDRUM2B'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRB2IBC'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRIBC2B'

exec #CreateTariff 'TVRBB2BB', 'Repacking Big bag to Big bag', 19, 'TON', 'EUR', 'VRBB2BB', 'V'
exec #CreateTariff 'TVRBB2B025', 'Repacking Big bag to 25kg bag', 35, 'TON', 'EUR', 'VRBB2B025', 'V'
exec #CreateTariff 'TVRB2DRUM', 'Repacking bag to drum', 23, 'TON', 'EUR', 'VRB2DRUM', 'V'
exec #CreateTariff 'TVRDRUM2B', 'Repacking drum to bag', 43, 'TON', 'EUR', 'VRDRUM2B', 'V'
exec #CreateTariff 'TVRB2IBC', 'Repacking bag to IBC', 19, 'TON', 'EUR', 'VRB2IBC', 'V'
exec #CreateTariff 'TVRIBC2B', 'Repacking IBC to bag', 43, 'TON', 'EUR', 'VRIBC2B', 'V'

--exec #CreateTariff 'TSCBP', 'Block products', 10, 'TON', 'EUR', 'BP', 'S'
--exec #CreateTariff 'TSCSL', 'Switch Location in Warehouse', 20, 'TON', 'EUR', 'SL', 'S'

INSERT INTO [dbo].[UNIT]
           ([DESCRIPTION]
           ,[CREATE_USER]
           ,[CREATE_TIMESTAMP]
           ,[UPDATE_USER]
           ,[UPDATE_TIMESTAMP]
           ,[STATUS]
           ,[CODE])
     VALUES
           ('Label' -- DESCRIPTION
           ,'sys'
           ,getdate()
           ,'sys'
           ,getdate()
           ,1 - STATUS
           ,'LBL')
INSERT INTO [dbo].[UNIT]
           ([DESCRIPTION]
           ,[CREATE_USER]
           ,[CREATE_TIMESTAMP]
           ,[UPDATE_USER]
           ,[UPDATE_TIMESTAMP]
           ,[STATUS]
           ,[CODE])
     VALUES
           ('Stencil' -- DESCRIPTION
           ,'sys'
           ,getdate()
           ,'sys'
           ,getdate()
           ,1 - STATUS
           ,'STENCIL')					 
INSERT INTO [dbo].[UNIT]
           ([DESCRIPTION]
           ,[CREATE_USER]
           ,[CREATE_TIMESTAMP]
           ,[UPDATE_USER]
           ,[UPDATE_TIMESTAMP]
           ,[STATUS]
           ,[CODE])
     VALUES
           ('Hour' -- DESCRIPTION
           ,'sys'
           ,getdate()
           ,'sys'
           ,getdate()
           ,1 - STATUS
           ,'HR')

exec #CreateTariff 'TWBB', 'Weatherizing Big Bags', 4.9, 'BBG', 'EUR', 'WBB', 'A'
exec #CreateTariff 'TCSL', 'Customer/Country specific label', 0.65, 'LBL', 'EUR', 'CSL', 'A'
exec #CreateTariff 'TSML', 'Shipping marks labelling', 0.65, 'LBL', 'EUR', 'SML', 'A'
exec #CreateTariff 'TPCH', 'Pallet Change (to 110x110 pallets)', 2.1, 'PAL', 'EUR', 'PCH', 'A'
exec #CreateTariff 'TDBBPLT', 'De-stacking of Big Bags + re-palletize', 2.1, 'PAL', 'EUR', 'DBBPLT', 'A'
exec #CreateTariff 'TPCHUS', 'Pallet Change (4 semi-way US to 4 way)', 2.1, 'PAL', 'EUR', 'PCHUS', 'A'
exec #CreateTariff 'TCCL', 'Color Coding labelling', 0.65, 'PAL', 'EUR', 'CCL', 'A'
exec #CreateTariff 'TSPAL', 'Securing pallet (drum or big bag)', 4.2, 'PAL', 'EUR', 'SPAL', 'A'
exec #CreateTariff 'TTPT', 'Taking pictures of truck/container in loading process', 6, 'tr/ctn', 'EUR', 'TPT', 'A'
exec #CreateTariff 'TSTENC', 'Stencilling', 65, 'STENCIL', 'EUR', 'STENC', 'A'
exec #CreateTariff 'TISHPD', 'Issuing of shipment documents', 11.65, 'ORDER', 'EUR', 'ISHPD', 'A'
exec #CreateTariff 'TPECNT', 'Preparing export container (blocking/bracing)', 12.5, 'ORDER', 'EUR', 'PECNT', 'A'
exec #CreateTariff 'TPCSTD', 'Preparation of customs documents', 35, 'ORDER', 'EUR', 'PCSTD', 'A'
exec #CreateTariff 'TAWHSP', 'Additional work hours / special project', 40, 'HR', 'EUR', 'AWHSP', 'A'
exec #CreateTariff 'TAWHO', 'Additional work hours – overtime / special project', 50, 'HR', 'EUR', 'AWHO', 'A'
exec #CreateTariff 'TAWHST', 'Additional work hours – Saturday / special project', 50, 'HR', 'EUR', 'AWHST', 'A'
exec #CreateTariff 'TAWHSN', 'Additional work hours – Sunday / special project', 70, 'HR', 'EUR', 'AWHSN', 'A'
exec #CreateTariff 'TAWHH', 'Additional work hours – Holiday / special project', 70, 'HR', 'EUR', 'AWHH', 'A'

