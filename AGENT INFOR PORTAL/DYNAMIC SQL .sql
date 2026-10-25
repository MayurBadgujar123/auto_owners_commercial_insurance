create or replace procedure prcv_dynamic_policy_report
(
   p_policy_type in varchar2,
   p_from_date in date,
   p_to_date in date
)
is
        v_sql varchar2(500);
        V_COUNT NUMBER;
begin
           v_sql:='SELECT COUNT(*)
                         FROM POLICIES
                        WHERE START_DATE BETWEEN :1 AND :2';
                        
           if  p_policy_type is not null then
           v_sql:=v_sql||' '||'AND POLICY_TYPE =:3';
           
           execute immediate v_sql
           into v_count
           using p_from_date,p_to_date,p_policy_type;
           
           else
            execute immediate v_sql
            into v_count
            USING p_from_date,p_to_date;
            
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('TOTAL POLICIES='||'  '||v_sql);
           
           
END;

/
BEGIN
    PRC_DYNAMIC_POLICY_REPORT
    (
        P_POLICY_TYPE => 'COMMERCIAL',
        P_FROM_DATE   => DATE '2026-01-01',
        P_TO_DATE     => DATE '2026-12-31'
    );
end;
/