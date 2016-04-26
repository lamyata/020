declare @PalletIdSidId int
declare @PackNoSidId int
declare @ProductGroupId int

select @PalletIdSidId = STORAGE_IDENTIFIER_ID from STORAGE_IDENTIFIER where CODE = 'PLTID'
select @ProductGroupId = PRODUCT_GROUP_ID from PRODUCT_GROUP where CODE = 'CRI'

--1/ Insert SID Pack No
--Description 'Pack No'; Code 'PACKN'; type: text box
insert into STORAGE_IDENTIFIER (CODE,SHORT_DESC,PREDEFINED,SID_TYPE,STATUS,VALUE_TYPE,MASK,USE_REGEX_MASK,[CREATE_USER],[CREATE_TIMESTAMP],[UPDATE_USER],[UPDATE_TIMESTAMP])
 values ('PACKN','Pack No','',3,1,'System.String, mscorlib','',0,'system', getdate(), 'system', getdate())

 select @PackNoSidId = SCOPE_IDENTITY();

--2/ Products in product group CRI - Change of product configuration
-- remove SID Pallet ID
-- add SID Pack No (for all main operations)
UPDATE psi SET [SID_ID] = @PackNoSidId, [SID_DEFAULT] = ''
FROM [dbo].[PRODUCT_STORAGE_IDENTIFIER] psi, PRODUCT p
WHERE psi.PRODUCT_ID = p.PRODUCT_ID AND p.PRODUCT_GROUP_ID = @ProductGroupId
	AND psi.SID_ID = @PalletIdSidId

--3/  Products in product group CRI - stock update
--Add SID Pack No - set the value equal to value of SID Pallet ID
--Remove SID Pallet ID
UPDATE sis
SET [SID_ID] = @PackNoSidId
FROM [dbo].[STOCK_INFO_SID] sis, STOCK_INFO_CONFIG sic, PRODUCT p
WHERE sis.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID and
	sic.PRODUCT_ID = p.PRODUCT_ID and p.PRODUCT_GROUP_ID = @ProductGroupId
	and sis.SID_ID = @PalletIdSidId
