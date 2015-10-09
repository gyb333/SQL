EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'单据ID' ,
@level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',
@level1name=N'MMP_SaleStandardCommon', @level2type=N'COLUMN',@level2name=N'BillId'
go

SELECT
--(case when a.colorder=1 then d.name else '' end) 表名,
d.name 表名,
a.colorder 字段序号,
a.name 字段名,
(case when COLUMNPROPERTY( a.id,a.name,'IsIdentity')=1 then '√'else '' end) 标识,
(case when (SELECT count(*)
FROM sysobjects
WHERE (name in (SELECT name
FROM sysindexes
WHERE (id = a.id) AND (indid in (SELECT indid
FROM sysindexkeys
WHERE (id = a.id) AND (colid in (SELECT colid
FROM syscolumns
WHERE (id = a.id) AND (name = a.name)
)
)
)
)
)
) AND (xtype = 'PK')
) > 0 then '√' else '' end) 主键,
b.name 类型,
a.length 占用字节数,
COLUMNPROPERTY(a.id,a.name,'PRECISION') as 长度,
isnull(COLUMNPROPERTY(a.id,a.name,'Scale'),0) as 小数位数,
(case when a.isnullable=1 then '√'else '' end) 允许空,
isnull(e.text,'') 默认值,
isnull(g.[value],'') AS 字段说明
FROM  syscolumns a
left join systypes b on a.xtype=b.xusertype
inner join sysobjects d on a.id=d.id  and  d.xtype='U' and d.name<>'dtproperties'
left join syscomments e on a.cdefault=e.id
left join sys.extended_properties g on a.id=g.major_id AND a.colid = g.minor_id
where d.name in (
'MMP_SaleStandardCommonType',
'MMP_SaleStandardCommon'
)
---查询具体的表，注释掉后就是查询整个数据库了
order by a.id,a.colorder


IF OBJECT_ID('T_ComixBillNo', 'U') IS NOT NULL
DROP TABLE T_ComixBillNo
GO
CREATE TABLE T_ComixBillNo(
BillTypeID INT PRIMARY KEY,				--业务单据ID
BillTypeName NVARCHAR(20) NOT NULL,	--业务单据名称
PreLetter NVARCHAR(10) DEFAULT '',		--前置字母
SNo		NVARCHAR(20) DEFAULT '',		--流水号
PostLetter NVARCHAR(10) DEFAULT ''		--后置字母
)

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'业务单据ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNo', @level2type=N'COLUMN',@level2name=N'BillTypeID'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'业务单据名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNo', @level2type=N'COLUMN',@level2name=N'BillTypeName'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'前置字母' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNo', @level2type=N'COLUMN',@level2name=N'PreLetter'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'流水号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNo', @level2type=N'COLUMN',@level2name=N'SNo'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'后置字母' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNo', @level2type=N'COLUMN',@level2name=N'PostLetter'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'单据编码原则' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNo'


INSERT INTO [dbo].[T_ComixBillNo]	VALUES  ( 2102 , N'销售订单' , N'SE' , N'000000' ,N''  )
INSERT INTO [dbo].[T_ComixBillNo]	VALUES  ( 2105 , N'预留单' , N'RE' , N'000000' ,N''  )
INSERT INTO [dbo].[T_ComixBillNo]	VALUES  ( 30000 , N'交货单' , N'SD' , N'000000' ,N''  )

go

IF OBJECT_ID('T_ComixBillNoDetail', 'U') IS NOT NULL
DROP TABLE T_ComixBillNoDetail
GO
CREATE TABLE T_ComixBillNoDetail(
SalesDeptCode VARCHAR(4) NOT NULL,			--销售办公室
BillTypeID INT NOT NULL,					--业务单据ID
CurrSNO INT NOT NULL,						--当前流水号
CurrDate VARCHAR(8) NOT NULL,						--当前日期
CONSTRAINT NPK_T_Comix_BillNoDetail PRIMARY KEY NONCLUSTERED(
SalesDeptCode, BillTypeID,CurrDate
)
)
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'销售办公室' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNoDetail', @level2type=N'COLUMN',@level2name=N'SalesDeptCode'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'业务单据ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNoDetail', @level2type=N'COLUMN',@level2name=N'BillTypeID'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'当前流水号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNoDetail', @level2type=N'COLUMN',@level2name=N'CurrSNO'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'当前日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNoDetail', @level2type=N'COLUMN',@level2name=N'CurrDate'
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'单据编码明细' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_ComixBillNoDetail'

go

ALTER PROCEDURE PrComixGetBillNo(
@BillTypeID int,
@SalesDeptCode VARCHAR(4) ,
@BillNo varchar(30) output
)
AS
DECLARE
@PreLetter NVARCHAR(10),
@SNo NVARCHAR(20),
@PostLetter NVARCHAR(10),
@CurrSNo INT ,
@CurrDate VARCHAR(8),
@Length INT


BEGIN
SELECT @PreLetter= RTRIM(LTRIM(PreLetter)) , @SNo= RTRIM(LTRIM([SNo])),@PostLetter= RTRIM(LTRIM([PostLetter])) from [dbo].[T_ComixBillNo] where [BillTypeID]=@BillTypeID
SELECT @BillNo = '',@CurrDate =CONVERT(VARCHAR(8),GETDATE(),112)

BEGIN TRAN

--取现有表编号
SELECT @CurrSNo =[CurrSNO]
FROM [dbo].[T_ComixBillNoDetail]   WITH (RowLock,UpdLock)
WHERE [SalesDeptCode]=@SalesDeptCode   AND  BillTypeID= @BillTypeID AND  CurrDate=@CurrDate

If @CurrSNo is null --无明细记录自动插入新值
BEGIN
SET @CurrSNo=0
INSERT INTO [dbo].[T_ComixBillNoDetail]( [SalesDeptCode] ,[BillTypeID] ,[CurrSNO] ,[CurrDate] )
VALUES(@SalesDeptCode,@BillTypeID,@CurrSNo+1,@CurrDate)
END

Else     --编号+1
BEGIN
UPDATE [T_ComixBillNoDetail] SET CurrSNo=@CurrSNo+1
WHERE [SalesDeptCode]=@SalesDeptCode and BillTypeID=@BillTypeID and CurrDate=@CurrDate
END


IF @@ERROR=0
BEGIN
IF @@TRANCOUNT>0 COMMIT TRAN
--用于判断现在流水号是否超过规定长度
if LEN(@CurrSNo+1)>LEN(@SNo)
SET @SNo =REPLICATE('0',LEN(@CurrSNo+1))
SET @Length =LEN(@SNo)-LEN(@CurrSNo+1)
IF @Length<=0
BEGIN
SET @BillNo =@PreLetter+@SalesDeptCode+RIGHT(@CurrDate,6)+LTRIM(STR(@CurrSNo+1)) + @PostLetter
END
ELSE
BEGIN
SET @BillNo =@PreLetter+@SalesDeptCode+RIGHT(@CurrDate,6)+LEFT(@SNo,@Length) +LTRIM(STR(@CurrSNo+1)) + @PostLetter
END
END
ELSE
BEGIN
IF @@TRANCOUNT>0 ROLLBACK TRAN
SET @BillNo=''
END
RETURN 1

END


Go
IF OBJECT_ID('T_Identity', 'U') IS NOT NULL
DROP TABLE T_Identity
GO
CREATE TABLE T_Identity(
TableName NVARCHAR(40) PRIMARY KEY,
CurrID INT DEFAULT 0
)
GO
CREATE PROCEDURE Pr_GetIdentity(
@TableName NVARCHAR(40),
@CurrID INT OUTPUT
)
AS

BEGIN TRAN
BEGIN TRY
UPDATE T_Identity SET CurrID =CurrID+1 WHERE  TableName =@TableName
SELECT @CurrID=CurrID FROM t_Identity WHERE TableName= @TableName
IF @CurrID IS NULL
BEGIN
SET @CurrID=10001
INSERT INTO t_Identity VALUES(@TableName,@CurrID)
END
IF @@TRANCOUNT>0
BEGIN
COMMIT TRAN
END
END TRY
BEGIN CATCH
SET @CurrID =-1
IF @@TRANCOUNT >0
BEGIN
ROLLBACK TRAN
RETURN -1
END
END  CATCH
RETURN 1
Go


ALTER PROCEDURE Pr_GetIdentityByLock(

	@TableName NVARCHAR(40),

	@CurrNo INT OUTPUT

)

AS
	BEGIN TRAN

	BEGIN TRY    		

		UPDATE T_IdentityLock WITH(ROWLOCK) SET CurrNo =CurrNo+1 WHERE  TableName =@TableName 

		SELECT @CurrNo=CurrNo FROM T_IdentityLock WITH (ROWLOCK,UPDLOCK) WHERE TableName= @TableName  



		IF @CurrNo IS NULL

					BEGIN

					SET @CurrNo=1              

					INSERT INTO T_IdentityLock(TableName,CurrNo) VALUES(@TableName,@CurrNo)

					END

	

		IF @@TRANCOUNT>0

			BEGIN

				COMMIT TRAN

			END

	END TRY

	BEGIN CATCH

		SET @CurrNo =-1

		IF @@TRANCOUNT >0

			BEGIN

				ROLLBACK TRAN

				RETURN -1

			END

	END  CATCH 

	RETURN 1

Go

IF OBJECT_ID('T_IdentitySNO', 'U') IS NOT NULL
  DROP TABLE T_IdentitySNO
  GO
CREATE TABLE T_IdentitySNO(
    --ID INT  IDENTITY ,
	TableName NVARCHAR(40) ,
	BillID INT ,
	CurrSNO INT DEFAULT 0
	constraint Pk_SNO primary key(TableName,BillID)
)
go

--CREATE INDEX IX_T_IdentitySNO ON T_IdentitySNO(TableName,BillID) INCLUDE(CurrSNO);

GO
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = N'dbo'
     AND SPECIFIC_NAME = N'Pr_GetIdentitySNO' 
)
   DROP PROCEDURE Pr_GetIdentitySNO
GO
CREATE PROCEDURE Pr_GetIdentitySNO(
	@TableName NVARCHAR(40),
	@BillID INT ,
	@CurrSNO INT OUTPUT
)
AS
	BEGIN TRAN 
	BEGIN TRY    		 		  		           
			SELECT TOP 1 @CurrSNO=CurrSNO FROM T_IdentitySNO WITH (NOLOCK) WHERE TableName= @TableName  AND BillID=@BillID
			IF @CurrSNO IS NULL
				BEGIN   
					SELECT  TOP 1 * FROM T_IdentitySNO WITH (PAGLOCK,UPDLOCK) 
					ORDER BY TableName,BillID DESC              
					SELECT TOP 1 @CurrSNO=CurrSNO FROM T_IdentitySNO WITH(NOLOCK) WHERE TableName= @TableName  AND BillID=@BillID
					IF @CurrSNO IS NULL						                  
                    BEGIN	                 
							SELECT  * FROM T_IdentitySNO WITH (UPDLOCK)  
							ORDER BY TableName,BillID DESC   					
							SELECT TOP 1 @CurrSNO=CurrSNO FROM T_IdentitySNO WITH(NOLOCK) WHERE TableName= @TableName  AND BillID=@BillID    						             
							IF @CurrSNO IS NULL
							BEGIN                          
								SELECT * FROM T_IdentitySNO WITH (PAGLOCK,XLOCK)  
								ORDER BY TableName,BillID DESC   					
								SELECT TOP 1 @CurrSNO=CurrSNO FROM T_IdentitySNO WITH(NOLOCK) WHERE TableName= @TableName  AND BillID=@BillID
								IF @CurrSNO IS NULL                           
									BEGIN  
										SELECT * FROM T_IdentitySNO WITH (XLOCK)  				
										SELECT TOP 1 @CurrSNO=CurrSNO FROM T_IdentitySNO WITH(NOLOCK) WHERE TableName= @TableName  AND BillID=@BillID
								        IF @CurrSNO IS NULL                           
										BEGIN                    
											SET @CurrSNO=1    						    
											INSERT INTO T_IdentitySNO(TableName,BillID,CurrSNO) VALUES(@TableName,@BillID,@CurrSNO)	
										END		
										ELSE   
											BEGIN				
												GOTO l2		
											END									
									END    
								ELSE   
									BEGIN				
										GOTO l2		
									END	
							END            
							ELSE   
								BEGIN				
								GOTO l2		
								END	
                 
					END
					ELSE   
							BEGIN   					
							GOTO l2		
							END			                  
				END
			ELSE
				BEGIN   
				l2:		          
				UPDATE T_IdentitySNO SET @CurrSNO=CurrSNO =CurrSNO+1 WHERE  TableName =@TableName AND BillID=@BillID  
				END


		IF @@TRANCOUNT>0
			BEGIN
				COMMIT TRAN
			END
	END TRY
	BEGIN CATCH		
		BEGIN 
		SET @CurrSNO =-1
		IF @@TRANCOUNT >0
			BEGIN    
				ROLLBACK TRAN                
				RETURN  -1
			END
		END          
	END  CATCH 
	RETURN 1

Go






IF EXISTS (
SELECT *
FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_SCHEMA = N'pr_ChangeStatus'
AND SPECIFIC_NAME = N'pr_ChangeStatus'
)
DROP PROCEDURE pr_ChangeStatus
GO


CREATE PROCEDURE pr_ChangeStatus
@intBillID int,
@intNewStatus int,
@IsKBP BIT,
@intBillerID int
AS


SET NOCOUNT ON;

DECLARE @intStatus int,				/*订单的当前状态*/
@intOrgID INT,
@intCompanyID INT ,
@intDistributorID INT,
@intCompBranchID INT ,
@IsExist BIT,
@chvErrMsg varchar(200)			/*报错信息*/


------------------------------------------------------------------------------------------

SET @chvErrMsg = '状态变更发生错误！'
------------------------------------------------------------------------
BEGIN TRANSACTION
BEGIN TRY
SELECT @intStatus = BillStatus,@intOrgID=OrgID,@intCompanyID = CompanyID,
@intDistributorID=DistributorID,@intCompBranchID=CompBranchID
FROM MMP_SaleStandardCommon WITH(ROWLOCK,UPDLOCK) WHERE BillID = @intBillID


IF @intStatus IS NULL
BEGIN
SET @chvErrMsg='设置状态操作失败，找不到该订单！';
RAISERROR(@chvErrMsg,16,1)
END


--作废操作
IF @intNewStatus = -1
BEGIN
IF @intStatus <> 0       
  BEGIN          
   SET @chvErrMsg='状态不是新建状态，作废操作失败！'          
   RAISERROR(@chvErrMsg,16,1)          
  END          
  ELSE      
   BEGIN        
   UPDATE  MMP_SaleStandardCommon SET  BillStatus = -1,ModifyBillerID=@intBillerID,ModifyTime=GETDATE() WHERE BillID = @intBillID          
  END          
             
  END         
          
 --审核操作          
 IF @intNewStatus = 11         
 BEGIN           
  IF @intStatus <> 0              
  BEGIN          
   SET @chvErrMsg='状态不是新建状态，审核操作失败！'          
   RAISERROR(@chvErrMsg,16,1)          
  END          
  ELSE  
  BEGIN    
	SET @IsExist =0
	IF @IsKBP =1
	BEGIN 
	SET @chvErrMsg='已存在同一分公司审核过的数据！' 
	SELECT @IsExist =1 FROM MMP_SaleStandardCommon WITH(ROWLOCK,UPDLOCK) WHERE OrgID=@intOrgID AND BillStatus>=11
	END 
	IF @IsKBP =0 
	BEGIN 
	SET @chvErrMsg='已存在同一KDS帐户与经销商帐号与户头审核过的数据！' 
	SELECT @IsExist =1 FROM MMP_SaleStandardCommon WITH(ROWLOCK,UPDLOCK) WHERE CompanyID=@intCompanyID AND DistributorID=@intDistributorID AND CompBranchID=@intCompBranchID AND BillStatus>=11
	END
	IF @IsExist =1
	 BEGIN          		         
		RAISERROR(@chvErrMsg,16,1)          
	 END  
	IF @IsExist =0
		BEGIN   
		UPDATE  MMP_SaleStandardCommon SET  BillStatus = 11,ModifyBillerID=@intBillerID,ModifyTime=GETDATE() WHERE BillID = @intBillID                  
		END        
   END   
  END
         
           

          
 --反审核操作          
 IF @intNewStatus = 0          
 BEGIN           
  IF @intStatus <> 11          
  BEGIN--如果          
   SET @chvErrMsg='状态不为审核状态，不可反审核！'          
   RAISERROR(@chvErrMsg,16,1)          
  END          
  ELSE           
  BEGIN           
    UPDATE  MMP_SaleStandardCommon SET  BillStatus = 0,ModifyBillerID=@intBillerID,ModifyTime=GETDATE() WHERE BillID = @intBillID       
  END          
 END          
          
 IF @@TRANCOUNT>0          
 BEGIN          
  COMMIT TRANSACTION           
 END          
 RETURN 1          
          
END TRY           
------------------------------------------------------------------------------------------          
--执行出错,回滚TRANS          
BEGIN CATCH           
 IF @@TRANCOUNT>0           
 BEGIN           
  ROLLBACK TRANSACTION           
 END           
          
 SET @chvErrMsg=ERROR_MESSAGE()          
 RAISERROR(@chvErrMsg,16,1)          
 RETURN -1          
END CATCH           
        
          
RETURN 1
GO

