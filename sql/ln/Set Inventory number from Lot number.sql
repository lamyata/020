-- SQL script for setting inventory number from SID "Lot number" for SGN's stocks

BEGIN TRY
	BEGIN TRANSACTION

		-- 1. Get existing data for LOT Numbers
		DECLARE @LotAndInventory table
		(
			StockInfoConfigId int,
			_Key_ nvarchar(max),
			LotNumber nvarchar(max),
			IsLotNumberValid bit,
			ToBeInventoryNumber nvarchar(max),
			InventoryNumber nvarchar(max)
		)
		INSERT INTO @LotAndInventory
		SELECT
			sic.STOCK_INFO_CONFIG_ID,
			sic._KEY_,
			sis.VALUE as LOT_Number,
			CAST(CASE WHEN 
					LEN(sis.VALUE) >= 10 and -- LotNumber should be at least 10 chars
					LEN(CONCAT(SUBSTRING(sis.VALUE, 5, 2), SUBSTRING(sis.VALUE, 8, 3))) = 5 and -- The new inventory number should be exactly 5 chars
					ISNUMERIC(CONCAT(SUBSTRING(sis.VALUE, 5, 2), SUBSTRING(sis.VALUE, 8, 3))) = 1 -- The new inventory number should contains only digits
				 THEN 1 ELSE 0 END as bit) as IsLotNumberValid,
			(CONCAT(SUBSTRING(sis.VALUE, 5, 2), SUBSTRING(sis.VALUE, 8, 3))) as ToBeInventoryNumber,
			sic.INVENTORY_NUMBER
		FROM STOCK_INFO_CONFIG sic
			join INTERNAL_COMPANY ic on sic.INTERNAL_COMPANY_ID = ic.COMPANYNR
			join COMPANY c on c.COMPANYNR = ic.COMPANYNR
			join STOCK_INFO_SID sis on sis.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
			join STORAGE_IDENTIFIER s on s.STORAGE_IDENTIFIER_ID = sis.SID_ID
		WHERE
			c.CODE = 'IC_SGN' and
			s.CODE = 'LOT' and
			sic.STOCK_INFO_CONFIG_ID not in
			(
				-- DOI Goods
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join DISCHARGING_ORDER_ITEM_GOODS doig on doig.STOCK_INFO_ID = si.STOCK_INFO_ID
				-- LOI Goods
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join LOADING_ORDER_ITEM_GOOD loig on loig.STOCK_INFO_ID = si.STOCK_INFO_ID
				-- SCOI Goods
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join STOCK_CHANGE_ITEM sci on sci.FROM_ID = si.STOCK_INFO_ID or sci.TO_ID = si.STOCK_INFO_ID
				join STOCK_CHANGE_ORDER_ITEM_GOOD scoig on scoig.STOCK_CHANGE_ITEM_ID = sci.STOCK_CHANGE_ITEM_ID

				-- DOP Remaining
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join DISCHARGING_OPERATION_PLAN dop on dop.REMAINING_ID = si.STOCK_INFO_ID
				-- LOP Remaining
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join LOADING_OPERATION_PLAN lop on lop.REMAINING_ID = si.STOCK_INFO_ID
				-- SCOP Remaining
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join STOCK_CHANGE_ITEM sci on sci.FROM_ID = si.STOCK_INFO_ID or sci.TO_ID = si.STOCK_INFO_ID
				join STOCK_CHANGE_OPERATION_PLAN scop on scop.REMAINING_ID = sci.STOCK_CHANGE_ITEM_ID

				-- DOP Planned
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join DISCHARGING_OPERATION_PLAN dop on dop.PLANNED_ID = si.STOCK_INFO_ID
				-- LOP Planned
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join LOADING_OPERATION_PLAN lop on lop.PLANNED_ID = si.STOCK_INFO_ID
				-- SCOP Planned
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join STOCK_CHANGE_ITEM sci on sci.FROM_ID = si.STOCK_INFO_ID or sci.TO_ID = si.STOCK_INFO_ID
				join STOCK_CHANGE_OPERATION_PLAN scop on scop.PLANNED_ID = sci.STOCK_CHANGE_ITEM_ID

				-- DOP Pending
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join DISCHARGING_OPERATION_PLAN dop on dop.PENDING_ID = si.STOCK_INFO_ID
				-- LOP Pending
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join LOADING_OPERATION_PLAN lop on lop.PENDING_ID = si.STOCK_INFO_ID
				-- SCOP Pending
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join STOCK_CHANGE_ITEM sci on sci.FROM_ID = si.STOCK_INFO_ID or sci.TO_ID = si.STOCK_INFO_ID
				join STOCK_CHANGE_OPERATION_PLAN scop on scop.PENDING_ID = sci.STOCK_CHANGE_ITEM_ID

				-- DOR Reported
				UNION
				SELECT sic.STOCK_INFO_CONFIG_ID FROM STOCK_INFO_CONFIG sic
				join STOCK_INFO si on si.STOCK_INFO_CONFIG_ID = sic.STOCK_INFO_CONFIG_ID
				join DISCHARGING_OPERATION_REPORT dor on dor.REPORTED_ID = si.STOCK_INFO_ID
				join OPERATION_REPORT r on r.OPERATION_REPORT_ID = dor.DISCHARGING_OPERATION_REPORT_ID
				WHERE r.STATUS in (0, 1)
			)
		SELECT * FROM @LotAndInventory

		-- 2. Check if all LOT Numbers are valid
		DECLARE @AreAllLotNumbersValid bit
		SET @AreAllLotNumbersValid = 
		(
			SELECT (CAST(CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END as bit)) as AreAllLotNumbersValid FROM @LotAndInventory
			WHERE IsLotNumberValid = 0
		)
		SELECT @AreAllLotNumbersValid as AreAllLotNumbersValid

		-- 3. If all LOT Numbers are valid, update Inventory numbers, else - print message
		IF @AreAllLotNumbersValid = 1
			BEGIN
				UPDATE STOCK_INFO_CONFIG
				SET
					INVENTORY_NUMBER = lai.ToBeInventoryNumber,
					_KEY_ = REPLACE(_KEY_, '"IN":"",', '"IN":"' + lai.ToBeInventoryNumber + '",'),
					UPDATE_USER = 'script',
					UPDATE_TIMESTAMP = GETDATE()
				FROM
					@LotAndInventory lai
				WHERE 
					STOCK_INFO_CONFIG_ID = lai.StockInfoConfigId
			END
		ELSE
			BEGIN
				PRINT 'Not all LOT Numbers are valid!'
			END

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		SELECT ERROR_NUMBER() as ErrorNumber, ERROR_MESSAGE() as ErrorMessage
END CATCH