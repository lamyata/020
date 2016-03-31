DECLARE @cnt INT = 1;

WHILE @cnt < 11
BEGIN
	declare @paddr nvarchar(10) = '1B' + right('00' + cast(@cnt as varchar(2)), 2)
	update loc set PARENT_ID = parent.LOCATION_ID, HIERARCHY_LEVEL = parent.HIERARCHY_LEVEL + 1,
		PLAIN_PATH = parent.PLAIN_PATH + parent.CODE + '|',
		[PATH] = parent.[PATH] + cast(parent.LOCATION_ID as nvarchar(20)) + '|'
		from [LOCATION] loc, [LOCATION] parent
		where loc.[ADDRESS] like @paddr + '_' and loc.PARENT_ID is null and parent.[ADDRESS] = @paddr
	update loc set HAS_CHILDREN = 1 from [LOCATION] loc where ADDRESS = @paddr
	SET @cnt = @cnt + 1;
END;
