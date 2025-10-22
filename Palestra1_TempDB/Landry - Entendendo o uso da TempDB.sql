/**************************************************
 Autor: Landry Duailibe
 Data: 20/10/2025

 MVPCONF 2025: Entendendo o uso da TempDB
***************************************************/
use master
go

/************************************************
 Uso da TEMPDB por Consulta em Tabel Grande
*************************************************/
DROP DATABASE IF exists HandsOn
go
CREATE DATABASE HandsOn 
ON  PRIMARY 
(NAME = N'HandsOn', FILENAME = N'C:\MSSQL_Data\HandsOn.mdf' , SIZE = 10GB , FILEGROWTH = 500MB)
LOG ON 
(NAME = N'HandsOn_log', FILENAME = N'C:\MSSQL_Data\HandsOn_log.ldf' , SIZE = 5GB , FILEGROWTH = 65536KB)
go
ALTER DATABASE HandsOn SET RECOVERY SIMPLE 
go
-- Leva 1 min para criar

/*********************************
 Cria Tabela com 7.8GB de ocupação
**********************************/
use HandsOn
go

DROP TABLE IF exists dbo.Cliente
go
CREATE TABLE dbo.Cliente (
Cliente_ID int NOT NULL identity CONSTRAINT pk_ PRIMARY KEY,
TipoCliente_ID char(2) NOT NULL,
TipoCliente varchar(100) NOT NULL,
Nome char(1000) not null,
Sufixo char(1000) NULL,
Email char(1000) NOT NULL,
rowguid uniqueidentifier ROWGUIDCOL  NOT NULL,
DataAlteracao datetime NOT NULL)
go

set nocount on
go

-- Inclui 100 linhas
INSERT dbo.Cliente (TipoCliente_ID,TipoCliente, Nome, Sufixo, Email, rowguid, DataAlteracao)
SELECT top 100 'SA' as TipoCliente_ID, 
'Store Account' as TipoCliente,
FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as Nome, 
Suffix as Sufixo, b.EmailAddress as Email, rowguid, ModifiedDate as DataAlteracao 
FROM AdventureWorks.Person.Person a
JOIN (SELECT BusinessEntityID, max(EmailAddress) as EmailAddress FROM AdventureWorks.Person.EmailAddress GROUP BY BusinessEntityID) b
on a.BusinessEntityID = b.BusinessEntityID
go

-- Executa 200x o INSERT...SELECT
INSERT dbo.Cliente (TipoCliente_ID,TipoCliente, Nome, Sufixo, Email, rowguid, DataAlteracao)
SELECT PersonType as TipoCliente_ID, 
CASE PersonType
WHEN 'SC' THEN 'Store Contact'
WHEN 'IN' THEN 'Individual (retail) customer'
WHEN 'SP' THEN 'Sales person'
WHEN 'EM' THEN 'Employee (non-sales)'
WHEN 'VC' THEN 'Vendor contact' 
WHEN 'GC' THEN 'General contact'
END as TipoCliente,
FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as Nome, 
Suffix as Sufixo, b.EmailAddress as Email, rowguid, ModifiedDate as DataAlteracao 
FROM AdventureWorks.Person.Person a
JOIN (SELECT BusinessEntityID, max(EmailAddress) as EmailAddress FROM AdventureWorks.Person.EmailAddress GROUP BY BusinessEntityID) b
on a.BusinessEntityID = b.BusinessEntityID
go 200

-- Inclui 50 linhas
INSERT dbo.Cliente (TipoCliente_ID,TipoCliente, Nome, Sufixo, Email, rowguid, DataAlteracao)
SELECT top 50 'SA' as TipoCliente_ID, 
'Store Account' as TipoCliente,
FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as Nome, 
Suffix as Sufixo, b.EmailAddress as Email, rowguid, ModifiedDate as DataAlteracao 
FROM AdventureWorks.Person.Person a
JOIN (SELECT BusinessEntityID, max(EmailAddress) as EmailAddress FROM AdventureWorks.Person.EmailAddress GROUP BY BusinessEntityID) b
on a.BusinessEntityID = b.BusinessEntityID
go

-- Leva 17 minutos para executar
/***************************** FIM Prepara Hands On *********************************/


/***************************
 Gera atividade na TEMPDB
****************************/

CREATE TABLE #TempTable (ID INT IDENTITY(1,1), Coluna1 CHAR(8000))
GO

INSERT INTO #TempTable (Coluna1)
VALUES (REPLICATE('A',8000))
go 100000 -- Inclui 100.000 linhas

INSERT INTO #TempTable (Coluna1)
VALUES (REPLICATE('A',8000))
go 400000 -- Inclui 400.000 linhas

DROP TABLE #TempTable

SELECT * FROM #TempTable

/*************************** 
 Monitorando a TEMPDB
 - Abrir outra sessão
****************************/
-- Espaço Utilizado na TempDB
SELECT SUM(unallocated_extent_page_count) * 8 / 1024 AS [Espaço Livre em MB], -- Espaço não alocado
SUM(version_store_reserved_page_count) * 8 / 1024 AS [Version Store em MB], -- Versionamento de linhas
SUM(user_object_reserved_page_count) * 8 / 1024 AS [Objetos de Usuário em MB], -- Tabelas temporárias
SUM(internal_object_reserved_page_count) * 8 / 1024 AS [Objetos Internos em MB] -- Worktables
FROM tempdb.sys.dm_db_file_space_usage

/****************************************
 Espaço Utilizado por sessão na TempDB
*****************************************/
SELECT tsu.[session_id], tsu.exec_context_id,
es.host_name as [Host], es.login_name as [Login], es.program_name as Aplicacao,

SUBSTRING(st.text, er.statement_start_offset/2 + 1,
(CASE WHEN er.statement_end_offset = -1 
THEN LEN(CONVERT(nvarchar(max),st.text)) * 2 
ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) as Query,

(SELECT SUBSTRING(st.text, er.statement_start_offset/2 + 1,
(CASE WHEN er.statement_end_offset = -1 
THEN LEN(CONVERT(nvarchar(max), st.text)) * 2 
ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) AS [text()]
FOR XML PATH('query'), TYPE) AS Query_XML,

tsu.user_objects_alloc_page_count * 8 as User_Objects_Alloc_KB, 
tsu.user_objects_dealloc_page_count * 8 as User_Objects_Dealloc_KB, 
(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) * 8 as User_Objects_Ativas_KB,
tsu.internal_objects_alloc_page_count * 8 as Internal_Objects_Alloc_KB,
tsu.internal_objects_dealloc_page_count * 8 as Internal_Objects_Dealloc_KB,
(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) * 8 as Internal_Objects_Ativas_KB,
er.start_time as DataHora_InicioExec, 
er.command as TipoComando, 
er.open_transaction_count as Qtd_Trasacoes, 
er.cpu_time as CPU, 
er.total_elapsed_time TempoExecucao_MS, 
er.reads as Leituras,er.writes as Escritas, 
er.logical_reads as LogicalReads, 
er.granted_query_memory * 16 as Memoria_KB
FROM sys.dm_db_task_space_usage tsu 
JOIN sys.dm_exec_requests er ON tsu.session_id = er.session_id and tsu.request_id = er.request_id
JOIN sys.dm_exec_sessions es ON tsu.session_id = es.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st

WHERE tsu.session_id <> @@spid
ORDER BY tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count desc


/********************************************
 Uso do Version Store por banco de dados
*********************************************/
SELECT b.name as Banco, a.reserved_page_count * 8 as Uso_KB
FROM sys.dm_tran_version_store_space_usage a
JOIN sys.databases b on b.database_id = a.database_id
ORDER BY Uso_KB desc

/********************************************
 Consultas sem Índices em Tabelas Grandes
*********************************************/
set statistics io on
set statistics io off

-- Utiliza TEMPDB para Sort
SELECT TOP 150 * FROM dbo.Cliente
ORDER BY DataAlteracao DESC
/*
Table 'Cliente'. Scan count 4, logical reads 2012104
Total de IO = 2012104 pg x 8 KB = 16096832 KB = 15719 MB = 15 GB
*/

-- DROP INDEX dbo.Cliente.ix_Cliente_DataAlteracao
CREATE INDEX ix_Cliente_DataAlteracao ON dbo.Cliente (DataAlteracao)
-- 1 minuto

/*******************************************
 Uso do Version Store por Triggers
********************************************/
DROP TABLE IF exists dbo.Funcionario
go
CREATE TABLE dbo.Funcionario (
Funcionario_ID int not null identity CONSTRAINT pk_Funcionario PRIMARY KEY,
Nome char(1000) not null,
Email char(1000) not null,
DataAlteracao datetime NOT NULL)
go

-- Cria Trigger
go
CREATE TRIGGER trg_Funcionario_INSERT ON dbo.Funcionario
FOR INSERT
as

DECLARE @i int = 1
WHILE @i >= 1000 BEGIN
	SELECT * FROM INSERTED
	SET @i += 1
END
go


-- Inclusão de Linhas em Tabela com Trigger, provoca uso do Versionamento de Linhas
INSERT dbo.Funcionario (Nome, Email, DataAlteracao)
SELECT FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as Nome, 
b.EmailAddress as Email, ModifiedDate as DataAlteracao 
FROM AdventureWorks.Person.Person a
JOIN (SELECT BusinessEntityID, max(EmailAddress) as EmailAddress FROM AdventureWorks.Person.EmailAddress GROUP BY BusinessEntityID) b
on a.BusinessEntityID = b.BusinessEntityID
go 100


-- Exclui tabela Cliente
DROP TABLE IF exists dbo.Funcionario

/******************************
 Exclui banco
*******************************/
USE master
go
ALTER DATABASE [HandsOn] SET  READ_ONLY WITH ROLLBACK IMMEDIATE
go
DROP DATABASE IF exists HandsOn
go
