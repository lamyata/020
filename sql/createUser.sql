create proc #CreateUser
	@Login nvarchar(30),
	@Password nvarchar(50),
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@LanguageId nvarchar(2),
	@ApplicationRoleName nvarchar(100),
	@ICCompanyCode nvarchar(50)
as
begin

	INSERT INTO [dbo].[PERSON] (
		 [LOGIN]
		 ,[PASSWORD]
		 ,[FIRST_NAME]
		 ,[LAST_NAME]
		 ,[LID]
		 ,[ACTIVE]
		 ,[CREATE_USER]
		 ,[CREATE_TIMESTAMP]
		 ,[UPDATE_USER]
		 ,[UPDATE_TIMESTAMP]
		 ,[DEFAULT_INTERNAL_COMPANY_ID]
	)
	 SELECT 
		@Login,
		@Password,
		@FirstName,
		@LastName,
		@LanguageId,
		1,
		'sys',
		getdate(),
		'sys',
		getdate(),
		COMPANYNR
	FROM COMPANY c
	WHERE c.CODE = @ICCompanyCode

INSERT INTO [dbo].[PERSON_APPLICATION_ROLE] ([PERSON_ID] ,[APPLICATION_ROLE_ID])
SELECT p.PERSON_ID, ar.APPLICATION_ROLE_ID
FROM PERSON p, APPLICATION_ROLE ar
WHERE p.LOGIN = @Login AND ar.NAME = @ApplicationRoleName

INSERT INTO [dbo].[PERSON_INTERNAL_COMPANY]
		 ([INT_COMPANYNR]
		 ,[USER_ID])
	 SELECT
		 c.COMPANYNR,
		 p.PERSON_ID
	FROM PERSON p, COMPANY c
	WHERE p.LOGIN = @Login AND c.CODE = @ICCompanyCode
end
go

exec #CreateUser 'UAT_BTM', 'MTB_TAU_soTi', 'Login', '1', 'EN', 'Admin', 'IC1'
exec #CreateUser 'an@btmmoerdijk.eu', 'UAT_BTM_An', 'Login', '2', 'EN', 'Admin', 'IC1'
exec #CreateUser 'Leendert@vdreijtfert.nl', 'UAT_BTM_Leendert', 'Login', '3', 'EN', 'Admin', 'IC1'
exec #CreateUser 'slemmer@vdreijtfert.nl', 'UAT_BTM_JOS', 'Login', '4', 'EN', 'Admin', 'IC1'
exec #CreateUser 'Kees@vdreijtfert.nl', 'UAT_BTM_KEES', 'Login', '5', 'EN', 'Admin', 'IC1'

update PERSON set [PASSWORD] = 'siroBi23' where [LOGIN] = 'iTos'

exec #CreateUser 'PRD_BTM', 'MTB_DRP_soTi', 'Login', '1', 'EN', 'Admin', 'IC1'
exec #CreateUser 'an@btmmoerdijk.eu', 'PRD_BTM_An', 'Login', '2', 'EN', 'Admin', 'IC1'
exec #CreateUser 'Leendert@vdreijtfert.nl', 'PRD_BTM_Leendert', 'Login', '3', 'EN', 'Admin', 'IC1'
exec #CreateUser 'slemmer@vdreijtfert.nl', 'PRD_BTM_JOS', 'Login', '4', 'EN', 'Admin', 'IC1'
exec #CreateUser 'Kees@vdreijtfert.nl', 'PRD_BTM_KEES', 'Login', '5', 'EN', 'Admin', 'IC1'

exec #CreateUser 'GVDVeken', 'GVDVeken1010', 'Guy', 'Van der Veken', 'EN', 'Admin', 'IC1'
exec #CreateUser 'PSmout', 'PSmout1010', 'Pieter', 'Smout', 'EN', 'Admin', 'IC1'
exec #CreateUser 'KVLeemput', 'KVLeemput1010', 'Koen', 'Van Leemput', 'EN', 'Admin', 'IC1'