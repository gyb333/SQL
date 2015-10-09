select plan_generation_num,SUBSTRING(qt.text,qs.statement_start_offset/2+1, 
(case when qs.statement_end_offset = -1 then DATALENGTH(qt.text) else qs.statement_end_offset end -qs.statement_start_offset)/2 + 1) as stmt_executing,
	qt.text,execution_count,sql_handle,dbid,db_name(dbid) DBName,objectid,object_name(objectid,dbid) ObjectName 
from sys.dm_exec_query_stats as qs Cross apply sys.dm_exec_sql_text(sql_handle) qt
where plan_generation_num >1
order by plan_generation_num

--SELECT   
--    DB_NAME(Blocked.database_id)                    AS 'database',  
--    Blocked.Session_ID                              AS 'blocked SPID',  
--    Blocked_SQL.TEXT                                AS 'blocked SQL',  
--    Waits.wait_type                 AS 'wait resource',  
--    Blocking.Session_ID                             AS 'blocking SPID',  
--    Blocking_SQL.TEXT                               AS 'blocking SQL',  
--    sess.status                 AS 'blocking status',  
--    sess.total_elapsed_time             AS 'blocking elapsed time',  
--    sess.logical_reads              AS 'blocking logical reads',  
--    sess.memory_usage               AS 'blocking memory usage',  
--    sess.cpu_time                   AS 'blocking cpu time',  
--    sess.program_name               AS 'blocking program',  
--    GETDATE()                                       AS 'timestamp'  
--FROM sys.dm_exec_connections AS Blocking   
--    INNER JOIN sys.dm_exec_requests AS Blocked ON Blocked.Blocking_Session_ID = Blocking.Session_ID  
--        INNER JOIN sys.dm_os_waiting_tasks AS Waits ON waits.Session_ID = Blocked.Session_ID  
--        INNER JOIN sys.dm_exec_sessions sess ON sess.session_id = Blocking.Session_ID  
--        CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS Blocking_SQL  
--        CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS Blocked_SQL  
--SELECT * FROM sys.sysprocesses WHERE spid>50
--KILL 52
--DBCC INPUTBUFFER(52)
-- =========================================
--���ݿ�������� ACID 

--ԭ���� (Atomictiy)��һ�������а�����һ�������߶�����乹����һ���������߼���Ԫ�����в����ٷֵ�ԭ���ԡ�Ҫôһ���ύִ��ȫ���ɹ���Ҫôһ���ύִ��ȫ��ʧ�ܡ�

--һ���� (Consistency)���������Ϊ���ݵ������ԣ�������ύҪȷ�������ݿ��ϵĲ���û���ƻ����ݵ������ԣ�����˵��ҪΥ��һЩԼ�������ݲ�������޸���Ϊ��

--������(Isolation)�������ݿ��е�������뼶���Լ�����أ�����û����Զ�ͬһ���ݲ������ʶ��ֲ��ƻ����ݵ���ȷ�Ժ������ԡ�����������޸ı�������������������޸��໥���������롣 �����ڲ�ͬ�ĸ��뼶���£�����Ķ�ȡ�������ܵõ��Ľ���ǲ�ͬ�ġ�

--�־���(Durability)�����ݳ־û�������һ�������ݵĲ�����ɲ��ύ�������޸ľ��Ѿ���ɣ���ʹ����������Щ����Ҳ����ı䡣

--�����г���������
--��� (Dirty Reads) : һ���������ڷ��ʲ��޸����ݿ��е����ݵ���û���ύ����������һ��������ܶ�ȡ����Щ�������޸ĵ�δ�ύ�����ݡ����ǵ�һ���������ܻع������ǵڶ�������ȴ��ȡ������Щ����ȷ�����ݡ�

--�����ظ���ȡ(Non-Repeatable Reads):  A �������ζ�ȡͬһ���ݣ�B����Ҳ��ȡ��ͬһ���ݣ����� A �����ڵڶ��ζ�ȡǰB�����Ѿ���������һ���ݡ����Զ���A������˵������һ�κ͵ڶ��ζ�ȡ������һ���ݿ��ܾͲ�һ���ˡ�����¼����ͬ�����ݲ�ͬ)

--�ö�(Phantom Reads):  A �����һ�β����ı���˵��ȫ������ݣ���ʱ B ���񲢲���ֻ�޸�ĳһ�������ݶ��ǲ�����һ�������ݣ����� A ����ڶ��ζ�ȡ��ȫ���ʱ��ͷ��ֱ���һ�ζ���һ�����ݣ������þ��ˡ�(��¼����ͬ)

--���¶�ʧ(Lost Update): ��������ͬʱ���£�����ĳһ���������ʧ�ܷ����ع����������ܵڶ��������Ѹ��µ�������Ϊ��һ���������ع���������������û�з������¡�

IF OBJECT_ID('TranTableName', 'U') IS NOT NULL
  DROP TABLE TranTableName
GO

CREATE TABLE TranTableName
(
	TranID INT NOT NULL IDENTITY,				
	TranColumnName NVARCHAR(50) NOT NULL,	
	Remark NVARCHAR(100) DEFAULT ''						
)
GO
INSERT INTO TranTableName(TranColumnName) VALUES('aa')
-----------------------------------�����ͬһ������)------------------
------------------------����A--------------
--Read committed  Ĭ��Ϊ�ύ��
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
--DBCC USEROPTIONS
BEGIN TRANSACTION 
UPDATE TranTableName SET TranColumnName='new'+STR(10*RAND(10)+RAND(10)) WHERE TranID=1
WAITFOR DELAY '00:00:10'
ROLLBACK TRANSACTION
---------------------------------------------
----------------------����B------------------
--READ UNCOMMITTED (δ�ύ��)Ĭ�������
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION

---------------------------------------------
----------------------����B------------------
--READ COMMITTED (�ύ��)  ��������������(��Ȼ���ڲ����ظ�������)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION

----------------�����ظ���ȡ(ͬһ����)-----------------------------
--Repeatable Read (������ظ���û�н���ö�������)
----------------------����A----------
SET TRANSACTION ISOLATION LEVEL  REPEATABLE READ
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION
------------------------------------
----------------------����B---------
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='new'+STR(10*RAND(10)+RAND(10)) WHERE TranID=1
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
------------------------------------
----------------�ö�(ͬһ����)-----------------------------
--���ÿ��ռ���Ĭ�����ݿⲻ����
ALTER DATABASE Test SET ALLOW_SNAPSHOT_ISOLATION ON

----------------------����A----------
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName 
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
COMMIT TRANSACTION
------------------------------------
----------------------����B---------
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
INSERT INTO TranTableName(TranColumnName) VALUES('bb')
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
------------------------------------

-----------���¶�ʧ------------
----------------------����A----------
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
DBCC USEROPTIONS
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='����A����' WHERE TranID=1
WAITFOR DELAY  '00:00:10'
ROLLBACK TRANSACTION
SELECT *,GETDATE() 'SERIALIZABLE' FROM TranTableName WHERE TranID=1

------------------------------------
----------------------����B---------
SET TRANSACTION ISOLATION LEVEL  READ COMMITTED
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='����B����' WHERE TranID=1
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
------------------------------------
--SERIALIZABLE(���л�):������������ʾ�����������ȸ���������ǵȴ���������ִ����
--���ܶ�ȡ�����������������޸ĵ���û���ύ�����ݣ�
--���������������ڵ�ǰ��������޸�֮ǰ�޸��ɵ�ǰ�����ȡ�����ݣ�
--���������������ڵ�ǰ��������޸�֮ǰ�����µ��С�
----------------------����A----------
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION
SELECT GETDATE()
------------------------------------

----------------------����B---------
SET TRANSACTION ISOLATION LEVEL  READ COMMITTED
BEGIN TRANSACTION
SELECT GETDATE() AS 'Select'
SELECT * FROM dbo.TranTableName
SELECT GETDATE() AS 'Update'
UPDATE TranTableName SET TranColumnName='����' WHERE TranID=1
SELECT GETDATE() AS 'Insert'
INSERT INTO TranTableName(TranColumnName) VALUES('���»��߲���')
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
------------------------------------

-------------------------------

--�α����ʾ��


--����һ���α�
DECLARE CurTest CURSOR SCROLL FOR SELECT TranID,TranColumnName FROM dbo.TranTableName;

--���α�
OPEN CurTest;

--�洢��ȡ��ֵ
DECLARE @TranID INT,@TranColumnName NVARCHAR(20)
        
--��ȡ��һ����¼
FETCH FIRST FROM CurTest INTO @TranID,@TranColumnName;

--ѭ����ȡ�α��¼
--ȫ�ֱ���
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SELECT @TranID,@TranColumnName
	 --������ȡ��һ����¼
	 FETCH NEXT FROM CurTest INTO @TranID,@TranColumnName;
END


--�ر��α�
CLOSE CurTest;

--ɾ���α�
DEALLOCATE CurTest;


SELECT * FROM sys.dm_tran_locks

SELECT STR(request_session_id,4,0) AS spid,
CONVERT(VARCHAR(20),DB_NAME(resource_database_id)) AS DB_NAME,
CASE WHEN resource_database_id=DB_ID() AND resource_type='OBJECT' THEN CONVERT(CHAR(20),OBJECT_NAME(resource_associated_entity_id))
ELSE CONVERT(CHAR(20),resource_associated_entity_id) END AS OBJECT,
CONVERT(VARCHAR(12),resource_type) AS ResourceType,
CONVERT(VARCHAR(12),request_type) AS RequestType,
CONVERT(CHAR(3),request_mode) AS Mode,
CONVERT(VARCHAR(8),request_status) AS Status
FROM sys.dm_tran_locks
ORDER BY request_session_id,3 DESC

--��commit��rollback����
--�������
SELECT * FROM dbo.TranTableName WITH(ROWLOCK)  WHERE TranID =1

---�������ݿ�ı� 
SELECT * FROM dbo.TranTableName WITH(HOLDLOCK)

--������ 
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='new'+STR(CAST(100*RAND()+10*RAND() AS INT)) WHERE TranID=1
WAITFOR DELAY  '00:00:10'
COMMIT TRANSACTION

--������
BEGIN TRANSACTION
SELECT * FROM dbo.TranTableName WITH(HOLDLOCK)
WAITFOR DELAY  '00:00:10'
COMMIT TRANSACTION
SELECT GETDATE()

BEGIN TRANSACTION
SELECT * FROM dbo.TranTableName
UPDATE TranTableName SET TranColumnName='new'+STR(CAST(100*RAND()+10*RAND() AS INT)) WHERE TranID=2
COMMIT TRANSACTION


--����32λWindows�û�������4GB�������ַ�ռ䡣����2GB������̬��ʣ��2GB���û�̬�����������ϸ�ֿ���Windows������Ϊ����ĳһ���ڴ��ַ�ռ��þ���������һ��Ŀռ��ó���

 

--����SQLSERVER�ľ��󲿷�ָ��������û�̬�£�����˵SQLSERVER���ڴ������ʹ���û�̬��ַ�ռ���Դ�����ڵ������2GB��ַ�ռ���Դ����SQLSERVER��˵�����谭��SQLSERVER��Ч����Ӳ����Դ

 

--����SQLSERVER������AWE address windowsing extensions(��ַ�ռ���չ)����������32λӦ�ó������64GB�����ڴ棬������ͼ�򴰿�ӳ�䵽2GB�����ַ�ռ�Ļ��ơ�

Exec sys.sp_configure								
Exec sys.sp_configure 'show advanced options',1		
Reconfigure With Override
Exec sys.sp_configure 'awe enabled' ,1
Reconfigure With Override
Exec sys.sp_configure 'max server memory (MB)',6000
Reconfigure With Override
--��ʱ��������
--��ʱ�������ñ����ƣ�ֻ�Ǵ�����Tempdb�У���ֻ����һ�����ݿ����ӽ����������SQL����DROP�����Ż���ʧ������ͻ�һֱ���ڡ�
--��ʱ���Ϊ���غ�ȫ�����֣�������ʱ������ƶ����ԡ�#��Ϊǰ׺�����ص�ǰ�û������в��ǿɼ��ģ��û���ʵ���Ͽ�����ʱ��ɾ����ȫ����ʱ������ƶ����ԡ�##��Ϊǰ׺����������κ��û����ǿɼ��ģ����������øñ���û��Ͽ�����ʱ��ɾ���� 

--������Ǳ�����һ�֣������Ҳ��Ϊ���ؼ�ȫ�ֵ����֣����ر���������ƶ����ԡ�@��Ϊǰ׺��ֻ���ڱ��ص�ǰ���û������вſ��Է��ʡ�ȫ�ֵı���������ƶ����ԡ�@@��Ϊǰ׺��һ�㶼��ϵͳ��ȫ�ֱ����������ǳ��õ��ģ��� @@Error�������ĺţ�@@RowCount����Ӱ��������� 

--������Ǵ洢���ڴ��еģ����û��ڷ��ʱ������ʱ��SQL Server�ǲ�������־�ģ�������ʱ�����ǲ�����־��; 
--�ڱ�����У��ǲ������зǾۼ�������; 
--������ǲ�������DEFAULTĬ��ֵ��Ҳ��������Լ��; 
--��ʱ���ϵ�ͳ����Ϣ�ǽ�ȫ���ɿ��ģ����Ǳ�����ϵ�ͳ����Ϣ�ǲ��ɿ���; 
--��ʱ�����������Ļ��ƣ���������о�û�����Ļ��ơ� 


IF OBJECT_ID('#TempTable', 'U') IS NOT NULL
  DROP TABLE #TempTable
GO

CREATE TABLE #TempTable(id INT IDENTITY(1,1),NAME VARCHAR(10))
INSERT INTO  #TempTable(NAME)  VALUES ('Old')
DECLARE @TableVariable TABLE (id INT IDENTITY(1,1), NAME VARCHAR(10))
INSERT INTO @TableVariable(NAME)  VALUES ('Old')

BEGIN TRAN
UPDATE #TempTable SET name='New' WHERE id=1
UPDATE @TableVariable set name ='New' WHERE id=1
ROLLBACK
SELECT * FROM #TempTable
SELECT * FROM @TableVariable

--���󻺴�
DBCC  FreeProcCache	--�ͷŻ���
--�ֱ𵥶�ִ��������䣬��������ƻ�
select ����id from ���� where ����ID=2
go
select ����id from ���� where ����ID=1
go
select ����id from ���� where ����ID=3
go
select ����id from ���� where ����ID=4
go

IF OBJECT_ID('P_order','P') IS NOT NULL
	DROP PROC p_order
GO	
CREATE PROC P_order
@orderid INT 
As
BEGIN
	SELECT ����id FROM ���� WHERE  ����ID=@orderid
END
GO
exec P_order 1
exec P_order 2
exec P_order 3
exec P_order 4
GO
SELECT cacheobjtype,objtype,usecounts,sql 
FROM sys.syscacheobjects 
WHERE sql NOT LIKE '%cache%' AND sql NOT LIKE '%sys.%' 

-----------����ʵ��-----------
--������²�����
Begin Tran
	Update ��Ʒ Set �����=30 where ��ƷID=1
	
Waitfor delay '0:00:20'	
ROLLBACK


--���������ѯ��ʱ����

Select * from ��Ʒ
---------------------------------------
------------����-----------------------
---��һ���������ȸ���A���ٸ���B��------
Begin TRAN
	Update ��Ʒ set �����=�����+1 where ��ƷID=1
	Waitfor delay '0:00:05'
	Update �ͻ� Set ��˾����='��������'
			where �ͻ�ID='Frank'
COMMIT
----�ڶ����������ȸ���B���ٸ���A��-------------
Begin TRAN
	Update �ͻ� Set ��˾����='��������'
			where �ͻ�ID='Frank'
	Waitfor delay '0:00:05'
	Update ��Ʒ set �����=�����+1 
			where ��ƷID=1
COMMIT
--��һ����������ִ�н���
-------------------------------------------

--�鿴��ǰʵ��������
Exec sp_configure
--�޸ĸ߼�ѡ�����ʾ����
Exec sp_configure 'show advanced options',1
--�����������̱��淧ֵΪ5��
Exec sp_configure 'blocked process threshold (s)',5
--���޸�����������Ч
Reconfigure With Override

-------------������Ż�
--��ѯ����Ż����������ı������ע��where �е��ֶ�˳���ȹ����������ģ��ܾ�����С���ݷ�Χ�ĵȡ�
--�����Ż���������������á�����������
--��ṹ�Ż����������������������ߺ����ֱ�����𣬽�ǰn���ֶη���һ��������m������һ������������һ�����������ݷ�һ�������繫˾Ա���ر�࣬�й�Ա��һ����Ů��Ա��һ����������һ����
--�洢��ʽ�Ż���ͨ����ͬ�Ĵ洢�ռ���߱�����������ݴ���ڲ�ͬ�Ĵ洢���򣬴ﵽ�������IO��Ŀ��
set statistics io ON			--�鿴IOͳ��
IF object_ID('t2','U') IS NOT NULL
	DROP TABLE t2
GO
select * into t2 from ������ϸ
select *  from t2  where ����*����=640

--�ڵ����Ͻ�����
create index ix_price on t2(����)
select *  from t2  where ����*����=640

--�������Ͻ�����
  create index ix_Qty on t2(����)
  select *  from t2  where ����*����=640
  
--���������
  DROP INDEX ix_price ON t2
  DROP INDEX  ix_Qty ON t2 
  DROP INDEX ix_Price_Qty ON t2
  CREATE INDEX ix_Price_Qty on t2(����,����)
  SELECT *  FROM t2  where ����*����=640
  
--�������ַ�ʽ���޷��Ż��������
  
ALTER table t2 ADD SubTotal As ����*���� PERSISTED --����������
--�ڼ������ϴ�������
--DROP INDEX ix_subTotal ON t2
CREATE INDEX ix_subTotal on t2(subTotal)
SELECT *  FROM t2  WHERE  ����*����=640		--IO�ͱ�С��
--�������ѯʱ��where������Ϊ������*���ۣ�
select * from t2 where ����*����=640		--IO������ø���

--����
CREATE TABLE TestIdentity (id INT IDENTITY,NAME CHAR(20))
INSERT INTO TestIdentity VALUES('joe')
SELECT * FROM TestIdentity		--identity�Ǳ��ڲ���,���ܹ�����������

CREATE TABLE Employees(EmployeeId INT NOT NULL PRIMARY KEY, Name NVARCHAR(255) NULL);

CREATE TABLE Contractors(ContractorId INT NOT NULL PRIMARY KEY,Name NVARCHAR(255) NULL);

--��������
CREATE SEQUENCE IdSequence AS INT START WITH 10000  INCREMENT BY 1; --�������п����ظ�ʹ��
--------��������--------
--����Ҫ�����¼ʱ,����ֱ�Ӵ�������������,��֤�õ���id�Ǵ���û�ù���
INSERT INTO Employees (EmployeeId, Name) VALUES (NEXT VALUE FOR IdSequence, 'Jane');
--������������¼ʱ,Ҳֱ�Ӵ���������,�õ���idҲ�Ǵ���û�ù���.
INSERT INTO Contractors (ContractorId, Name) VALUES (NEXT VALUE FOR IdSequence, 'John');

SELECT * FROM Employees;
SELECT * FROM Contractors;

SELECT ID,Name,NEXT VALUE FOR IdSequence OVER(ORDER BY Name DESC) As SNO FROM Employees

--��������֮�󣬿��Զ����н����޸�
alter sequence idsequence INCREMENT BY 1 MINVALUE 10000 MAXVALUE 10003 CYCLE

--������ͼ
Create Table Orders(OrderId int Identity NOT NULL,
	 CustId int NOT NULL,   --1~~30000
	 ProductId int NOT NULL,  --1~~2000
	 EmpId int NOT NULL,		--1~~1000
	 Unitprice money NOT NULL,  --10~~10000
	 Quantity int NOT NULL,    --1~50000
	 OrderDate datetime NOT NULL,  --2000~����
	 Note char(100) NOT NULL)
--����100��������
Exec sp_spaceused Orders
--������ǰ�Ự��IOͳ��
Set Statistics IO ON
SELECT * FROM Orders Where OrderDate >'2013-4-12 16:00:00'

Create Index IX_OrderDate On Orders(OrderDate)

Select * from Orders Where OrderDate >'2013-4-12 16:00:00'
--IO�����˺ܶ�
Select * from Orders Where OrderDate >'2010-4-10 16:00:00'
--������
DROP TABLE dbo.Orders2013
DROP TABLE dbo.Orders2012
DROP TABLE dbo.Orders2009
DROP TABLE dbo.Orders2005

SELECT * INTO Orders2013 FROM Orders WHERE YEAR(Orderdate)>=2013
SELECT * INTO Orders2012 FROM Orders WHERE YEAR(Orderdate) BETWEEN 2010 AND 2012
SELECT * INTO Orders2009 FROM Orders WHERE YEAR(Orderdate) BETWEEN 2006 AND 2009
SELECT * INTO Orders2005 FROM Orders WHERE YEAR(Orderdate) <= 2005
	go
--����������ͼ		
CREATE VIEW pvOrders as 
	SELECT * FROM Orders2013 UNION ALL
	SELECT * FROM Orders2012 UNION ALL
	SELECT * FROM Orders2009  UNION ALL
	SELECT * FROM Orders2005
	go
	
SELECT * FROM Orders WHERE OrderDate >='2013-1-1'
SELECT * FROM pvOrders WHERE OrderDate >='2013-1-1'
--�ֱ�����������CHECKԼ��
ALTER TABLE Orders2013 ADD CONSTRAINT CK_Date4 CHECK (Orderdate >='2013-1-1' )
ALTER TABLE Orders2012 ADD CONSTRAINT CK_Date3 CHECK (Orderdate >='2010-1-1' and Orderdate<'2013-1-1')
ALTER TABLE Orders2009 ADD CONSTRAINT CK_Date2 CHECK (Orderdate >='2006-1-1' and Orderdate<'2010-1-1')
ALTER TABLE Orders2005 ADD CONSTRAINT CK_Date1 CHECK (Orderdate<'2006-1-1')

SELECT * FROM pvOrders WHERE OrderDate >='2013-1-1'
--��������
CREATE INDEX ix_Orders2013_OrderDate ON orders2013(OrderDate)

--������䲻��������
SELECT * FROM pvOrders Where OrderDate >='2013-1-1'

--���������õ���������Ϊ���صļ�¼���Ƚ��٣�
SELECT * FROM pvOrders Where OrderDate >='2013-10-15 23:00:00'

--������
Select * from Orders where OrderDate >='2013-1-1'

DROP PARTITION FUNCTION fn_ByDate
DROP PARTITION SCHEME ps_ByDate

--����������ȷ���˷ֶ�����
Create Partition Function fn_ByDate (DateTime)
	AS Range Right
	For Values('2005-1-1','2010-1-1','2011-1-1',
		'2012-1-1','2013-1-1','2014-1-1')
Go
--������������
Create Partition Scheme ps_ByDate
	AS Partition fn_ByDate
	To ([Primary],[Primary],[Primary],[Primary]
	,[Primary],[Primary],[Primary],[Primary]
	,[Primary],[Primary],[Primary],[Primary])
GO

DROP TABLE dbo.Orders2
--Ӧ�÷����������½��ı�
Create Table Orders2
	(OrderId int ,
	 CustId int,   --1~~30000
	 ProductId int,  --1~~2000
	 EmpId int,		--1~~1000
	 Unitprice money,  --10~~10000
	 Quantity int,    --1~50000
	 OrderDate datetime,  --2000~����
	 Note char(100))
On ps_ByDate(OrderDate)
--��������
INSERT Orders2 SELECT * FROM Orders
--�����ֶ���Ϊ����
Select * from Orders2 where OrderDate >='2013-1-1'

--���б�ָ�������������ڱ������ָ����
CREATE CLUSTERED INDEX ix_orders_OrderDate ON dbo.Orders(OrderDate) ON ps_ByDate(OrderDate)
DROP INDEX ix_orders_OrderDate ON dbo.Orders

--������ת��:��һ����ķ����ҵ�����һ��������,��ṹһ��,����һ��
DROP TABLE dbo.Orders_change
Create Table Orders_change
	(OrderId int ,
	 CustId int,   --1~~30000
	 ProductId int,  --1~~2000
	 EmpId int,		--1~~1000
	 Unitprice money,  --10~~10000
	 Quantity int,    --1~50000
	 OrderDate datetime,  --2000~����
	 Note char(100))
On ps_ByDate(OrderDate)

alter table orders2 switch partition 1 to orders_change partition 1

--��ѯ��orders
select * from Orders2 where OrderDate<='2004-11-1'
--�յ�

--��ѯ��orders_change
select * from Orders_change where OrderDate<='2004-11-1'

-----�����Ĳ��

--ָ���¸��������ڵ��ļ���
ALTER PARTITION SCHEME ps_ByDate NEXT USED [primary]

--���ӷ��������ı߽�ֵ
ALTER PARTITION FUNCTION fn_ByDate () SPLIT RANGE ('2008-1-1')

-----�����ĺϲ�
ALTER PARTITION FUNCTION fn_ByDate () MERGE RANGE ('2008-1-1')

--��������ͳ�Ʊ�
SELECT ProductId,SUM(Quantity),SUM(Unitprice*Quantity)
From Orders
Group by ProductId
Order by SUM(Unitprice*Quantity) DESC
--18189 ��,17.7


--����ˢ��ͳ�Ʊ�
IF OBJECT_ID('OrdersSummary','u') IS NOT NULL 
DROP TABLE OrdersSummary
SELECT  ProductId,SUM(Quantity) SumQuantity,SUM(Unitprice*Quantity) SalesAmount
Into OrdersSummary
From Orders
Group by ProductId
Order by SUM(Unitprice*Quantity) DESC
	
SELECT * FROM OrdersSummary


--������ͼ
SELECT * INTO orders3 from Orders

--ִ������������õĿ���
Select  ProductId,SUM(Quantity) ,SUM(Unitprice*Quantity) 
From dbo.orders3
Group by ProductId
	
GO
--����������ͼ
CREATE VIEW vOrdersSummary WITH SCHEMABINDING AS
SELECT ProductId,SUM(Quantity) SumQuantity
				,SUM(Unitprice*Quantity) SumAmount,COUNT_BIG(*) cb
From dbo.orders3
Group by ProductId
Go
--����ͼ�Ͻ�Ωһ�ۼ�����
CREATE UNIQUE CLUSTERED INDEX UCX_ProductId on vOrdersSummary(ProductId)

SELECT * FROM dbo.vOrdersSummary

SELECT  ProductId,SUM(Quantity),SUM(Unitprice*Quantity)
From orders3
Group by ProductId
Order by SUM(Unitprice*Quantity) DESC
--11 ��,0.05


--����
--�ѱ�û�оۼ������ı���¼ͨ��IAMҳ�Լ�PFSҳ��ȷ����ҳ�п��пռ䡣
--�ۼ��������оۼ������ı���¼�Ǹ��ݾۼ���ֵ����ҳ�ļ�ֵ�߼�˳��ά����
CREATE TABLE HeapTable(id INT IDENTITY,NAME NVARCHAR(20))
--����10������
INSERT INTO  HeapTable VALUES('Heap');
SELECT * FROM HeapTable
--ɾ����������
DELETE HeapTable WHERE id in (4,6)
--���������������
INSERT INTO HeapTable values('joe')
INSERT INTO HeapTable values('GYB')

CREATE TABLE ClusteredIndexTable(id INT IDENTITY PRIMARY KEY CLUSTERED,NAME NVARCHAR(20))
--����10������
INSERT INTO  ClusteredIndexTable VALUES('Clustered');
--ɾ����������
DELETE ClusteredIndexTable WHERE id in (4,6)
SELECT * FROM ClusteredIndexTable

--���������������
INSERT INTO ClusteredIndexTable values('joe')
INSERT INTO ClusteredIndexTable values('GYB')

--�ۼ�������Ǿۼ�����
--�ڱ��ѯ�У��ۼ��������� > �Ǿۼ��������� > ����ɨ�� > ��ɨ��
SELECT * INTO OrderIndex FROM dbo.Orders
--��Ӿۼ�����
ALTER TABLE OrderIndex  ADD CONSTRAINT PK_Orderid primary key (OrderId)
DROP TABLE OrderIndex
--�Ǿۼ�����
DROP INDEX ix_ProductId ON OrderIndex
CREATE  INDEX ix_ProductId   ON OrderIndex(ProductId) 

sp_helpindex orderIndex

SELECT OrderID,ProductID FROM OrderIndex WHERE EmpId=258

SELECT * FROM OrderIndex WHERE EmpId=824

SELECT ProductID,CustId ,EmpId ,Unitprice ,Quantity FROM orderIndex

SELECT * FROM OrderIndex WHERE OrderId=10249
SELECT OrderID FROM OrderIndex
SELECT ProductId FROM OrderIndex WHERE OrderId=10249 AND ProductId =895 AND EmpId=258

select * from OrderIndex where    OrderId=10249 AND ProductId =895

select  * from OrderIndex where  ProductId+1 =895
select  OrderID,ProductID  from OrderIndex where  ProductId =895 


CREATE INDEX ix_custid_productid ON dbo.OrderIndex(CustId,ProductId)

SELECT CustId,ProductId FROM dbo.OrderIndex WHERE CustId =895
SELECT CustId,ProductId FROM dbo.OrderIndex WHERE ProductId =895 

SELECT CustId,ProductId,orderid FROM dbo.OrderIndex WHERE CustId =895
--�鿴������Ƭ���
DECLARE @n INT
SET @n = DB_ID() 

SELECT  DB_NAME(a.database_id) [db_name] ,
        c.name [table_name] ,
        b.name [index_name] ,
        a.page_count,
        a.avg_fragmentation_in_percent
FROM    sys.dm_db_index_physical_stats(@n, NULL, NULL, NULL, 'Limited') AS a
        JOIN sys.indexes AS b ON a.object_id = b.object_id
                                 AND a.index_id = b.index_id
        JOIN sys.tables AS c ON a.object_id = c.object_id
WHERE   a.index_id > 0
        AND a.avg_fragmentation_in_percent > 0 AND c.name ='OrderIndex'
        
        --�鿴��������Ƭ
DBCC SHOWCONTIG(OrderIndex)
DBCC SHOWCONTIG(OrderIndex,ix_ProductId)

--������֯����
ALTER INDEX ix_orderid On OrderIndex REORGANIZE
	
--�ؽ�����
ALTER INDEX ix_orderid On OrderIndex REBUILD
------------------ SQL2000�Ĵ���
--��Ƭ����
dbcc indexdefrag(NorthwindCS,Orders)
--������������
DBCC DBREINDEX(Orders,ix_orderid)

-----------------�����������
Create Index NX_CustId On Orders(CustId) With FillFactor = 60

--SQL2005
Alter Index ix_orderid On orders REBUILD WITH (FillFactor = 60)
	
--SQL2005��������	
Alter Index ix_orderid On orders Rebuild With (online=ON,FillFactor = 60)
	
--SQL2000

DBCC DBREINDEX(Orders,ix_orderid,90)

SELECT * FROM orders WHERE CustId=10000

DBCC SHOW_STATISTICS	('OrderIndex','ix_ProductId') 
	
Update �ͻ�  Set  ����='����' 
			where �ͻ�ID='ALFKI'
	
--Update Statistics ����

--Update Statistics ���� ������

Update Statistics �ͻ� ����
DBCC SHOW_STATISTICS


--������ʾ,ǿ��SQL Server ʹ������
Select * from OrderIndex with (INDEX=ix_ProductId) where ProductId =895


