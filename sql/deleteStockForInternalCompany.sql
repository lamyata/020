declare @IcCompanyCode nvarchar(50) = 'IC_VMHZP';
declare @internalCompanyId int;
select @internalCompanyId = COMPANYNR from COMPANY where CODE = @IcCompanyCode;

declare @deletedIds table (
 STOCK_INFO_ID int,
 STOCK_INFO_CONFIG_ID int,
 BASE_QUANTITY_ID int,
 STOCK_INFO_QUANTITY_ID int
);

delete s
 output deleted.STOCK_INFO_ID into @deletedIds (STOCK_INFO_ID)
 from STOCK s join STOCK_INFO si on s.STOCK_INFO_ID = si.STOCK_INFO_ID
 join STOCK_INFO_CONFIG sic on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
 where sic.INTERNAL_COMPANY_ID = @internalCompanyId;

delete siq
 from STOCK_INFO_QUANTITY siq
 join STOCK_INFO si on siq.STOCK_INFO_QUANTITY_ID = si.STORAGE_QUANTITY_ID
 join @deletedIds d on si.STOCK_INFO_ID = d.STOCK_INFO_ID;

delete sieq
 output deleted.STOCK_INFO_QUANTITY_ID into @deletedIds (STOCK_INFO_QUANTITY_ID)
 from STOCK_INFO_EXTRA_QUANTITY sieq
 join STOCK_INFO si on sieq.STOCK_INFO_ID = si.STOCK_INFO_ID
 join @deletedIds d on si.STOCK_INFO_ID = d.STOCK_INFO_ID;

delete siq
 from STOCK_INFO_QUANTITY siq
 join @deletedIds d on siq.STOCK_INFO_QUANTITY_ID = d.STOCK_INFO_QUANTITY_ID;

delete siq
 from STOCK_INFO_QUANTITY siq
 join STOCK_INFO si on siq.STOCK_INFO_QUANTITY_ID = si.STORAGE_QUANTITY_ID
 join @deletedIds d on si.STOCK_INFO_ID = d.STOCK_INFO_ID;

delete si
 output deleted.BASE_QUANTITY_ID, deleted.STOCK_INFO_CONFIG_ID into @deletedIds (BASE_QUANTITY_ID, STOCK_INFO_CONFIG_ID)
 from STOCK_INFO si
 join @deletedIds d on si.STOCK_INFO_ID = d.STOCK_INFO_ID;

delete siq
 from STOCK_INFO_QUANTITY siq
 join @deletedIds d on siq.STOCK_INFO_QUANTITY_ID = d.BASE_QUANTITY_ID;

delete siceu
 from STOCK_INFO_CONFIG_EXTRA_UNIT siceu
 join @deletedIds d on siceu.STOCK_INFO_CONFIG_ID = d.STOCK_INFO_CONFIG_ID;

delete sis
 from STOCK_INFO_SID sis
 join @deletedIds d on sis.STOCK_INFO_CONFIG_ID = d.STOCK_INFO_CONFIG_ID;

delete sic
 from STOCK_INFO_CONFIG sic
 join @deletedIds d on sic.STOCK_INFO_CONFIG_ID = d.STOCK_INFO_CONFIG_ID;
