SELECT * FROM POLICIES;
DESC POLICIES;
SELECT * FROM POLICY_HOLDERS;
SELECT * FROM VEHICLES;
SELECT * FROM PREMIUM_PAYMENTS ;
SELECT * FROM VEHICLE_INSPECTIONS ;
SELECT * FROM CLAIMS;
SELECT * FROM POLICY_AGENTS ;



/
Q1. =>
This procedure fetches all policy, vehicle, payment, and renewal details based on AGENT_ID and returns the information to the portal using SYS_REFCURSOR.

CREATE OR REPLACE PROCEDURE PRC_GET_AGENT_POLICIES
(
  P_AGENT_ID IN NUMBER,
  P_RESULT OUT SYS_REFCURSOR
  )
  IS
  BEGIN
                OPEN P_RESULT FOR 
                SELECT 
                               P.POLICY_ID,
                               P.POLICY_TYPE,
                               P.START_DATE,
                               P.END_DATE,
                               P.PREMIUM_AMOUNT,
                               PH.POL_HOLDER_ID,
                               PH.POL_HOLDER_NAME AS CUSTOMER_NAME,
                               PH.MOBILE_NO,
                               V.VEHICLE_ID,
                               V.VEHICLE_TYPE,
                               V.VEHICLE_NAME,
                               V.REGISTRATION_NUMBER,
                               NVL(PP.PAYMENT_STATUS,'PENDING') AS PAYMENT_STATUS,
                               PP.PAYMENT_DATE,
                               NVL(VI.INSPECTION_STATUS,'PENDING') AS INSPECTION_STATUS,
                               NVL(C.CLAIM_STATUS,'NO CLAM') AS CLAIM_STATUS,
                               CASE
                                         WHEN P.END_DATE<SYSDATE THEN 'LAPSED'
                                         WHEN P.END_DATE BETWEEN SYSDATE AND SYSDATE+30
                                         THEN 'RENEWAL DUE'
                                         ELSE 'ACTIVE'
                                END AS RENEWAL_STATUS
                      FROM POLICY_AGENTS PA 
                      INNER JOIN POLICIES P
                      ON PA.POLICY_ID=P.POLICY_ID
                      
                      INNER JOIN POLICY_HOLDERS PH
                      ON P.POL_HOL_ID=PH.POL_HOLDER_ID
                      
                      INNER JOIN VEHICLES V
                      ON P.VEHICLE_ID=V.VEHICLE_ID
                      
                      LEFT OUTER JOIN PREMIUM_PAYMENTS PP
                      ON P.POLICY_ID=PP.POLICY_ID
                      
                      LEFT OUTER JOIN VEHICLE_INSPECTIONS VI
                      ON V.VEHICLE_ID=VI.VEHICLE_ID
                      
                      LEFT OUTER JOIN CLAIMS C
                      ON P.POLICY_ID=C.POLICY_ID
                      
                      WHERE PA.AGENT_ID=P_AGENT_ID
                      ORDER BY P.END_DATE;
  END;
  
  /
SET SERVEROUTPUT ON;

select * from agents;
SELECT * FROM POLICIES;
select * from policy_holders;
select * from vehicles;
select * from customers;
SELECT * FROM PREMIUM_PAYMENTS;



policy id : 2001 | customer : mayur badgujar | vehicle : tata | status : active

/
DECLARE
    V_CUR SYS_REFCURSOR;

    V_POLICY_ID          POLICIES.POLICY_ID%TYPE;
    V_POLICY_TYPE        POLICIES.POLICY_TYPE%TYPE;
    V_START_DATE         DATE;
    V_END_DATE           DATE;
    V_PREMIUM_AMOUNT     POLICIES.PREMIUM_AMOUNT%TYPE;
    V_CUSTOMER_NAME      POLICY_HOLDERS.POL_HOLDER_NAME%TYPE;
    V_VEHICLE_NAME       VEHICLES.VEHICLE_NAME%TYPE;
    V_PAYMENT_STATUS     VARCHAR2(20);
    V_INSPECTION_STATUS  VARCHAR2(20);
    V_CLAIM_STATUS       VARCHAR2(20);
    V_RENEWAL_STATUS     VARCHAR2(20);
BEGIN

    PRC_GET_AGENT_POLICIES(101, V_CUR);

    LOOP
        FETCH V_CUR INTO
            V_POLICY_ID,
            V_POLICY_TYPE,
            V_START_DATE,
            V_END_DATE,
            V_PREMIUM_AMOUNT,
            -- skip POL_HOLDER_ID
            V_POLICY_ID,
            V_CUSTOMER_NAME,
            -- skip MOBILE_NO
            V_PAYMENT_STATUS,
            -- vehicle columns
            V_POLICY_ID,
            V_PAYMENT_STATUS,
            V_VEHICLE_NAME,
            V_PAYMENT_STATUS,
            V_PAYMENT_STATUS,
            -- payment date
            V_START_DATE,
            V_INSPECTION_STATUS,
            V_CLAIM_STATUS,
            V_RENEWAL_STATUS;

        EXIT WHEN V_CUR%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(----------------------------op
            'POLICY ID : ' || V_POLICY_ID ||
            ' | CUSTOMER : ' || V_CUSTOMER_NAME ||
            ' | VEHICLE : ' || V_VEHICLE_NAME ||
            ' | STATUS : ' || V_RENEWAL_STATUS
        );
    END LOOP;

    CLOSE V_CUR;
END;  
  
  /
  SET SERVEROUTPUT ON
  /
  
  2. PRC_SAVE_CUSTOMER_FOLLOWUP – 
  THIS PROCEDURE SAVES CUSTOMER FOLLOW-UP INFORMATION COLLECTED BY THE AGENT, SUCH AS CONTACT DETAILS, VEHICLE USAGE INFORMATION, 
  renewal discussion notes, inspection remarks, payment follow-up status, and additional commercial vehicle insurance details.

SELECT * FROM CUSTOMER_FOLLOWUPS;

CREATE TABLE CUSTOMER_FOLLOWUPS
(
    FOLLOWUP_ID                 NUMBER(10) PRIMARY KEY,

    AGENT_ID                    NUMBER(10) NOT NULL,

    POLICY_ID                   NUMBER(10) NOT NULL,

    CUSTOMER_CONTACT            VARCHAR2(20),

    VEHICLE_USAGE_INFO          VARCHAR2(200),

    RENEWAL_DISCUSSION_NOTES    VARCHAR2(500),

    INSPECTION_REMARKS          VARCHAR2(300),

    PAYMENT_FOLLOWUP_STATUS     VARCHAR2(30)
        CHECK (PAYMENT_FOLLOWUP_STATUS IN
              ('PENDING','SUCCESS','FAILED','FOLLOWUP_REQUIRED')) ,

    ADDITIONAL_INSURANCE_INFO   VARCHAR2(500),

    FOLLOWUP_DATE               DATE DEFAULT SYSDATE,

    NEXT_FOLLOWUP_DATE          DATE,

    CREATED_BY                  VARCHAR2(50),

    CREATED_DATE                DATE DEFAULT SYSDATE,

    CONSTRAINT FK_CF_AGENT
        FOREIGN KEY (AGENT_ID)
        REFERENCES AGENTS(AGENT_ID),

    CONSTRAINT FK_CF_POLICY
        FOREIGN KEY (POLICY_ID)
        REFERENCES POLICIES(POLICY_ID)
);

/
CREATE SEQUENCE SEQ_CUSTOMER_FOLLOWUP
START WITH 1001
INCREMENT BY 1
nocache
NOCYCLE;
/


/
INSERT INTO CUSTOMER_FOLLOWUPS
(
    FOLLOWUP_ID,
    AGENT_ID,
    POLICY_ID,
    CUSTOMER_CONTACT,
    VEHICLE_USAGE_INFO,
    RENEWAL_DISCUSSION_NOTES,
    INSPECTION_REMARKS,
    PAYMENT_FOLLOWUP_STATUS,
    ADDITIONAL_INSURANCE_INFO,
    NEXT_FOLLOWUP_DATE,
    CREATED_BY
)
VALUES
(
    SEQ_CUSTOMER_FOLLOWUP.NEXTVAL,
    101,
    3001,
    '9876543210',
    'Vehicle used for inter-state transport',
    'Customer interested in renewal next month',
    'Inspection documents pending',
    'PENDING',
    'Interested in roadside assistance add-on',
    TO_DATE('25-08-2026','DD-MM-YYYY'),
    'MAYUR'
);

COMMIT;
/

  /
1.Create Object Type


/
CREATE OR REPLACE TYPE FOLLOWUP_OBJ AS OBJECT
(
    AGENT_ID                   NUMBER,
    POLICY_ID                  NUMBER,
    CUSTOMER_CONTACT           VARCHAR2(20),
    VEHICLE_USAGE_INFO         VARCHAR2(200),
    RENEWAL_DISCUSSION_NOTES   VARCHAR2(500),
    INSPECTION_REMARKS         VARCHAR2(300),
    PAYMENT_FOLLOWUP_STATUS    VARCHAR2(30),
    ADDITIONAL_INSURANCE_INFO  VARCHAR2(500),
    NEXT_FOLLOWUP_DATE         DATE,
    CREATED_BY                 VARCHAR2(50)
);
/

2. Create List Type

/
CREATE OR REPLACE TYPE FOLLOWUP_OBJ_LIST
AS TABLE OF FOLLOWUP_OBJ;


/
3. PROCEDURE USING OBJECT AND LIST
/


CREATE OR REPLACE PROCEDURE PRC_SAVE_CUSTOMER_FOLLOWUP
(
    P_AGENT_ID                  IN NUMBER,
    P_POLICY_ID                 IN NUMBER,
    P_CUSTOMER_CONTACT          IN VARCHAR2,
    P_VEHICLE_USAGE_INFO        IN VARCHAR2,
    P_RENEWAL_DISCUSSION_NOTES  IN VARCHAR2,
    P_INSPECTION_REMARKS        IN VARCHAR2,
    P_PAYMENT_FOLLOWUP_STATUS   IN VARCHAR2,
    P_ADDITIONAL_INSURANCE_INFO IN VARCHAR2,
    P_NEXT_FOLLOWUP_DATE        IN DATE,
    P_CREATED_BY                IN VARCHAR2,
    P_STATUS                    OUT VARCHAR2,
    P_MESSAGE                   OUT VARCHAR2
)
AS
    V_COUNT NUMBER;
BEGIN

    -- Validate Policy Exists
    SELECT COUNT(*)
    INTO   V_COUNT
    FROM   POLICIES
    WHERE  POLICY_ID = P_POLICY_ID;

    IF V_COUNT = 0 THEN
        P_STATUS  := 'FAILED';
        P_MESSAGE := 'Policy ID does not exist';
        RETURN;
    END IF;

    -- Insert Follow-up Record
    INSERT INTO CUSTOMER_FOLLOWUPS
    (
        FOLLOWUP_ID,
        AGENT_ID,
        POLICY_ID,
        CUSTOMER_CONTACT,
        VEHICLE_USAGE_INFO,
        RENEWAL_DISCUSSION_NOTES,
        INSPECTION_REMARKS,
        PAYMENT_FOLLOWUP_STATUS,
        ADDITIONAL_INSURANCE_INFO,
        FOLLOWUP_DATE,
        NEXT_FOLLOWUP_DATE,
        CREATED_BY,
        CREATED_DATE
    )
    VALUES
    (
        SEQ_CUSTOMER_FOLLOWUP.NEXTVAL,
        P_AGENT_ID,
        P_POLICY_ID,
        P_CUSTOMER_CONTACT,
        P_VEHICLE_USAGE_INFO,
        P_RENEWAL_DISCUSSION_NOTES,
        P_INSPECTION_REMARKS,
        P_PAYMENT_FOLLOWUP_STATUS,
        P_ADDITIONAL_INSURANCE_INFO,
        SYSDATE,
        P_NEXT_FOLLOWUP_DATE,
        P_CREATED_BY,
        SYSDATE
    );

    COMMIT;

    P_STATUS  := 'SUCCESS';
    P_MESSAGE := 'Customer follow-up saved successfully';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        P_STATUS  := 'FAILED';
        P_MESSAGE := 'Error : ' || SQLERRM;
END;
/

/
SET SERVEROUTPUT ON;

DECLARE
    V_STATUS  VARCHAR2(20);
    V_MESSAGE VARCHAR2(200);
BEGIN

    PRC_SAVE_CUSTOMER_FOLLOWUP
    (
        101,
        3001,
        '9876543210',
        'Vehicle used for long-distance transport',
        'Customer interested in renewal next month',
        'Inspection documents pending',
        'PENDING',
        'Interested in accident and roadside assistance add-on',
        TO_DATE('25-08-2026','DD-MM-YYYY'),
        'MAYUR',
        V_STATUS,
        V_MESSAGE
    );

    DBMS_OUTPUT.PUT_LINE('STATUS  : ' || V_STATUS);
    DBMS_OUTPUT.PUT_LINE('MESSAGE : ' || V_MESSAGE);

end;
/
@C:\ORACLEXE\APP\ORACLE\PRODUCT\11.2.0\SERVER\RDBMS\ADMIN\PROFTAB.SQL;

select * from PLSQL_PROFILER_DATA;
select * from PLSQL_PROFILER_UNITS;
select * from PLSQL_PROFILER_RUNS;






SELECT *
from PLSQL_PROFILER_RUNS
ORDER BY RUNID DESC;

EXEC DBMS_PROFILER.START_PROFILER('PRC_GET_AGENT_POLICIES');
EXEC DBMS_PROFILER.STOP_PROFILER;
set serveroutput on;