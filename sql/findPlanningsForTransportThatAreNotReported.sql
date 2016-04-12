-- works for discharging (and after customize loading) reports
declare @transportId int = 13713
select * from DISCHARGING_OPERATION_PLAN where TRANSPORT_ID = @transportId and DISCHARGING_OPERATION_PLAN_ID not in (
	select opr.PLAN_ID from DISCHARGING_OPERATION_REPORT dopr join OPERATION_REPORT opr
	on dopr.DISCHARGING_OPERATION_REPORT_ID = opr.OPERATION_REPORT_ID and dopr.TRANSPORT_ID = @transportId
)
