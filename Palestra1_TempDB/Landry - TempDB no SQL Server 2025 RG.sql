/************************************************
 Autor: Landry Duailibe

 Live #084 
 – Resource Governor TempDB no SQL Server 2025
*************************************************/
use master
go

/*****************************************
 Habilitando Resource Governor (RG)
******************************************/
-- Verifica Status
SELECT is_enabled FROM sys.resource_governor_configuration

-- Para habilitar RG
-- Não precisa reiniciar o SQL Server
ALTER RESOURCE GOVERNOR RECONFIGURE

CREATE RESOURCE POOL RP_TempDB
WITH (MAX_CPU_PERCENT = 75,MAX_MEMORY_PERCENT = 75)

CREATE WORKLOAD GROUP RG_TempDB_Group USING RP_TempDB

SELECT * FROM sys.resource_governor_resource_pools
SELECT * FROM sys.resource_governor_workload_groups

/*************************************************
 Limitando o uso dos arquivos de dados da TempDB
**************************************************/
-- Pode limitar o uso da TempDB por valor absoluto em MB
ALTER WORKLOAD GROUP RG_TempDB_Group WITH (GROUP_MAX_TEMPDB_DATA_MB = 1)
ALTER RESOURCE GOVERNOR RECONFIGURE

ALTER WORKLOAD GROUP RG_TempDB_Group WITH (GROUP_MAX_TEMPDB_DATA_PERCENT = 10)
ALTER RESOURCE GOVERNOR RECONFIGURE

/**********************************************
 Cria Login para testar o limite
***********************************************/
-- Cria Server Role
CREATE SERVER ROLE [srv_role_TempDB]
go
-- Cria Login de teste
CREATE LOGIN [Teste_Login] WITH PASSWORD=N'senha', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
go
ALTER SERVER ROLE [srv_role_TempDB] ADD MEMBER [Teste_Login]
go

USE AdventureWorks
go
CREATE USER [Teste_Login] FOR LOGIN [Teste_Login]
go
ALTER ROLE [db_datareader] ADD MEMBER [Teste_Login]
go
 
/************************************************************
 Função de Classificação
 https://learn.microsoft.com/en-us/sql/relational-databases/resource-governor/resource-governor-classifier-function?view=sql-server-ver17
*************************************************************/
use master
go

CREATE or ALTER FUNCTION dbo.RG_ClassifierFunction()
RETURNS sysname
WITH SCHEMABINDING
AS
BEGIN

DECLARE @Login sysname
SELECT @Login = SUSER_NAME()

IF (SELECT IS_SRVROLEMEMBER('srv_role_TempDB', @Login)) = 1
    RETURN 'RG_TempDB_Group'

RETURN 'default'
END
go
/************* FIM Função **************/

-- Associa a função ao Resource Governor
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.RG_ClassifierFunction)
ALTER RESOURCE GOVERNOR RECONFIGURE

-- Retorna informações da Função de Classificação
SELECT a.classifier_function_id as FuncaoClassificacao_id,
b.[name] as FuncaoClassificacao,
a.is_enabled,
c.[definition] as ddl
FROM sys.resource_governor_configuration a
JOIN sys.objects b ON a.classifier_function_id = b.[object_id]
JOIN sys.sql_modules c ON b.[object_id] = c.[object_id]


/**********************************
 Testando a Restrição na TempDB
 - Fazer login com "Teste_Login"
***********************************/
exec sp_helpdb 'tempdb'

SELECT * INTO #temptable FROM AdventureWorks.[Sales].[SalesOrderDetail]

SELECT * FROM #temptable

DROP TABLE #temptable

/******************************************************************
 Quantidade de vezes que atingiu o limite por Resource Pool
*******************************************************************/
SELECT a.group_id, a.[name], 
a.total_tempdb_data_limit_violation_count as Qtd_Atingiu_Limite,
a.tempdb_data_space_kb as TempDB_Limite_Atual,
a.peak_tempdb_data_space_kb as TempDB_Limite_UltimaInicializacao
FROM sys.dm_resource_governor_workload_groups a
JOIN sys.resource_governor_workload_groups b
ON a.[name] = b.[name]


/***********************************
 Exclui objetos criados no HandsOn
************************************/
use AdventureWorks
go
DROP USER [Teste_Login]

use master
go
DROP LOGIN [Teste_Login]
DROP SERVER ROLE [srv_role_TempDB]
go

ALTER RESOURCE GOVERNOR DISABLE
go
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
go
DROP FUNCTION IF EXISTS RG_ClassifierFunction

DROP WORKLOAD GROUP RG_TempDB_Group
DROP RESOURCE POOL RP_TempDB
go
-- Reiniciar o SQL Server

