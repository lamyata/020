/*
CREATE TABLE [dbo].[VAS_TARIFF]
(
    [VAS_TARIFF_ID] int NOT NULL,
    [CREATE_USER] nvarchar(100) NOT NULL,
    [CREATE_TIMESTAMP] datetime2(7) NOT NULL,
    [UPDATE_USER] nvarchar(100) NOT NULL,
    [UPDATE_TIMESTAMP] datetime2(7) NOT NULL,
    CONSTRAINT [PK_VAS_TARIFF] PRIMARY KEY CLUSTERED ([VAS_TARIFF_ID] ASC),
    CONSTRAINT [FK_VAS_TARIFF_TARIFF] FOREIGN KEY ([VAS_TARIFF_ID]) REFERENCES [dbo].[TARIFF] ([TARIFF_ID])
)
*/


-- add static data
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
           ,1 -- STATUS
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
           ,1 -- STATUS
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
           ,1 -- STATUS
           ,'HR')
go

create proc #CreateTariffInternal
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@MeasurementUnitCode  nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@CustomerCode nvarchar(50)
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
			,@MeasurementUnitId
			,CURRENCY_ID
			--,SERVICE_ACCOUNT nvarchar(50)
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
			   ,'1-JAN-2022' -- PERIOD_TO
			   ,'sys'
			   ,getdate()
			   ,'sys'
			   ,getdate()
	FROM TARIFF_INFO ti, TARIFF_FILE tf
	WHERE ti.CODE = @TariffInfoCode AND tf.REFERENCE = 'CRI_TARIFF';

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

create proc #CreateTariff
	@TariffInfoCode nvarchar(250),
	@TariffInfoDescr nvarchar(250),
	@TariffInfoTariff decimal(18,3),
	@UnitCode nvarchar(50),
	@MeasurementUnitCode  nvarchar(50),
	@CurrencyCode nvarchar(3),
	@OperationCode nvarchar(50),
	@OperationType nvarchar(10),
	@CustomerCode nvarchar(50)
as
	declare @TariffId int
begin
	exec @TariffId = #CreateTariffInternal @TariffInfoCode, @TariffInfoDescr, @TariffInfoTariff, @UnitCode, @MeasurementUnitCode, @CurrencyCode, @OperationCode, @CustomerCode
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
exec CreateOperation 'SKU','IC_VMHZP','VAS','SKU Change','SKU Change'


insert into [dbo].[OPERATION_SHIFT]([OPERATION_ID],[SHIFT_ID]) 
select o.OPERATION_ID, s.SHIFT_ID from OPERATION o, NS_SHIFT s
join  NS_SHIFT_INTERNAL_COMPANY si ON s.SHIFT_ID = si.SHIFT_ID
join INTERNAL_COMPANY ic on si.INTERNAL_COMPANYNR = ic.COMPANYNR
JOIN COMPANY c ON ic.COMPANYNR = c.COMPANYNR
WHERE c.CODE = 'IC_VMHZP' and 
	  s.CODE in ('D', 'N', 'MN', 'HD') AND 
	  o.CODE IN ('VRBB2BB', 'VRBB2B025', 'VRB2DRUM', 'VRDRUM2B', 'VRB2IBC', 'VRIBC2B', 'SKU')
																  

insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRBB2BB'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRBB2B025'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRB2DRUM'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRDRUM2B'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRB2IBC'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'VRIBC2B'
insert into [dbo].[VAS_OPERATION] ([VAS_OPERATION_ID],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] ) select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'SKU'

exec #CreateTariff 'TVRBB2BB', 'Repacking Big bag to Big bag', 19, 'Net', 'TON', 'EUR', 'VRBB2BB', 'V', 'CRI'
exec #CreateTariff 'TVRBB2B025', 'Repacking Big bag to 25kg bag', 35, 'Net', 'TON', 'EUR', 'VRBB2B025', 'V', 'CRI'
exec #CreateTariff 'TVRB2DRUM', 'Repacking bag to drum', 23, 'Net', 'TON', 'EUR', 'VRB2DRUM', 'V', 'CRI'
exec #CreateTariff 'TVRDRUM2B', 'Repacking drum to bag', 43, 'Net', 'TON', 'EUR', 'VRDRUM2B', 'V', 'CRI'
exec #CreateTariff 'TVRB2IBC', 'Repacking bag to IBC', 19, 'Net', 'TON', 'EUR', 'VRB2IBC', 'V', 'CRI'
exec #CreateTariff 'TVRIBC2B', 'Repacking IBC to bag', 43, 'Net', 'TON', 'EUR', 'VRIBC2B', 'V', 'CRI'
exec #CreateTariff 'TCRISKU', 'SKU Change', 5.50, 'PAL', null, 'EUR', 'SKU', 'V', 'CRI'

--exec #CreateTariff 'TSCBP', 'Block products', 10, 'TON', 'EUR', 'BP', 'S'
--exec #CreateTariff 'TSCSL', 'Switch Location in Warehouse', 20, 'TON', 'EUR', 'SL', 'S'

-- DISCHARGING into warehouse (ex-truck/container) – 3.99 EUR per pallet
exec #CreateTariff 'CRI_DSCH', 'Discharging into warehouse (ex-truck/container)', 3.99, 'PAL', null, 'EUR', 'NULL', 'D', 'CRI'

-- LOADING ex-warehouse (into truck/container) – 3.39 EUR per pallet
exec #CreateTariff 'CRI_LDNG', 'Loading ex-warehouse (into truck/container)', 3.39, 'PAL', null, 'EUR', 'NULL', 'L', 'CRI'

exec #CreateTariff 'TWBB', 'Weatherizing Big Bags', 4.9, 'BBG', null,'EUR', 'WBB', 'A', 'CRI'
exec #CreateTariff 'TCSL', 'Customer/Country specific label', 0.65, 'LBL', null,'EUR', 'CSL', 'A', 'CRI'
exec #CreateTariff 'TSML', 'Shipping marks labelling', 0.65, 'LBL', null,'EUR', 'SML', 'A', 'CRI'
exec #CreateTariff 'TPCH', 'Pallet Change (to 110x110 pallets)', 2.1, 'PAL', null,'EUR', 'PCH', 'A', 'CRI'
exec #CreateTariff 'TDBBPLT', 'De-stacking of Big Bags + re-palletize', 2.1, 'PAL', null,'EUR', 'DBBPLT', 'A', 'CRI'
exec #CreateTariff 'TPCHUS', 'Pallet Change (4 semi-way US to 4 way)', 2.1, 'PAL', null,'EUR', 'PCHUS', 'A', 'CRI'
exec #CreateTariff 'TCCL', 'Color Coding labelling', 0.65, 'PAL', null,'EUR', 'CCL', 'A', 'CRI'
exec #CreateTariff 'TSPAL', 'Securing pallet (drum or big bag)', 4.2, 'PAL', null,'EUR', 'SPAL', 'A', 'CRI'
exec #CreateTariff 'TTPT', 'Taking pictures of truck/container in loading process', 6, 'TRP', null,'EUR', 'ORDER', 'A', 'CRI'
exec #CreateTariff 'TSTENC', 'Stencilling', 65, 'STENCIL', null,'EUR', 'STENC', 'A', 'CRI'
exec #CreateTariff 'TISHPD', 'Issuing of shipment documents', 11.65, 'ORDER', null,'EUR', 'ISHPD', 'A', 'CRI'
exec #CreateTariff 'TPECNT', 'Preparing export container (blocking/bracing)', 12.5, 'ORDER', null,'EUR', 'PECNT', 'A', 'CRI'
exec #CreateTariff 'TPCSTD', 'Preparation of customs documents', 35, 'ORDER', null,'EUR', 'PCSTD', 'A', 'CRI'
exec #CreateTariff 'TAWHSP', 'Additional work hours / special project', 40, 'HR', null,'EUR', 'AWHSP', 'A', 'CRI'
exec #CreateTariff 'TAWHO', 'Additional work hours – overtime / special project', 50, 'HR', null,'EUR', 'AWHO', 'A', 'CRI'
exec #CreateTariff 'TAWHST', 'Additional work hours – Saturday / special project', 50, 'HR', null,'EUR', 'AWHST', 'A', 'CRI'
exec #CreateTariff 'TAWHSN', 'Additional work hours – Sunday / special project', 70, 'HR', null,'EUR', 'AWHSN', 'A', 'CRI'
exec #CreateTariff 'TAWHH', 'Additional work hours – Holiday / special project', 70, 'HR', null,'EUR', 'AWHH', 'A', 'CRI'

INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Colorspraying','Colorspraying','ACLRSPRAY', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 1,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'ACLRSPRAY'
exec #CreateTariff 'TACLRSPRAY', 'Colorspraying', 0, 'PCS', null,'EUR', 'ACLRSPRAY', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION)
	and ao.CODE = 'ACLRSPRAY'


INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Put wooden top covers on goods','Put wooden top covers on goods','AWDTOPCOVERS', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 1 ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'AWDTOPCOVERS'
exec #CreateTariff 'TAWDTOPCOVERS', 'Put wooden top covers on goods', 0, 'PCS', null,'EUR', 'AWDTOPCOVERS', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION)
	and ao.CODE = 'AWDTOPCOVERS'
	
INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Crossdocking','Crossdocking','ACRSDOCKING', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'ACRSDOCKING'
exec #CreateTariff 'TACRSDOCKING', 'Crossdocking', -2.38, 'PAL', null,'EUR', 'ACRSDOCKING', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION)
	and ao.CODE = 'ACRSDOCKING'
	
INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Same Day rush order','Same Day rush order','ASAMEDAYRUSHORDER', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'ASAMEDAYRUSHORDER'
exec #CreateTariff 'TASAMEDAYRUSHORDER', 'Same Day rush order', 0, 'ORDER', null,'EUR', 'ASAMEDAYRUSHORDER', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION)
	and ao.CODE = 'ASAMEDAYRUSHORDER'

--exec CreateOperation 'AANNPHYSINVENT','IC_VMHZP','AA','Annual Physical Inventory','Annual Physical Inventory'
--insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
-- select o.OPERATION_ID ,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'ASAMEDAYRUSHORDER'
--exec #CreateTariff 'TAANNPHYSINVENT', 'Annual Physical Inventory', 0, 'ORDER', null,'EUR', 'AANNPHYSINVENT', 'A', 'CRI'

INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Fees on customs duty outlays','Fees on customs duty outlays','AFEESCUSTDUTYOUTLAYS', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
 select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'AFEESCUSTDUTYOUTLAYS'
exec #CreateTariff 'TAFEESCUSTDUTYOUTLAYS', 'Fees on customs duty outlays', 0, 'ORDER', null,'EUR', 'AFEESCUSTDUTYOUTLAYS', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION union select DISCHARGING_OPERATION_ID from DISCHARGING_OPERATION)
	and ao.CODE = 'AFEESCUSTDUTYOUTLAYS'
	
INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Start-up and cleaning fee','Start-up and cleaning fee','ASNCLEANING', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
exec CreateOperation 'ASNCLEANING','IC_VMHZP','AA','Start-up and cleaning fee','Start-up and cleaning fee'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
 select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'ASNCLEANING'
exec #CreateTariff 'TASNCLEANING', 'Start-up and cleaning fee', 195, 'ORDER', null,'EUR', 'ASNCLEANING', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION union select DISCHARGING_OPERATION_ID from DISCHARGING_OPERATION)
	and ao.CODE = 'ASNCLEANING'

INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Waste handling per Big bag','Waste handling per Big bag','AWSTHANBB', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'AWSTHANBB'
exec #CreateTariff 'TAWSTHANBB', 'Waste handling per Big bag', 0.8, 'BBG', null,'EUR', 'AWSTHANBB', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION union select DISCHARGING_OPERATION_ID from DISCHARGING_OPERATION)
	and ao.CODE = 'AWSTHANBB'
	
INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Waste handling Drum','Waste handling Drum','AWSTHANDRUM', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'AWSTHANDRUM'
exec #CreateTariff 'TAWSTHANDRUM', 'Waste handling Drum', 0.8, 'DRUM', null,'EUR', 'AWSTHANDRUM', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION union select DISCHARGING_OPERATION_ID from DISCHARGING_OPERATION)
	and ao.CODE = 'AWSTHANDRUM'

INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Forklift work hours','Forklift work hours','AFRKLFTWRK', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'
insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 0, 'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'AFRKLFTWRK'
exec #CreateTariff 'TFRKLFTWRK', 'Forklift work hours', 0, 'HR', null,'EUR', 'AFRKLFTWRK', 'A', 'CRI'
insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select LOADING_OPERATION_ID from LOADING_OPERATION union select VAS_OPERATION_ID from VAS_OPERATION union select DISCHARGING_OPERATION_ID from DISCHARGING_OPERATION)
	and ao.CODE = 'AFRKLFTWRK'

-- Fast SKU Change additional operation
	INSERT INTO [dbo].[OPERATION]([NAME],[DESCRIPTION],[CODE],[INTERNAL_COMPANY_ID],[TYPE_ID],[STATUS],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
	SELECT 'Fast SKU Change','Fast SKU Change','FCRISKU', c.COMPANYNR, ot.OPERATION_TYPE_ID, 0,'system', getdate(), 'system', getdate()
	FROM COMPANY c, OPERATION_TYPE ot where c.CODE = 'IC_VMHZP' and ot.[DESCRIPTION]='Additional'

insert into [dbo].[ADDITIONAL_OPERATION] ([ADDITIONAL_OPERATION_ID],[USAGE],[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP] )
	select o.OPERATION_ID , 1,'system', getdate(), 'system', getdate() from OPERATION o where o.CODE = 'FCRISKU'

exec #CreateTariff 'TFCRISKU', 'Fast SKU Change', 0.55, 'PAL', null,'EUR', 'FCRISKU', 'A', 'CRI'

insert into OPERATION_ADDITIONAL_OPERATION
	select o.OPERATION_ID, ao.OPERATION_ID
	from OPERATION o, OPERATION ao
	where o.INTERNAL_COMPANY_ID = ao.INTERNAL_COMPANY_ID
	and o.OPERATION_ID in (select OPERATION_ID from VAS_OPERATION vo INNER JOIN OPERATION o ON vo.VAS_OPERATION_ID = o.OPERATION_ID WHERE o.CODE = 'SKU') 
	and ao.CODE = 'FCRISKU'

-- Set service accounts.

UPDATE TARIFF_INFO 
SET SERVICE_ACCOUNT = '701300' -- Loading
WHERE TARIFF_INFO_ID IN (
	SELECT t.TARIFF_INFO_ID FROM TARIFF t
	JOIN LOADING_TARIFF lt ON t.TARIFF_ID = lt.LOADING_TARIFF_ID
	JOIN TARIFF_FILE tf ON t.TARIFF_FILE_ID = tf.TARIFF_FILE_ID
	WHERE tf.REFERENCE = 'CRI_TARIFF' )

UPDATE TARIFF_INFO 
SET SERVICE_ACCOUNT = '701300' -- Discharging
WHERE TARIFF_INFO_ID IN (
	SELECT t.TARIFF_INFO_ID FROM TARIFF t
	JOIN DISCHARGING_TARIFF dt ON t.TARIFF_ID = dt.DISCHARGING_TARIFF_ID
	JOIN TARIFF_FILE tf ON t.TARIFF_FILE_ID = tf.TARIFF_FILE_ID
	WHERE tf.REFERENCE = 'CRI_TARIFF' )

UPDATE TARIFF_INFO 
SET SERVICE_ACCOUNT = '701310' -- Additional
WHERE TARIFF_INFO_ID IN (
	SELECT t.TARIFF_INFO_ID FROM TARIFF t
	JOIN ADDITIONAL_TARIFF at ON t.TARIFF_ID = at.ADDITIONAL_TARIFF_ID
	JOIN TARIFF_FILE tf ON t.TARIFF_FILE_ID = tf.TARIFF_FILE_ID
	WHERE tf.REFERENCE = 'CRI_TARIFF' )

/*
UPDATE TARIFF_INFO 
SET SERVICE_ACCOUNT = '' -- VAS
WHERE TARIFF_INFO_ID IN (
	SELECT t.TARIFF_INFO_ID FROM TARIFF t
	JOIN VAS_TARIFF vt ON t.TARIFF_ID = vt.VAS_TARIFF_ID
	JOIN TARIFF_FILE tf ON t.TARIFF_FILE_ID = tf.TARIFF_FILE_ID
	WHERE tf.REFERENCE = 'CRI_TARIFF' )
*/

insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='ACLRSPRAY' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='AWDTOPCOVERS' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='ACRSDOCKING' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='ASAMEDAYRUSHORDER' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='AFEESCUSTDUTYOUTLAYS' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='ASNCLEANING' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='AWSTHANBB' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='AWSTHANDRUM' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='AFRKLFTWRK' and c.CODE ='CRI'
insert into [dbo].[ADDITIONAL_OPERATION_COMPANY]([ADDITIONAL_OPERATION_ID],[COMPANYNR]) select o.OPERATION_ID, c.COMPANYNR from OPERATION o, COMPANY c where o.CODE='FCRISKU' and c.CODE ='CRI'

