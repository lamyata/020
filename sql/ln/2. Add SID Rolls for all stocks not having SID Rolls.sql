-- 2. Add SID "Rolls" for all stocks not having SID "Rolls"

BEGIN TRY
	BEGIN TRANSACTION

		-- 2.1. Create temp table with all StockInfoConfigs not having SID "Rolls"
		DECLARE @StockInfoConfigsToUpdate table
		(
			StockInfoConfigId int
		)
		INSERT INTO @StockInfoConfigsToUpdate
		-- StockInfoConfigs not having SID "Rolls"
		SELECT DISTINCT STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
		join INTERNAL_COMPANY ic on sic.INTERNAL_COMPANY_ID = ic.COMPANYNR
		join COMPANY c on c.COMPANYNR = ic.COMPANYNR
		WHERE
			c.CODE = 'IC_SGN' and
			sic.STOCK_INFO_CONFIG_ID not in
			(
				-- StockInfoConfigs having SID "Rolls"
				SELECT DISTINCT sis.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_SID sis
				join STORAGE_IDENTIFIER s on s.STORAGE_IDENTIFIER_ID = sis.SID_ID

				join STOCK_INFO_CONFIG sic on sic.STOCK_INFO_CONFIG_ID = sis.STOCK_INFO_CONFIG_ID
				join INTERNAL_COMPANY ic on sic.INTERNAL_COMPANY_ID = ic.COMPANYNR
				join COMPANY c on c.COMPANYNR = ic.COMPANYNR
				WHERE
					c.CODE = 'IC_SGN' and
					s.CODE = 'RLL'
			)
		
		--SELECT a.StockInfoConfigId, sic._KEY_ FROM @StockInfoConfigsToUpdate a
		--join STOCK_INFO_CONFIG sic on sic.STOCK_INFO_CONFIG_ID = a.StockInfoConfigId

		-- 2.2. Add SID "Rolls" for all StockInfoConfigs not having SID "Rolls" with NULL value
		INSERT INTO STOCK_INFO_SID
		(
			SID_ID,
			STOCK_INFO_CONFIG_ID,
			VALUE,
			CREATE_USER,
			CREATE_TIMESTAMP,
			UPDATE_USER,
			UPDATE_TIMESTAMP
		)
		SELECT
			s.STORAGE_IDENTIFIER_ID,
			sic.STOCK_INFO_CONFIG_ID,
			NULL,
			'script',
			GETDATE(),
			'script',
			GETDATE()
		FROM
			STORAGE_IDENTIFIER s,
			STOCK_INFO_CONFIG sic
		WHERE
			s.CODE = 'RLL' and 
			sic.STOCK_INFO_CONFIG_ID in
			(
				SELECT StockInfoConfigId FROM @StockInfoConfigsToUpdate
			)

		-- Update all StockInfoConfig's keys, not having SID "Rolls"
		UPDATE STOCK_INFO_CONFIG
		SET
			_KEY_ = REPLACE(_KEY_, '"}]}', '"},{"' + CAST(si.STORAGE_IDENTIFIER_ID as varchar) + '":""}]}'),
			UPDATE_USER = 'script',
			UPDATE_TIMESTAMP = GETDATE()
		FROM
			(SELECT * FROM STORAGE_IDENTIFIER) si
		WHERE
			si.CODE = 'RLL' and
			STOCK_INFO_CONFIG_ID in
			(
				SELECT StockInfoConfigId FROM @StockInfoConfigsToUpdate
			)

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		SELECT ERROR_NUMBER() as ErrorNumber, ERROR_MESSAGE() as ErrorMessage
END CATCH


-- Check (The query should return 0 rows)
--SELECT StockInfoConfigId FROM @StockInfoConfigsToUpdate

--select sic._KEY_ from STOCK_INFO_SID sis
--join STOCK_INFO_CONFIG sic on sis.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
--where sis.CREATE_USER = 'script'