/*******************************************
 Autor: Landry Duailibe
 Data: 20/10/2025

 MVPCONF 2025
 – SQL Server 2025 Optimized Locking
********************************************/
use master
go

CREATE DATABASE MVPCONF_DB
go
ALTER DATABASE MVPCONF_DB SET RECOVERY simple
go

CREATE DATABASE MVPCONF_DB_OptLock
go
ALTER DATABASE MVPCONF_DB_OptLock SET RECOVERY simple
go

SELECT name as Banco,
is_accelerated_database_recovery_on as ADR_Enabled,
is_read_committed_snapshot_on as RCSI_Enabled,
is_optimized_locking_on as OptLock_Enabled
FROM sys.databases
WHERE name in ('MVPCONF_DB','MVPCONF_DB_OptLock')

/***********************************
 Banco MVPCONF_DB
 - Configuração padrão
************************************/
use MVPCONF_DB
go

DROP TABLE IF EXISTS dbo.Produto
CREATE TABLE dbo.Produto (
Produto_ID int not null CONSTRAINT pk_Produto PRIMARY KEY,
Produto varchar(50) not null,
Valor_Unitario decimal(19,2) null)
go
INSERT Produto VALUES 
(1, 'HD SSD 1TB', 400.00), 
(2, 'Notebook Dell i7', 4200.00), 
(3, 'Mouse Microsoft', 120.00)
go

/***********************************
 Banco MVPCONF_DB_OptLock
 - OPTIMIZED_LOCKING = ON
************************************/
use MVPCONF_DB_OptLock
go

DROP TABLE IF EXISTS dbo.Produto
CREATE TABLE dbo.Produto (
Produto_ID int not null CONSTRAINT pk_Produto PRIMARY KEY,
Produto varchar(50) not null,
Valor_Unitario decimal(19,2) null)
go
INSERT Produto VALUES 
(1, 'HD SSD 1TB', 400.00), 
(2, 'Notebook Dell i7', 4200.00), 
(3, 'Mouse Microsoft', 120.00)
go

/***********************************
 Habilitando 
************************************/
use master
go
-- 1. Ativar Accelerated Database Recovery (ADR) no banco de dados
ALTER DATABASE MVPCONF_DB_OptLock SET ACCELERATED_DATABASE_RECOVERY = ON

-- 2. Ativar Read Committed Snapshot Isolation (RCSI) no banco de dados
ALTER DATABASE MVPCONF_DB_OptLock SET READ_COMMITTED_SNAPSHOT ON

-- 3. Ativar Optimized Locking no banco de dados
ALTER DATABASE MVPCONF_DB_OptLock SET OPTIMIZED_LOCKING = ON



/***************************************
 Hands On 1
 - Atualizando todas as linhas
 - Quantidade menor de Locks
****************************************/
-- Sessão 1
BEGIN TRAN
UPDATE Produto SET Valor_Unitario = Valor_Unitario + 10

ROLLBACK
go

-- Sessão 2
exec sp_lock 58

SELECT request_session_id, resource_type, resource_description, request_mode,request_status
FROM sys.dm_tran_locks
WHERE request_session_id in (58) 
ORDER BY request_session_id

/* Configuração Padrão

resource_type  resource_description   request_mode
-------------- ---------------------- ---------------
DATABASE                              S
PAGE           1:312                  IX
KEY            (98ec012aa510)         X
KEY            (8194443284a0)         X
OBJECT                                IX
KEY            (61a06abd401c)         X
*/

/* Com OPTIMIZED_LOCKING

resource_type   resource_description  request_mode
--------------- --------------------- ---------------
DATABASE                              S
XACT            XACT: 13:1082:0       X
OBJECT                                IX
*/


/**************************************************
 Hands On 2
 - Duas Transações atualizando linhas diferentes
 - Filtro na PK
 - Atualização ocorre em ambas as sessões
***************************************************/
-- Sessão 1
BEGIN TRAN
UPDATE Produto SET Valor_Unitario = Valor_Unitario + 10
WHERE Produto_ID = 1

ROLLBACK
go

-- Sessão 2
BEGIN TRAN
UPDATE Produto SET Valor_Unitario = Valor_Unitario + 10
WHERE Produto_ID = 2

ROLLBACK
go


/**************************************************
 Hands On 3
 - Duas Transações atualizando linhas diferentes
 - Filtro em coluna sem índice
 - Sem Optimized Locking fica bloqueada a sessão 2!
***************************************************/
-- Sessão 1
BEGIN TRAN
UPDATE Produto SET Valor_Unitario = Valor_Unitario + 10
WHERE Produto = 'HD SSD 1TB'

ROLLBACK
go

-- Sessão 2
BEGIN TRAN
UPDATE Produto SET Valor_Unitario = Valor_Unitario + 10
WHERE Produto = 'Notebook Dell i7'

ROLLBACK
go


/********************
 Exclui Banco
*********************/
use master
go
DROP DATABASE IF exists MVPCONF_DB
DROP DATABASE IF exists MVPCONF_DB_OptLock

