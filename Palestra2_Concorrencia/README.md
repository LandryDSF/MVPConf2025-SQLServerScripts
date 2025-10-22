# ⚙️ Concorrência no SQL Server 2025 Como o Optimized Locking Vai Mudar o Jogo

📅 **25/10/2025 – 10h | Sala 2 | MVP Conf 2025**

---

## 🎯 Descrição

Problemas de **concorrência** estão entre os maiores vilões da performance no SQL Server.  
Nesta sessão, revisamos os fundamentos de *locks*, níveis de isolamento e versionamento de linhas, e exploramos a grande novidade do **SQL Server 2025: Optimized Locking**, que promete reduzir contenção e melhorar a escalabilidade.

Serão demonstrados cenários práticos com bloqueios, deadlocks e impacto de isolamento, comparando a abordagem tradicional com o novo modelo otimizado.

---

## 🧠 Objetivos de Aprendizado
- Revisar os conceitos de concorrência otimista e pessimista  
- Entender os tipos de *locks* e sua influência na performance  
- Explorar os níveis de isolamento e o *row versioning*  
- Aplicar o novo recurso *Optimized Locking* do SQL Server 2025  

---

## 🧰 Conteúdo dos Scripts
1. Simulações de deadlocks e bloqueios comuns  
2. Consultas com `sys.dm_tran_locks`, `sys.dm_os_waiting_tasks` e `sys.dm_exec_requests`  
3. Demonstração prática de como o *Optimized Locking* reduz contenção  
4. Scripts de comparação entre o modelo tradicional e o novo comportamento do SQL Server 2025  

---

## ⚙️ Como Executar
1. Utilize um ambiente de **testes com duas ou mais sessões simultâneas**.  
2. Execute os scripts passo a passo para observar o comportamento dos locks.  
3. Monitore as DMV’s (`sys.dm_tran_locks`, `sys.dm_exec_sessions`) para acompanhar os efeitos.  
4. Compare os resultados com e sem o *Optimized Locking* habilitado.

---

## 📄 Referências
- [Transaction Locking and Row Versioning Guide – Microsoft Docs](https://learn.microsoft.com/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide)
- [SQL Server 2025 – Optimized Locking (Preview)](https://learn.microsoft.com/sql/)

---

> 💬 “Concorrência bem gerenciada é sinônimo de performance previsível — e o Optimized Locking é o próximo passo dessa evolução.”
