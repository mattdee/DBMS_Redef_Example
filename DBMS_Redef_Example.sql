/* Redefinition example */

/* Create base table */
create table test_table
	(
		emp_id 		number,
	 	name		varchar2(500),
	 	salary		number,
	 	hiredate	date,
	 	primary key (emp_id)
	 )
/

/* Make sure the table has no partitions */
SELECT COUNT(*) FROM DBA_TAB_PARTITIONS WHERE TABLE_NAME = 'TEST_TABLE' ;



/* Insert some random data */
declare
	type t_test is table of test_table%ROWTYPE;
	l_howmany	NUMBER := 10;
	l_test t_test := t_test();

	begin
		for i in 1..l_howmany loop
			l_test.extend;

			l_test(l_test.last).emp_id		:= dbms_random.value(1, 99999);
			l_test(l_test.last).name		:= dbms_random.string( 'a', TRUNC( dbms_random.value( 1, 99 ) ) );
			l_test(l_test.last).salary		:= dbms_random.value(10, 99999);
			l_test(l_test.last).hiredate	:= TO_DATE (TRUNC (DBMS_RANDOM.VALUE (2451545, 5373484) ), 'J');
	end loop;

	forall x in l_test.first .. l_test.last
		insert into test_table values l_test(x);
		commit;

	end;
	/


/* Create a new partitioned table */
create table INTERIM_TEST_TABLE
	(
		emp_id 		number,
	 	name		varchar2(500),
	 	salary		number,
	 	hiredate	date,
	 	primary key (emp_id)
	 )
	partition by range (hiredate) 
interval (numtoyminterval(1,'month'))  /* you can change year to month to increase the number of partitions created */
(
	partition "p1" values less than (to_date('11/1/1995','mm/dd/yyyy'))
)
/

/* Check to make sure the table can be refined */
/* No output = no error */
BEGIN 
DBMS_REDEFINITION.CAN_REDEF_TABLE (
	uname => 'MATT', 
	tname => 'TEST_TABLE'
	);
END;
/


/* Start the redefinition process */
 BEGIN
  DBMS_REDEFINITION.START_REDEF_TABLE (
    uname          => 'MATT',
    orig_table     => 'TEST_TABLE',
    int_table      => 'INTERIM_TEST_TABLE',
    col_mapping    => 'EMP_ID EMP_ID, NAME NAME, SALARY SALARY, HIREDATE HIREDATE',
    options_flag   => DBMS_REDEFINITION.CONS_USE_PK
    );
END;
/


/* Copy the original tables constraints, indexes, privileges, stats */
DECLARE
num_errors PLS_INTEGER ;
BEGIN
DBMS_REDEFINITION.COPY_TABLE_DEPENDENTS (
	'MATT', 
	'TEST_TABLE',
	'INTERIM_TEST_TABLE',
	DBMS_REDEFINITION.CONS_ORIG_PARAMS, 
	TRUE, 
	TRUE, 
	TRUE, 
	TRUE, 
	num_errors       
	);
END;
/


/* Apply captured changed to interim table */
BEGIN
DBMS_REDEFINITION.SYNC_INTERIM_TABLE (
   uname                   => 'MATT',
   orig_table              => 'TEST_TABLE',
   int_table               => 'INTERIM_TEST_TABLE'
   );
END;
/


/* Finish the redefinition process */
BEGIN 
DBMS_REDEFINITION.FINISH_REDEF_TABLE(
   uname                   => 'MATT',
   orig_table              => 'TEST_TABLE',
   int_table               => 'INTERIM_TEST_TABLE'
   );
END;
/


/* Drop the interim table */
drop table INTERIM_TEST_TABLE purge; 

/* Check to make sure the table now has partitions */
SELECT COUNT(*) FROM DBA_TAB_PARTITIONS WHERE TABLE_NAME = 'TEST_TABLE' ;










