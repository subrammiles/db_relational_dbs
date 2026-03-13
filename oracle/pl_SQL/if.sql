CREATE TABLE employee (
    emp_id number(15) NOT NULL,
    full_name varchar2(20) NOT NULL,
    PRIMARY KEY(emp_id)
);

INSERT
    ALL INTO employee (emp_id, full_name)
VALUES
    (21, 'Samantha') INTO employee (emp_id, full_name)
VALUES
    (22, 'Trump') INTO employee (emp_id, full_name)
VALUES
    (23, 'Jackie Chan') INTO employee (emp_id, full_name)
VALUES
    (24, 'Rama Siva')
SELECT
    *
FROM
    dual;



DECLARE
   V1   VARCHAR (10) := NULL;
    a number(2) := 10; 
 
BEGIN 
	a:= 10; 
IF (a<20) THEN 
   SELECT FULL_NAME  INTO V1 FROM EMPLOYEE e WHERE EMP_ID=21 ;
   dbms_output.put_line(v1); 
 END IF; 
IF (a>20) THEN 
   SELECT FULL_NAME  INTO V1 FROM EMPLOYEE e WHERE EMP_ID=24 ;
   dbms_output.put_line(v1); 
   END IF; 
END; 