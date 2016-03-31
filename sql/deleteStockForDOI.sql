declare @dischargingOrderItemId int = 15679;

declare @deletedIds table (
 STOCK_INFO_ID int,
 STOCK_INFO_CONFIG_ID int,
 STOCK_INFO_QUANTITY_ID int,
 BASE_QUANTITY_ID int,
 STORAGE_QUANTITY_ID int
);

delete doig
 output deleted.STOCK_INFO_ID into @deletedIds (STOCK_INFO_ID)
 from DISCHARGING_ORDER_ITEM_GOODS doig where DISCHARGING_ORDER_ITEM_ID = @dischargingOrderItemId;

delete sieq 
	output deleted.STOCK_INFO_QUANTITY_ID into @deletedIds(STOCK_INFO_QUANTITY_ID)
	from STOCK_INFO_EXTRA_QUANTITY sieq
	join @deletedIds d on sieq.STOCK_INFO_ID = d.STOCK_INFO_ID;

delete si
 output deleted.STOCK_INFO_CONFIG_ID, deleted.BASE_QUANTITY_ID, deleted.STORAGE_QUANTITY_ID into @deletedIds (STOCK_INFO_CONFIG_ID, BASE_QUANTITY_ID, STORAGE_QUANTITY_ID)
 from STOCK_INFO si join @deletedIds d on si.STOCK_INFO_ID = d.STOCK_INFO_ID;

delete siq
 from STOCK_INFO_QUANTITY siq
 join @deletedIds d on siq.STOCK_INFO_QUANTITY_ID = d.STOCK_INFO_QUANTITY_ID;

delete siq
 from STOCK_INFO_QUANTITY siq
 join @deletedIds d on siq.STOCK_INFO_QUANTITY_ID = d.BASE_QUANTITY_ID;

delete siq
 from STOCK_INFO_QUANTITY siq
 join @deletedIds d on siq.STOCK_INFO_QUANTITY_ID = d.STORAGE_QUANTITY_ID;

delete siceu
 from STOCK_INFO_CONFIG_EXTRA_UNIT siceu join @deletedIds d on siceu.STOCK_INFO_CONFIG_ID = d.STOCK_INFO_CONFIG_ID;

delete sis
 from STOCK_INFO_SID sis join @deletedIds d on sis.STOCK_INFO_CONFIG_ID = d.STOCK_INFO_CONFIG_ID;

