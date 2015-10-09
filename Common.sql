SELECT DATEADD(wk,DATEDIFF(wk,0,DATEADD(day,-1,GETDATE())),0) '当前日期的周一',
DATEADD(wk,DATEDIFF(wk,0,DATEADD(day,-1,GETDATE())),6) '当前日期的周日';
/*
标题：合并列值
表结构，数据如下：
id 		value
----- ------
1 		aa
1 		bb
2 		aaa
2 		bbb
2 		ccc
需要得到结果：
id 		values
------ -----------
1 		aa,bb
2 		aaa,bbb,ccc
即：group by id, 求value 的和（字符串相加）*/

SELECT id, [values]=STUFF((SELECT ','+[value] FROM tb t WHERE id=tb.id FOR XML PATH('')), 1, 1, '') FROM tb GROUP BY id

/*
标题：分拆列值
表tb, 如下:
 id          value
 ----------- -----------
 1           aa,bb
 2           aaa,bbb,ccc
 欲按id,分拆value列, 分拆后结果如下:
 id          value
 ----------- --------
 1           aa
 1           bb
 2           aaa
 2           bbb
 2           ccc	*/

  SELECT XML.id, Nodes.value
 FROM(
     SELECT id, [value] = CONVERT(xml,'<root><v>' + REPLACE([value], ',', '</v><v>') + '</v></root>') FROM tb
 )XML
 OUTER APPLY(
     SELECT value = N.v.value('.', 'varchar(100)') FROM XML.[value].nodes('/root/v') N(v)
 )Nodes

 /*
标题：普通行列转换(version 2.0)
问题：假设有张学生成绩表(tb)如下:
姓名		课程		分数
张三		语文		74
张三		数学		83
张三		物理		93
李四		语文		74
李四		数学		84
李四		物理		94
(得到如下结果)：
姓名	  语文	数学		物理
---- ---- ---- ----
李四  74   84   94
张三	  74   83   93
-------------------	*/
select 姓名 as 姓名 ,
  max(case 课程 when '语文' then 分数 else 0 end) 语文,
  max(case 课程 when '数学' then 分数 else 0 end) 数学,
  max(case 课程 when '物理' then 分数 else 0 end) 物理
from tb group by 姓名
select * from (select * from tb) a pivot (max(分数) for 课程 in (语文,数学,物理)) b
declare @sql varchar(8000)
select @sql = isnull(@sql + '],[' , '') + 课程 from tb group by 课程
set @sql = '[' + @sql + ']'
exec ('select * from (select * from tb) a pivot (max(分数) for 课程in (' + @sql + ')) b')

/*
问题：如果上述两表互相换一下：即表结构和数据为：
姓名		语文		数学		物理
张三		74		83  	93
李四		74　　　84		94
(得到如下结果)：
姓名	  课程  分数
---- ---- ----
李四	  语文  74
李四  数学  84
李四  物理  94
张三  语文  74
张三  数学  83
张三  物理  93
--------------	*/
select * from
(
 select 姓名 , 课程 = '语文' , 分数 = 语文 from tb where 语文 is not null
 union all
 select 姓名 , 课程 = '数学' , 分数 = 数学 from tb where 数学 is not null
 union all
 select 姓名 , 课程 = '物理' , 分数 = 物理 from tb where 物理 is not null
) t
order by 姓名 , case 课程 when '语文' then 1 when '数学' then 2 when '物理' then 3 END
select 姓名 , 课程 , 分数 from tb unpivot (分数 for 课程 in([语文] , [数学] , [物理])) t

/*
问题：在上述的结果上加个平均分，总分，得到如下结果：
姓名		课程  分数
---- ------ ------
李四		语文  74.00
李四		数学  84.00
李四		物理  94.00
李四		平均分84.00
李四		总分  252.00
张三		语文  74.00
张三		数学  83.00
张三		物理  93.00
张三		平均分83.33
张三		总分  250.00
------------------	*/
select * from
(
 select 姓名 as 姓名 , 课程 = '语文' , 分数 = 语文 from tb 
 union all
 select 姓名 as 姓名 , 课程 = '数学' , 分数 = 数学 from tb
 union all
 select 姓名 as 姓名 , 课程 = '物理' , 分数 = 物理 from tb
 union all
 select 姓名 as 姓名 , 课程 = '平均分' , 分数 = cast((语文 + 数学 + 物理)*1.0/3 as decimal(18,2)) from tb
 union all
 select 姓名 as 姓名 , 课程 = '总分' , 分数 = 语文 + 数学 + 物理 from tb
) t
order by 姓名 , case 课程 when '语文' then 1 when '数学' then 2 when '物理' then 3 when '平均分' then 4 when '总分' then 5 END

/*
表tb, 如下:
班级		姓名		课程		分数
一班		张三		语文		74
一班		张三		数学		83
一班		张三		物理		93
一班		李四		语文		74
一班		李四		数学		84
一班		李四		物理		94
二班		张三		语文		64
二班		张三		数学		73
二班		张三		物理		83
二班		李四		语文		79
二班		李四		数学		81
二班		李四		物理		97	*/
SELECT 班级,姓名,SUM(分数) 总成绩 FROM tb GROUP BY CUBE (班级,姓名)

SELECT 班级,姓名,CASE WHEN GROUPING(姓名)=1  THEN  ISNULL(班级,'所有')+'汇总'  
WHEN GROUPING(班级)=1 THEN ISNULL(姓名,'所有')+'汇总'  
ELSE '正常行' END as 行类别,SUM(分数) 总成绩 FROM tb GROUP BY 班级,姓名 WITH CUBE 

SELECT 班级,姓名,SUM(分数) 总成绩 FROM tb GROUP BY ROLLUP (班级,姓名)

SELECT 班级,姓名,SUM(分数) 总成绩 FROM tb 
GROUP BY GROUPING SETS (班级,(班级,姓名))

/*
当SET XACT_ABORT 为ON 时，如果执行Transact-SQL 语句产生运行时错误，则整个事务将终止并回滚。
当SET XACT_ABORT 为OFF 时，有时只回滚产生错误的Transact-SQL 语句，而事务将继续进行处理。*/
SET XACT_ABORT OFF
BEGIN TRY
BEGIN TRAN
INSERT INTO score VALUES (101,80)
INSERT INTO score VALUES (102,87)
INSERT INTO score VALUES (107, 59) /* 外键错误*/
INSERT INTO score VALUES (103,100)
COMMIT TRAN
PRINT '事务提交'
END TRY
BEGIN CATCH
ROLLBACK;
PRINT '事务回滚';
--RAISERROR (ERROR_MESSAGE(), ERROR_SEVERITY(),ERROR_STATE());
Throw;
END CATCH


/*
记录数据变更的四个方法：触发器、Output子句、变更数据捕获（Change Data Capture 即CDC）功能、同步更改跟踪。*/
--查看是否启用CDC
SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NorthwindCS'
----启用当前数据库的CDC功能
EXEC sys.sp_cdc_enable_db
--创建链接服务器
exec sp_addlinkedserver  'Mysrv_lnk','','SQLOLEDB','192.168.80.188'
exec sp_addlinkedsrvlogin 'Mysrv_lnk','false',null,'sa','sa' 
--跳过远程实例架构表的检查，以提升性能 
EXEC sp_serveroption 'Mysrv_lnk', 'lazy schema validation', 'true'

--SQL分页
DECLARE @page INT, @size INT
;WITH cte AS (
    SELECT  TOP (@page * @size) *,ROW_NUMBER() OVER(ORDER BY 班级 ) AS Seq,
        COUNT(*) OVER(PARTITION BY '') AS Total 
FROM tb WHERE 1=1 ORDER BY 班级 ASC
        )
SELECT * FROM cte WHERE seq BETWEEN (@page - 1 ) * @size + 1 AND @page * @size ORDER BY seq;

SELECT *,COUNT(*) OVER(PARTITION BY '') AS Total FROM tb WHERE 1=1 ORDER BY 班级  OFFSET (@page -1) * @size ROWS FETCH NEXT @size ROWS ONLY;

--当前会话中任何作用域的任何表的最新标识值
SELECT @@IDENTITY;

--获取当前会话和当前作用域的任何表的最新标识值
SELECT SCOPE_IDENTITY();

--获取跨任何会话或作用域的某个表的最新标识值
SELECT IDENT_CURRENT('tb');

--嵌套循环Loop适合：当一个表很小另一个表很大、在关联的列上有索引时
select * from MEAN p  inner loop join MARD r  on p.ProdCode = r.ProdCode 

--合并merge适合：按照关联列排序的中等或者大的表
select * from MARA p inner join MARD  r on p.ProdCode = p.ProdCode OPTION(MERGE JOIN)

--哈希匹配hash适合：没有排序的大的表
select * from MARA p inner hash join MARD r on r.ProdCode = p.ProdCode  

---------------获取与公司相关的当前节点和所有的父节点
WITH CTEGetParent AS (
SELECT AreaID,AreaCode,AreaName,AreaLevel,ParentID
FROM  t_Area
UNION ALL
(
SELECT a.AreaID,a.AreaCode,a.AreaName,a.AreaLevel,a.ParentID  
FROM t_Area AS a INNER JOIN CTEGetParent AS b ON a.AreaID = b.ParentId)
)
-----------------获取与公司相关的当前节点和所有的子节点
,CTEGetChild AS(
SELECT AreaID,AreaCode,AreaName,AreaLevel,ParentID
FROM  t_Area 
UNION ALL
(SELECT a.AreaID,a.AreaCode,a.AreaName,a.AreaLevel,a.ParentID
FROM t_Area AS a INNER JOIN CTEGetChild AS b ON a.ParentId = b.AreaID)
)
-------------------获取与公司相关的所有节点
,CTEAll AS (
SELECT DISTINCT * FROM CTEGetParent where AreaID>=1 and AreaID<=999999
UNION
select distinct * from CTEGetChild where AreaID>=1 and AreaID<=999999
)
-------------------通过父ID查询下一级节点
,CTEGetSubChild as(
select * from CTEAll
union all
(Select a.* from CTEAll as a inner join CTEGetSubChild as b on a.ParentID = b.AreaID) 
)



--一次性插入多行
INSERT INTO [Values](Name,Code,Date) VALUES('A','AAA',GETDATE()),('B','BBB',GETDATE())

--不使用永久表或临时表而表示一个结果集，而且不需要函数或表变量
SELECT Name,Code,Date FROM(values('A','AAA',GETDATE()),('E','EEE',GETDATE()))[Values] (Name,Code,Date)

--百分比是表数据页的百分比，而不是记录数的百分比，因此记录数目是不确定的。
select Top (1) percent  NAME    from  dbo.test  order by NAME

--(select,Update,delete)避免在一个语句中执行非常大的操作,而把修改分成多个小块,这大大改善了大数据量,
--大访问量的表的并发性,可以用于大的报表或数据仓库应用程序.此外,分块操作可以避免日志的快速增长,
--因为前一操作完成后,可能会重用日志空间。如果操作中有事务，已经完成的修改数据已经可以用于查询,而不必等待所有的修改完成.
WHILE (SELECT COUNT(1) FROM test)>0
BEGIN
DELETE TOP (200) FROM test
END

--定义表变量以存储输出
DECLARE  @tableVarRecord Table 
(ID int not null identity(1,1) primary key
,Name Nvarchar(20) null
,Code NVarchar(30) null
,Date datetime null
)

--确定目标表
Merge INTO TProduct  p
--从数据源查找编码相同的产品
USING SProduct s on p.Code=s.Code 
--如果编码相同，则更新目标表的名称
WHEN Matched AND P.Name<>s.Name THEN UPDATE SET P.Name=s.Name
--如果目标表中不存在，则从数据源插入目标表
WHEN Not Matched By TARGET Then INSERT (Name,Code,Date) values (s.Name,s.Code,s.Date)
--如果数据源的行在源表中不存在，则删除目标表行
WHEN Not Matched By Source THEN DELETE OUTPUT DELETED.* INTO @tableVarRecord;
--返回上个Merge语句影响的行数
SELECT @@ROWCOUNT as Count1,ROWCOUNT_BIG() as Count2 

--当单个T-SQL语句在单个表或索引上获取5000多个锁,或者SQL Server实例中的锁数量超过可用内存阈值时,SQL Server会尝试启动锁升级.
--锁占用系统内存,因此把很多锁转化为一个较大的锁能释放内存资源.然而,在释放内存资源的同时会降低并发性.
--查看锁的活动
SELECT request_session_id sessionid,resource_type type,resource_database_id dbid,
OBJECT_NAME(resource_associated_entity_id, resource_database_id) objectname,request_mode rmode,
request_status rstatus FROM sys.dm_tran_locks WHERE resource_type IN ('DATABASE', 'OBJECT')

--Table 这是SQL Server 2005中使用的默认行为.当设置为该值时,在表级别启用了锁升级,不论是否为分区表.
--Auto 如果表已分区,则在分区级别(堆或B树)启用锁升级.如果表未分区,锁升级将发生在表级别上.
--Disable 在表级别删除锁升级.注意,对于用了TABLOCK 提示或使用可序列化隔离级别下Heap的查询时,你仍然可能看到表锁.
ALTER TABLE dbo.test SET (LOCK_ESCALATION = AUTO )

--注意这句在SQL Server 2005下会出错
SELECT lock_escalation,lock_escalation_desc FROM sys.tables WHERE name='test'

--如果阻塞成串，必须通过blocking_session_id和session_ID列仔细查看每一个阻塞进程，直到发现原始的阻塞进程。
SELECT blocking_session_id, wait_duration_ms, session_id
FROM sys.dm_os_waiting_tasks WHERE blocking_session_id IS NOT NULL

kill 52 

SELECT t.text FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text (c.most_recent_sql_handle) t WHERE c.session_id = 54

--SET LOCK_TIMEOUT 1000 设定需要等待的时间
--死锁的一些原因:
--1.应用程序以不同的次序访问表.例如会话1先更新了客户然后更新了订单,而会话2先更新了订单然后更新了客户.这就增加了死锁的可能性.
--2.应用程序使用了长时间的事务,在一个事务中更新很多行或很多表.这样增加了行的"表面积",从而导致死锁冲突.
--3.在一些情况下,SQL Server发出了一些行锁,之后它又决定将其升级为表锁.如果这些行在相同的数据页面中,
--并且两个会话希望同时在相同的页面升级锁粒度,就会产生死锁.

--DBCC TRACEON，启用跟踪标志位。用法：DBCC TRACEON ( trace# [ ,...n ][ , -1 ] ) [ WITH NO_INFOMSGS ]
--DBCC TRACESTATUS，检查跟踪标志位状态。用法：DBCC TRACESTATUS ( [ [ trace# [ ,...n ] ] [ , ] [ -1 ] ] ) [ WITH NO_INFOMSGS ]
--DBCC TRACEOFF，关闭跟踪标志位。用法：DBCC TRACEOFF (trace# [ ,...n ] [ , -1 ] ) [ WITH NO_INFOMSGS ]
DBCC TRACEON (1222, -1)
GO
DBCC TRACESTATUS
--SET DEADLOCK_PRIORITY { LOW | NORMAL | HIGH | <numeric-priority> | @deadlock_var | @deadlock_intvar }
--<numeric-priority> ::= { -10 | -9 | -8 | … | 0 | … | 8 | 9 | 10 }