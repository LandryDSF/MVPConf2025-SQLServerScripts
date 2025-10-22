# 🧩 Descomplicando a TempDB: O Que é e por que você precisa cuidar bem dela?

📅 **24/10/2025 – 11h | Sala 2 | MVP Conf 2025**

---

## 🎯 Descrição

A **TempDB** é um dos bancos de sistema mais importantes do SQL Server — e também um dos mais ignorados.  
Nesta sessão, apresento como a configuração incorreta da TempDB pode gerar **lentidão, contenção de recursos e indisponibilidade** do ambiente.

Mostro, de forma prática, como diagnosticar gargalos e aplicar boas práticas de configuração, além de explorar a novidade do **SQL Server 2025: Resource Governor TempDB**, que promete uma administração muito mais eficiente.

---

## 🧠 Objetivos de Aprendizado
- Compreender o papel da TempDB no SQL Server  
- Identificar cenários de uso e gargalos comuns  
- Aplicar boas práticas de sizing, autogrowth e número de arquivos  
- Entender o funcionamento do *Resource Governor TempDB* no SQL Server 2025  

---

## 🧰 Conteúdo do Script: Landry - Entendendo o uso da TempDB.sql
1. Criação de cenários que simulam uso intensivo da TempDB  
2. Consultas de diagnóstico com sys.dm_db_file_space_usage, sys.dm_db_task_space_usage e sys.dm_exec_requests

---

## 🧰 Conteúdo do Script: Landry - SQL Server 2025 RG TempDB.sql
1. Como configurar o Resource Governor TempDB 
2. Simulação de atividade com um usuário classificado para restrição de consumo da TempDB.  

---

> 💬 “Quase tudo o que o SQL Server faz, em algum momento, passa pela TempDB.”
