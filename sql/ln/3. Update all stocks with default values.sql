-- 3. Update all StockInfoConfigs as follows: change _key_ and set its value according to default values in product configuration

BEGIN TRY
	BEGIN TRANSACTION

		-- 3.1. Create temp table with all StockInfoConfigs and default values of SID "Rolls" from SGN's products configurations
		DECLARE @StockInfoConfigsAndDefaultValues table
		(
			StockInfoConfigId int,
			ProductId int,
			SidId int,
			SidDefault nvarchar(max)
		)
		INSERT INTO @StockInfoConfigsAndDefaultValues
		SELECT
			sic.STOCK_INFO_CONFIG_ID,
			productsAndDefaultValues.PRODUCT_ID,
			productsAndDefaultValues.STORAGE_IDENTIFIER_ID,
			productsAndDefaultValues.SID_DEFAULT
		FROM 
			STOCK_INFO_CONFIG sic
			join INTERNAL_COMPANY ic on ic.COMPANYNR = sic.INTERNAL_COMPANY_ID
			join COMPANY c on c.COMPANYNR = ic.COMPANYNR,
			(
				-- SID "Rolls" default values for all SGN's products
				SELECT psi.PRODUCT_ID, si.STORAGE_IDENTIFIER_ID, psi.SID_DEFAULT FROM PRODUCT_STORAGE_IDENTIFIER psi
				join STORAGE_IDENTIFIER si on si.STORAGE_IDENTIFIER_ID = psi.SID_ID
				join PRODUCT p on p.PRODUCT_ID = psi.PRODUCT_ID
				join PRODUCT_INT_COMPANY pic on pic.PRODUCT_ID = p.PRODUCT_ID
				join INTERNAL_COMPANY ic on ic.COMPANYNR = pic.INT_COMPANYNR
				join COMPANY c on c.COMPANYNR = ic.COMPANYNR
				WHERE
					si.CODE = 'RLL' and
					c.CODE = 'IC_SGN' and
					(psi.SID_DEFAULT is not NULL and LEN(psi.SID_DEFAULT) > 0)
			) productsAndDefaultValues
		WHERE
			c.CODE = 'IC_SGN' and
			sic.PRODUCT_ID = productsAndDefaultValues.PRODUCT_ID
		--select * from @StockInfoConfigsAndDefaultValues

		-- 3.2. Update all StockInfoSid's values according to default values in product configuration
		UPDATE STOCK_INFO_SID
		SET
			VALUE = stockInfoConfigsAndDefaultValues.SidDefault,
			UPDATE_USER = 'script',
			UPDATE_TIMESTAMP = GETDATE()
		FROM
			@StockInfoConfigsAndDefaultValues stockInfoConfigsAndDefaultValues
		WHERE
			SID_ID = stockInfoConfigsAndDefaultValues.SidId and
			STOCK_INFO_CONFIG_ID = stockInfoConfigsAndDefaultValues.StockInfoConfigId
			

		-- 3.3. Update all StockInfoConfig's keys according to default values in product configuration
		UPDATE STOCK_INFO_CONFIG
		SET
			_KEY_ = REPLACE(
								_KEY_,
								'{"' + CAST(stockInfoConfigsAndDefaultValues.SidId as varchar) + '":""}',
								'{"' + CAST(stockInfoConfigsAndDefaultValues.SidId as varchar) + '":"' + stockInfoConfigsAndDefaultValues.SidDefault + '"}'
						   ),
			UPDATE_USER = 'script',
			UPDATE_TIMESTAMP = GETDATE()
		FROM @StockInfoConfigsAndDefaultValues stockInfoConfigsAndDefaultValues
		WHERE STOCK_INFO_CONFIG_ID = stockInfoConfigsAndDefaultValues.StockInfoConfigId

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		SELECT ERROR_NUMBER() as ErrorNumber, ERROR_MESSAGE() as ErrorMessage
END CATCH