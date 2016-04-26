declare @ProductCode nvarchar(50) = '3024'
declare @NewBaseUnitCode nvarchar(50) = 'Box'

--declare @ProductCode nvarchar(50) = '3209'
--declare @NewBaseUnitCode nvarchar(50) = 'JERRICAN'

--declare @ProductCode nvarchar(50) = '10341'
--declare @NewBaseUnitCode nvarchar(50) = 'JERRICAN'

--declare @ProductCode nvarchar(50) = '5338'
--declare @NewBaseUnitCode nvarchar(50) = 'DRUM'


declare @ProductId int
select @ProductId = PRODUCT_ID from PRODUCT where CODE = @ProductCode

declare @OldBaseUnitId int
declare @OldProductUnitId int

select @OldBaseUnitId = pu.UNIT_ID, @OldProductUnitId = pu.PRODUCT_UNIT_ID
	from PRODUCT_UNIT pu join PRODUCT p on pu.PRODUCT_UNIT_ID = p.BASE_UNIT_ID
	where PRODUCT_ID = @ProductId

declare @NewBaseUnitId int
declare @NewProductUnitId int

select @NewBaseUnitId = UNIT_ID from UNIT where CODE = @NewBaseUnitCode
insert into PRODUCT_UNIT (UNIT_ID, COEF, DEFAULT_MEASUREMENT_UNIT_ID, CREATE_USER, CREATE_TIMESTAMP, UPDATE_USER, UPDATE_TIMESTAMP)
	values (@NewBaseUnitId, NULL, NULL, 'sys', getdate(), 'sys', getdate());
set @NewProductUnitId = SCOPE_IDENTITY();

update PRODUCT set BASE_UNIT_ID = @NewProductUnitId where PRODUCT_ID = @ProductId

delete from PRODUCT_UNIT where PRODUCT_UNIT_ID = @OldProductUnitId

update siq set UNIT_ID = @NewBaseUnitId, MEASUREMENT_UNIT_ID = null
	from STOCK_INFO si join STOCK_INFO_CONFIG sic on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
	join STOCK_INFO_QUANTITY siq on siq.STOCK_INFO_QUANTITY_ID = si.BASE_QUANTITY_ID
	where sic.PRODUCT_ID = @ProductId

update STOCK_INFO_CONFIG set BASE_UNIT_ID = @NewBaseUnitId, [_KEY_] = 
	REPLACE([_KEY_], '"BU":' + CAST(@OldBaseUnitId as varchar) + ',"TN":',	'"BU":' + CAST(@NewBaseUnitId as varchar) + ',"TN":')
	where PRODUCT_ID = @ProductId