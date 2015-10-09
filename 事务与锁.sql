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
--数据库中事务的 ACID 

--原子性 (Atomictiy)：一个事务中包含的一条语句或者多条语句构成了一个完整的逻辑单元，具有不可再分的原子性。要么一起提交执行全部成功，要么一起提交执行全部失败。

--一致性 (Consistency)：可以理解为数据的完整性，事务的提交要确保在数据库上的操作没有破坏数据的完整性，比如说不要违背一些约束的数据插入或者修改行为。

--隔离性(Isolation)：与数据库中的事务隔离级别以及锁相关，多个用户可以对同一数据并发访问而又不破坏数据的正确性和完整性。并行事务的修改必须与其它并行事务的修改相互独立，隔离。 但是在不同的隔离级别下，事务的读取操作可能得到的结果是不同的。

--持久性(Durability)：数据持久化，事务一旦对数据的操作完成并提交后，数据修改就已经完成，即使服务重启这些数据也不会改变。

--事务中常见的问题
--脏读 (Dirty Reads) : 一个事务正在访问并修改数据库中的数据但是没有提交，但是另外一个事务可能读取到这些已作出修改但未提交的数据。就是第一个操作可能回滚，但是第二个事务却读取到了这些不正确的数据。

--不可重复读取(Non-Repeatable Reads):  A 事务两次读取同一数据，B事务也读取这同一数据，但是 A 事务在第二次读取前B事务已经更新了这一数据。所以对于A事务来说，它第一次和第二次读取到的这一数据可能就不一致了。（记录数相同，内容不同)

--幻读(Phantom Reads):  A 事务第一次操作的比如说是全表的数据，此时 B 事务并不是只修改某一具体数据而是插入了一条新数据，而后 A 事务第二次读取这全表的时候就发现比上一次多了一条数据，发生幻觉了。(记录数不同)

--更新丢失(Lost Update): 两个事务同时更新，由于某一个事务更新失败发生回滚操作，可能第二个事务已更新的数据因为第一个事务发生回滚而导致数据最终没有发生更新。

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
-----------------------------------脏读（同一事务中)------------------
------------------------事务A--------------
--Read committed  默认为提交读
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
--DBCC USEROPTIONS
BEGIN TRANSACTION 
UPDATE TranTableName SET TranColumnName='new'+STR(10*RAND(10)+RAND(10)) WHERE TranID=1
WAITFOR DELAY '00:00:10'
ROLLBACK TRANSACTION
---------------------------------------------
----------------------事务B------------------
--READ UNCOMMITTED (未提交读)默认是脏读
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION

---------------------------------------------
----------------------事务B------------------
--READ COMMITTED (提交读)  导致阻塞解决脏读(仍然存在不可重复读问题)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION

----------------不可重复读取(同一事务)-----------------------------
--Repeatable Read (解决可重复读没有解决幻读的问题)
----------------------事务A----------
SET TRANSACTION ISOLATION LEVEL  REPEATABLE READ
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION
------------------------------------
----------------------事务B---------
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='new'+STR(10*RAND(10)+RAND(10)) WHERE TranID=1
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
------------------------------------
----------------幻读(同一事务)-----------------------------
--设置快照级别（默认数据库不允许）
ALTER DATABASE Test SET ALLOW_SNAPSHOT_ISOLATION ON

----------------------事务A----------
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName 
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
COMMIT TRANSACTION
------------------------------------
----------------------事务B---------
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
INSERT INTO TranTableName(TranColumnName) VALUES('bb')
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
------------------------------------

-----------更新丢失------------
----------------------事务A----------
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
DBCC USEROPTIONS
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='事务A更新' WHERE TranID=1
WAITFOR DELAY  '00:00:10'
ROLLBACK TRANSACTION
SELECT *,GETDATE() 'SERIALIZABLE' FROM TranTableName WHERE TranID=1

------------------------------------
----------------------事务B---------
SET TRANSACTION ISOLATION LEVEL  READ COMMITTED
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='事务B更新' WHERE TranID=1
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
------------------------------------
--SERIALIZABLE(序列化):设置这个级别表示其他事务必须等该事务或者是等待其他事务执行完
--不能读取其它已由其它事务修改但是没有提交的数据，
--不允许其它事务在当前事务完成修改之前修改由当前事务读取的数据，
--不允许其它事务在当前事务完成修改之前插入新的行。
----------------------事务A----------
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
DBCC USEROPTIONS
BEGIN TRANSACTION
SELECT * FROM TranTableName WHERE TranID=1
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName WHERE TranID=1
COMMIT TRANSACTION
SELECT GETDATE()
------------------------------------

----------------------事务B---------
SET TRANSACTION ISOLATION LEVEL  READ COMMITTED
BEGIN TRANSACTION
SELECT GETDATE() AS 'Select'
SELECT * FROM dbo.TranTableName
SELECT GETDATE() AS 'Update'
UPDATE TranTableName SET TranColumnName='更新' WHERE TranID=1
SELECT GETDATE() AS 'Insert'
INSERT INTO TranTableName(TranColumnName) VALUES('更新或者插入')
COMMIT TRANSACTION
WAITFOR DELAY  '00:00:10'
SELECT * FROM TranTableName 
------------------------------------

-------------------------------

--游标操作示例


--创建一个游标
DECLARE CurTest CURSOR SCROLL FOR SELECT TranID,TranColumnName FROM dbo.TranTableName;

--打开游标
OPEN CurTest;

--存储读取的值
DECLARE @TranID INT,@TranColumnName NVARCHAR(20)
        
--读取第一条记录
FETCH FIRST FROM CurTest INTO @TranID,@TranColumnName;

--循环读取游标记录
--全局变量
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SELECT @TranID,@TranColumnName
	 --继续读取下一条记录
	 FETCH NEXT FROM CurTest INTO @TranID,@TranColumnName;
END


--关闭游标
CLOSE CurTest;

--删除游标
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

--用commit或rollback解锁
--锁表的行
SELECT * FROM dbo.TranTableName WITH(ROWLOCK)  WHERE TranID =1

---锁定数据库的表 
SELECT * FROM dbo.TranTableName WITH(HOLDLOCK)

--排它锁 
BEGIN TRANSACTION
UPDATE TranTableName SET TranColumnName='new'+STR(CAST(100*RAND()+10*RAND() AS INT)) WHERE TranID=1
WAITFOR DELAY  '00:00:10'
COMMIT TRANSACTION

--共享锁
BEGIN TRANSACTION
SELECT * FROM dbo.TranTableName WITH(HOLDLOCK)
WAITFOR DELAY  '00:00:10'
COMMIT TRANSACTION
SELECT GETDATE()

BEGIN TRANSACTION
SELECT * FROM dbo.TranTableName
UPDATE TranTableName SET TranColumnName='new'+STR(CAST(100*RAND()+10*RAND() AS INT)) WHERE TranID=2
COMMIT TRANSACTION


--由于32位Windows用户进程有4GB的虚拟地址空间。其中2GB给核心态，剩下2GB给用户态。这两部分严格分开。Windows不会因为其中某一块内存地址空间用尽而将另外一块的空间让出。

 

--由于SQLSERVER的绝大部分指令都运行在用户态下，就是说SQLSERVER的内存基本上使用用户态地址空间资源。现在的情况是2GB地址空间资源对于SQLSERVER来说严重阻碍了SQLSERVER有效利用硬件资源

 

--所以SQLSERVER引入了AWE address windowsing extensions(地址空间扩展)。这是允许32位应用程序分配64GB物理内存，并把视图或窗口映射到2GB虚拟地址空间的机制。

Exec sys.sp_configure								
Exec sys.sp_configure 'show advanced options',1		
Reconfigure With Override
Exec sys.sp_configure 'awe enabled' ,1
Reconfigure With Override
Exec sys.sp_configure 'max server memory (MB)',6000
Reconfigure With Override
--临时表与表变量
--临时表与永久表相似，只是创建在Tempdb中，它只有在一个数据库连接结束后或者由SQL命令DROP掉，才会消失，否则就会一直存在。
--临时表分为本地和全局两种，本地临时表的名称都是以“#”为前缀，本地当前用户连接中才是可见的，用户从实例断开连接时被删除。全局临时表的名称都是以“##”为前缀，创建后对任何用户都是可见的，当所有引用该表的用户断开连接时被删除。 

--表变量是变量的一种，表变量也分为本地及全局的两种，本地表变量的名称都是以“@”为前缀，只有在本地当前的用户连接中才可以访问。全局的表变量的名称都是以“@@”为前缀，一般都是系统的全局变量，像我们常用到的，如 @@Error代表错误的号，@@RowCount代表影响的行数。 

--表变量是存储在内存中的，当用户在访问表变量的时候，SQL Server是不产生日志的，而在临时表中是产生日志的; 
--在表变量中，是不允许有非聚集索引的; 
--表变量是不允许有DEFAULT默认值，也不允许有约束; 
--临时表上的统计信息是健全而可靠的，但是表变量上的统计信息是不可靠的; 
--临时表中是有锁的机制，而表变量中就没有锁的机制。 


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

--对象缓存
DBCC  FreeProcCache	--释放缓存
--分别单独执行以下语句，四条缓存计划
select 订单id from 订单 where 订单ID=2
go
select 订单id from 订单 where 订单ID=1
go
select 订单id from 订单 where 订单ID=3
go
select 订单id from 订单 where 订单ID=4
go

IF OBJECT_ID('P_order','P') IS NOT NULL
	DROP PROC p_order
GO	
CREATE PROC P_order
@orderid INT 
As
BEGIN
	SELECT 订单id FROM 订单 WHERE  订单ID=@orderid
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

-----------阻塞实例-----------
--事务更新操作表
Begin Tran
	Update 产品 Set 库存量=30 where 产品ID=1
	
Waitfor delay '0:00:20'	
ROLLBACK


--另外事务查询表时阻塞

Select * from 产品
---------------------------------------
------------死锁-----------------------
---第一个事务首先更新A表再更新B表------
Begin TRAN
	Update 产品 set 库存量=库存量+1 where 产品ID=1
	Waitfor delay '0:00:05'
	Update 客户 Set 公司名称='国鼎集团'
			where 客户ID='Frank'
COMMIT
----第二个事务首先更新B表再更新A表-------------
Begin TRAN
	Update 客户 Set 公司名称='国鼎集团'
			where 客户ID='Frank'
	Waitfor delay '0:00:05'
	Update 产品 set 库存量=库存量+1 
			where 产品ID=1
COMMIT
--第一个事务正常执行结束
-------------------------------------------

--查看当前实例的配置
Exec sp_configure
--修改高级选项的显示设置
Exec sp_configure 'show advanced options',1
--设置阻塞进程报告阀值为5秒
Exec sp_configure 'blocked process threshold (s)',5
--让修改设置立即生效
Reconfigure With Override

-------------表设计优化
--查询语句优化：避免过多的表关联，注意where 中的字段顺序，先过滤有索引的，能尽量缩小数据范围的等。
--索引优化：合理分析并设置、调整索引。
--表结构优化：如果数据量过大，纵向或者横向拆分表。纵向拆，将前n个字段放在一个表，后面m个放另一个表。横向：满足一定条件的数据放一个表，比如公司员工特别多，男雇员放一个，女雇员放一个表，人妖放一个表。
--存储方式优化：通过不同的存储空间或者表分区，将数据存放在不同的存储区域，达到充分利用IO的目的
set statistics io ON			--查看IO统计
IF object_ID('t2','U') IS NOT NULL
	DROP TABLE t2
GO
select * into t2 from 订单明细
select *  from t2  where 单价*数量=640

--在单价上建索引
create index ix_price on t2(单价)
select *  from t2  where 单价*数量=640

--在数量上建索引
  create index ix_Qty on t2(数量)
  select *  from t2  where 单价*数量=640
  
--建组合索引
  DROP INDEX ix_price ON t2
  DROP INDEX  ix_Qty ON t2 
  DROP INDEX ix_Price_Qty ON t2
  CREATE INDEX ix_Price_Qty on t2(单价,数量)
  SELECT *  FROM t2  where 单价*数量=640
  
--上面三种方式都无法优化这条语句
  
ALTER table t2 ADD SubTotal As 单价*数量 PERSISTED --创建计算列
--在计算列上创建索引
--DROP INDEX ix_subTotal ON t2
CREATE INDEX ix_subTotal on t2(subTotal)
SELECT *  FROM t2  WHERE  单价*数量=640		--IO就变小了
--如果将查询时的where条件改为（数量*单价）
select * from t2 where 数量*单价=640		--IO反而变得更大

--序列
CREATE TABLE TestIdentity (id INT IDENTITY,NAME CHAR(20))
INSERT INTO TestIdentity VALUES('joe')
SELECT * FROM TestIdentity		--identity是表内部的,不能够给其它表用

CREATE TABLE Employees(EmployeeId INT NOT NULL PRIMARY KEY, Name NVARCHAR(255) NULL);

CREATE TABLE Contractors(ContractorId INT NOT NULL PRIMARY KEY,Name NVARCHAR(255) NULL);

--创建序列
CREATE SEQUENCE IdSequence AS INT START WITH 10000  INCREMENT BY 1; --产生序列可以重复使用
--------共享序列--------
--当需要插入记录时,可以直接从序列中拿数据,保证拿到的id是从来没用过的
INSERT INTO Employees (EmployeeId, Name) VALUES (NEXT VALUE FOR IdSequence, 'Jane');
--向其它表插入记录时,也直接从序列中拿,拿到的id也是从来没用过的.
INSERT INTO Contractors (ContractorId, Name) VALUES (NEXT VALUE FOR IdSequence, 'John');

SELECT * FROM Employees;
SELECT * FROM Contractors;

SELECT ID,Name,NEXT VALUE FOR IdSequence OVER(ORDER BY Name DESC) As SNO FROM Employees

--创建序列之后，可以对序列进行修改
alter sequence idsequence INCREMENT BY 1 MINVALUE 10000 MAXVALUE 10003 CYCLE

--分区视图
Create Table Orders(OrderId int Identity NOT NULL,
	 CustId int NOT NULL,   --1~~30000
	 ProductId int NOT NULL,  --1~~2000
	 EmpId int NOT NULL,		--1~~1000
	 Unitprice money NOT NULL,  --10~~10000
	 Quantity int NOT NULL,    --1~50000
	 OrderDate datetime NOT NULL,  --2000~当天
	 Note char(100) NOT NULL)
--制造100万条数据
Exec sp_spaceused Orders
--开启当前会话的IO统计
Set Statistics IO ON
SELECT * FROM Orders Where OrderDate >'2013-4-12 16:00:00'

Create Index IX_OrderDate On Orders(OrderDate)

Select * from Orders Where OrderDate >'2013-4-12 16:00:00'
--IO降低了很多
Select * from Orders Where OrderDate >'2010-4-10 16:00:00'
--创建表
DROP TABLE dbo.Orders2013
DROP TABLE dbo.Orders2012
DROP TABLE dbo.Orders2009
DROP TABLE dbo.Orders2005

SELECT * INTO Orders2013 FROM Orders WHERE YEAR(Orderdate)>=2013
SELECT * INTO Orders2012 FROM Orders WHERE YEAR(Orderdate) BETWEEN 2010 AND 2012
SELECT * INTO Orders2009 FROM Orders WHERE YEAR(Orderdate) BETWEEN 2006 AND 2009
SELECT * INTO Orders2005 FROM Orders WHERE YEAR(Orderdate) <= 2005
	go
--创建分区视图		
CREATE VIEW pvOrders as 
	SELECT * FROM Orders2013 UNION ALL
	SELECT * FROM Orders2012 UNION ALL
	SELECT * FROM Orders2009  UNION ALL
	SELECT * FROM Orders2005
	go
	
SELECT * FROM Orders WHERE OrderDate >='2013-1-1'
SELECT * FROM pvOrders WHERE OrderDate >='2013-1-1'
--分别给分区表添加CHECK约束
ALTER TABLE Orders2013 ADD CONSTRAINT CK_Date4 CHECK (Orderdate >='2013-1-1' )
ALTER TABLE Orders2012 ADD CONSTRAINT CK_Date3 CHECK (Orderdate >='2010-1-1' and Orderdate<'2013-1-1')
ALTER TABLE Orders2009 ADD CONSTRAINT CK_Date2 CHECK (Orderdate >='2006-1-1' and Orderdate<'2010-1-1')
ALTER TABLE Orders2005 ADD CONSTRAINT CK_Date1 CHECK (Orderdate<'2006-1-1')

SELECT * FROM pvOrders WHERE OrderDate >='2013-1-1'
--创建索引
CREATE INDEX ix_Orders2013_OrderDate ON orders2013(OrderDate)

--下面语句不会用索引
SELECT * FROM pvOrders Where OrderDate >='2013-1-1'

--下面语句会用到索引（因为返回的记录数比较少）
SELECT * FROM pvOrders Where OrderDate >='2013-10-15 23:00:00'

--分区表
Select * from Orders where OrderDate >='2013-1-1'

DROP PARTITION FUNCTION fn_ByDate
DROP PARTITION SCHEME ps_ByDate

--分区函数，确定了分段条件
Create Partition Function fn_ByDate (DateTime)
	AS Range Right
	For Values('2005-1-1','2010-1-1','2011-1-1',
		'2012-1-1','2013-1-1','2014-1-1')
Go
--创建分区方案
Create Partition Scheme ps_ByDate
	AS Partition fn_ByDate
	To ([Primary],[Primary],[Primary],[Primary]
	,[Primary],[Primary],[Primary],[Primary]
	,[Primary],[Primary],[Primary],[Primary])
GO

DROP TABLE dbo.Orders2
--应用分区方案到新建的表
Create Table Orders2
	(OrderId int ,
	 CustId int,   --1~~30000
	 ProductId int,  --1~~2000
	 EmpId int,		--1~~1000
	 Unitprice money,  --10~~10000
	 Quantity int,    --1~50000
	 OrderDate datetime,  --2000~当天
	 Note char(100))
On ps_ByDate(OrderDate)
--导入数据
INSERT Orders2 SELECT * FROM Orders
--分区字段作为条件
Select * from Orders2 where OrderDate >='2013-1-1'

--现有表指定分区方案（在表设计中指定）
CREATE CLUSTERED INDEX ix_orders_OrderDate ON dbo.Orders(OrderDate) ON ps_ByDate(OrderDate)
DROP INDEX ix_orders_OrderDate ON dbo.Orders

--分区的转换:将一个表的分区挂到另外一个表上面,表结构一样,分区一样
DROP TABLE dbo.Orders_change
Create Table Orders_change
	(OrderId int ,
	 CustId int,   --1~~30000
	 ProductId int,  --1~~2000
	 EmpId int,		--1~~1000
	 Unitprice money,  --10~~10000
	 Quantity int,    --1~50000
	 OrderDate datetime,  --2000~当天
	 Note char(100))
On ps_ByDate(OrderDate)

alter table orders2 switch partition 1 to orders_change partition 1

--查询表orders
select * from Orders2 where OrderDate<='2004-11-1'
--空的

--查询表orders_change
select * from Orders_change where OrderDate<='2004-11-1'

-----分区的拆分

--指定下个分区所在的文件组
ALTER PARTITION SCHEME ps_ByDate NEXT USED [primary]

--增加分区函数的边界值
ALTER PARTITION FUNCTION fn_ByDate () SPLIT RANGE ('2008-1-1')

-----分区的合并
ALTER PARTITION FUNCTION fn_ByDate () MERGE RANGE ('2008-1-1')

--定期生成统计表
SELECT ProductId,SUM(Quantity),SUM(Unitprice*Quantity)
From Orders
Group by ProductId
Order by SUM(Unitprice*Quantity) DESC
--18189 次,17.7


--定期刷新统计表
IF OBJECT_ID('OrdersSummary','u') IS NOT NULL 
DROP TABLE OrdersSummary
SELECT  ProductId,SUM(Quantity) SumQuantity,SUM(Unitprice*Quantity) SalesAmount
Into OrdersSummary
From Orders
Group by ProductId
Order by SUM(Unitprice*Quantity) DESC
	
SELECT * FROM OrdersSummary


--索引视图
SELECT * INTO orders3 from Orders

--执行以下语句所用的开销
Select  ProductId,SUM(Quantity) ,SUM(Unitprice*Quantity) 
From dbo.orders3
Group by ProductId
	
GO
--创建索引视图
CREATE VIEW vOrdersSummary WITH SCHEMABINDING AS
SELECT ProductId,SUM(Quantity) SumQuantity
				,SUM(Unitprice*Quantity) SumAmount,COUNT_BIG(*) cb
From dbo.orders3
Group by ProductId
Go
--在视图上建惟一聚集索引
CREATE UNIQUE CLUSTERED INDEX UCX_ProductId on vOrdersSummary(ProductId)

SELECT * FROM dbo.vOrdersSummary

SELECT  ProductId,SUM(Quantity),SUM(Unitprice*Quantity)
From orders3
Group by ProductId
Order by SUM(Unitprice*Quantity) DESC
--11 次,0.05


--索引
--堆表：没有聚集索引的表，记录通过IAM页以及PFS页来确定哪页有空闲空间。
--聚集索引表：有聚集索引的表，记录是根据聚集键值所在页的键值逻辑顺序维护的
CREATE TABLE HeapTable(id INT IDENTITY,NAME NVARCHAR(20))
--插入10条数据
INSERT INTO  HeapTable VALUES('Heap');
SELECT * FROM HeapTable
--删除几条数据
DELETE HeapTable WHERE id in (4,6)
--再往里面插入数据
INSERT INTO HeapTable values('joe')
INSERT INTO HeapTable values('GYB')

CREATE TABLE ClusteredIndexTable(id INT IDENTITY PRIMARY KEY CLUSTERED,NAME NVARCHAR(20))
--插入10条数据
INSERT INTO  ClusteredIndexTable VALUES('Clustered');
--删除几条数据
DELETE ClusteredIndexTable WHERE id in (4,6)
SELECT * FROM ClusteredIndexTable

--再往里面插入数据
INSERT INTO ClusteredIndexTable values('joe')
INSERT INTO ClusteredIndexTable values('GYB')

--聚集索引与非聚集索引
--在表查询中：聚集索引查找 > 非聚集索引查找 > 索引扫描 > 表扫描
SELECT * INTO OrderIndex FROM dbo.Orders
--添加聚集索引
ALTER TABLE OrderIndex  ADD CONSTRAINT PK_Orderid primary key (OrderId)
DROP TABLE OrderIndex
--非聚集索引
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
--查看索引碎片语句
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
        
        --查看索引的碎片
DBCC SHOWCONTIG(OrderIndex)
DBCC SHOWCONTIG(OrderIndex,ix_ProductId)

--重新组织索引
ALTER INDEX ix_orderid On OrderIndex REORGANIZE
	
--重建索引
ALTER INDEX ix_orderid On OrderIndex REBUILD
------------------ SQL2000的处理
--碎片整理
dbcc indexdefrag(NorthwindCS,Orders)
--重新生成索引
DBCC DBREINDEX(Orders,ix_orderid)

-----------------索引填充因子
Create Index NX_CustId On Orders(CustId) With FillFactor = 60

--SQL2005
Alter Index ix_orderid On orders REBUILD WITH (FillFactor = 60)
	
--SQL2005联机处理	
Alter Index ix_orderid On orders Rebuild With (online=ON,FillFactor = 60)
	
--SQL2000

DBCC DBREINDEX(Orders,ix_orderid,90)

SELECT * FROM orders WHERE CustId=10000

DBCC SHOW_STATISTICS	('OrderIndex','ix_ProductId') 
	
Update 客户  Set  地区='华南' 
			where 客户ID='ALFKI'
	
--Update Statistics 表名

--Update Statistics 表名 索引名

Update Statistics 客户 地区
DBCC SHOW_STATISTICS


--索引提示,强制SQL Server 使用索引
Select * from OrderIndex with (INDEX=ix_ProductId) where ProductId =895


