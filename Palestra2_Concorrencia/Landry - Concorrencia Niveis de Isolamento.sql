/*******************************************************************
 Autor: Landry Duailibe
 Data: 20/10/2025

 MVPCONF 2025
 - Cria Banco de Dados DB_Concorrencia
 - Blocking
 - Versionamento de Linha
********************************************************************/
USE master
go

CREATE DATABASE DB_Concorrencia
go
ALTER DATABASE DB_Concorrencia SET RECOVERY simple
go

USE DB_Concorrencia
go

-- Cria Tabela para demonstração
DROP TABLE IF exists dbo.Funcionario
go
CREATE TABLE dbo.Funcionario (PK int, Nome varchar(50), Descricao varchar(100), Status char(1),Salario decimal(10,2))
INSERT dbo.Funcionario VALUES (1,'Fernando','Gerente','B',5600.00)
INSERT dbo.Funcionario VALUES (2,'Ana Maria','Diretor','A',7500.00)
INSERT dbo.Funcionario VALUES (3,'Lucia','Gerente','B',5600.00)
INSERT dbo.Funcionario VALUES (4,'Pedro','Operacional','C',2600.00)
INSERT dbo.Funcionario VALUES (5,'Carlos','Diretor','A',7500.00)
INSERT dbo.Funcionario VALUES (6,'Carol','Operacional','C',2600.00)
INSERT dbo.Funcionario VALUES (7,'Luana','Operacional','C',2600.00)
INSERT dbo.Funcionario VALUES (8,'Lula','Diretor','A',7500.00)
INSERT dbo.Funcionario VALUES (9,'Erick','Operacional','C',2600.00)
INSERT dbo.Funcionario VALUES (10,'Joana','Operacional','C',2600.00)
go


/****************************************************************************************
 Hands On 1: READ_COMMITTED padrão  
  - Leitura bloqueia escrita.
*****************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRAN
  UPDATE dbo.Funcionario SET Salario = 3000.00 WHERE PK = 10
  SELECT * FROM dbo.Funcionario WHERE PK = 10 -- Salario = 2600.00

  ROLLBACK

-- *** Conexão B ***
SELECT * FROM DB_Concorrencia.dbo.Funcionario --with(nolock)
WHERE PK = 10

/************************************
 SQL Server 7.0 e 2000
*************************************/
EXEC sp_who2
EXEC sp_lock 53
EXEC sp_lock 54
DBCC INPUTBUFFER (53)
DBCC INPUTBUFFER (54)

/*************************************
 SQL Server 2005 em diante
*************************************/
SELECT * FROM sys.dm_exec_connections
SELECT * FROM sys.dm_exec_sessions where session_id > 50 and session_id <> @@spid
SELECT * FROM sys.dm_exec_requests where session_id > 50 and session_id <> @@spid
SELECT * FROM sys.dm_tran_locks

SELECT session_id as Sessao, [status] as [Status], 
db_name(database_id) as Banco,
blocking_session_id as Sessao_Blocking,
wait_resource as Recurso_Blocking
FROM sys.dm_exec_requests 
WHERE session_id <> @@spid
and blocking_session_id > 0

/***********************************************
 Locks
************************************************/
SELECT a.session_id, a.start_time, a.[status],a.command,
a.total_elapsed_time / 100 as TempoExec_Seg,
b.text as 'TSQL', db_name(a.database_id) as Banco, 
blocking_session_id as Blocking,wait_type,wait_resource,wait_time / 1000 Wait_Seg,
open_transaction_count as TransacoesAbertas, cpu_time, logical_reads * 8 as Leituras_KB

FROM sys.dm_exec_requests a 
OUTER APPLY sys.dm_exec_sql_text(a.sql_handle) AS b
WHERE session_id > 50

-- Locks
SELECT resource_type as Resurso, 
resource_description as Recurso_Desc,
request_mode as Lock, request_status as 'Status'
FROM sys.dm_tran_locks
WHERE request_session_id = 88

SELECT resource_type as Resurso, 
resource_description as Recurso_Desc,
request_mode as Lock, request_status as 'Status'
FROM sys.dm_tran_locks
WHERE request_session_id = 90


-- Retorna Sessões em Bloqueio
SELECT w.session_id,w.wait_duration_ms,w.wait_type,w.blocking_session_id,w.resource_description,
s.program_name,t.text,t.dbid,s.cpu_time,s.memory_usage
FROM sys.dm_os_waiting_tasks w
JOIN sys.dm_exec_sessions s ON w.session_id = s.session_id
JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
WHERE s.is_user_process = 1

-- Retorna Sessões raiz do Blocking
SELECT spid,sp.STATUS,SUBSTRING(loginame, 1, 12) as loginame,
SUBSTRING(hostname, 1, 12) as hostname,CONVERT(CHAR(3), blocked) as blk,
open_tran,SUBSTRING(DB_NAME(sp.dbid),1,10) as dbname,cmd,waittype,waittime,
last_batch,SUBSTRING(qt.text,er.statement_start_offset/2,
(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
      ELSE er.statement_end_offset END - er.statement_start_offset)/2) as SQLStatement
FROM sys.sysprocesses sp
LEFT JOIN sys.dm_exec_requests er ON er.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
WHERE spid IN (SELECT blocked FROM sys.sysprocesses) AND blocked = 0

/****************************************************************************************
 Hands On 2: READ_COMMITTED_SNAPSHOT Isolation Level
 - Versionamento de linhas no Banco TempDB
*****************************************************************************************/
use master
go

-- Habilita o banco para DB_Concorrencia Isolation Level
ALTER DATABASE DB_Concorrencia SET READ_COMMITTED_SNAPSHOT ON

-- Desabilita o READ_COMMITTED_SNAPSHOT no banco
ALTER DATABASE DB_Concorrencia SET READ_COMMITTED_SNAPSHOT OFF

-- Exclui banco
use master
go
ALTER DATABASE DB_Concorrencia SET SINGLE_USER WITH ROLLBACK IMMEDIATE
go
DROP DATABASE IF exists DB_Concorrencia

