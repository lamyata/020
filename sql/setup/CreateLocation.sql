CREATE PROC CreateLocation
	@Code nvarchar(15),
	@Address nvarchar(20),
	@Description nvarchar(100),
	@Status int,
	@LocationTypeName nvarchar(100),
	@ParentAddress nvarchar(20),
	@BarcodeTypeDescription nvarchar(50),
	@Barcode nvarchar(50),
	@Row int,
	@Column int,
	@Level int
AS
	declare @BarcodeTypeId int
	declare @LocationTypeId int
	declare @ParentId int
	declare @HierarchiLevel int = 0
	declare @Path nvarchar(250)
	declare @PlainPath nvarchar(250)
BEGIN

	select @LocationTypeId = LOCATION_TYPE_ID from LOCATION_TYPE where NAME = @LocationTypeName
	select @BarcodeTypeId = BARCODE_TYPE_ID from BARCODE_TYPE where [DESCRIPTION] = @BarcodeTypeDescription
	select @ParentId = LOCATION_ID,
		@HierarchiLevel = HIERARCHY_LEVEL + 1,
		@PlainPath = IsNull([PLAIN_PATH],'|') + CODE +'|',
		@Path = IsNull([PATH],'|') + cast(LOCATION_ID as nvarchar(20)) + '|'
	from LOCATION where [ADDRESS] = @ParentAddress

	INSERT INTO [dbo].[LOCATION]
           ([CODE]
           ,[ADDRESS]
           ,[DESCRIPTION]
           ,[STATUS]
           ,[BARCODE_TYPE_ID]
           ,[BARCODE]
           ,[LOCATION_TYPE_ID]
           ,[_ROW_]
           ,[_COLUMN_]
           ,[LEVEL]
           ,[HIERARCHY_LEVEL]
           ,[PARENT_ID]
		   ,[HAS_CHILDREN]
           ,[PATH]
           ,[PLAIN_PATH]
           ,[CREATE_USER]
           ,[CREATE_TIMESTAMP]
           ,[UPDATE_USER]
           ,[UPDATE_TIMESTAMP])
     VALUES
           (@Code
           ,@Address
           ,@Description
           ,@Status
           ,@BarcodeTypeId
           ,@Barcode
           ,@LocationTypeId
           ,@Row
           ,@Column
           ,@Level
           ,@HierarchiLevel
           ,@ParentId
		   ,0
           ,@Path
           ,@PlainPath
           ,'system'
           ,getdate()
           ,'system'
           ,getdate())

	-- Update parent's "HasChildren" property
	UPDATE LOCATION
	SET HAS_CHILDREN = 1
	WHERE LOCATION_ID IN
	(
		SELECT PARENT_ID FROM LOCATION
		WHERE STATUS = 0 AND PARENT_ID IS NOT NULL AND PARENT_ID = @ParentId
		GROUP BY PARENT_ID
	)
END
