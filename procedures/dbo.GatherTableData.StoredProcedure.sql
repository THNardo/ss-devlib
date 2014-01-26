USE devlib
GO
ALTER PROCEDURE dbo.GatherTableData (
   @database_name VARCHAR(150)
)
AS
/*
** ============================================================================
**   Procedure Name: GatherTableData
**   Author:         T. Henry Nardo
**   Date Created:   01/26/2014 (original date: 10/02/2002)
**   Purpose:        Procedure that will gather and consolidate necessary data 
**                   from the information schema 
**
**   Modification History
**   Date        By   Modification
**   ----------  ---  ------------
**   MM/DD/RRRR  XXX  XXX...
** ============================================================================
*/
-- Local Variables and Program Data
DECLARE
   @sql_stmt VARCHAR(8000) 

BEGIN -- Begin Main Block

   -- drop temp table if it exists
   IF OBJECT_ID('tempdb..##TableData') IS NOT NULL
      DROP TABLE ##TableData

   -- drop temp table if it exists
   IF OBJECT_ID('tempdb..##PKColumns') IS NOT NULL
      DROP TABLE ##PKColumns

   -- drop temp table if it exists
   IF OBJECT_ID('tempdb..##NonPKColumns') IS NOT NULL
      DROP TABLE ##NonPKColumns

   -- create temp table
   CREATE TABLE ##TableData(
      table_name VARCHAR(150),
      column_name VARCHAR(150),
      is_identity BIT,
      ordinal_position INT,
      column_default VARCHAR(150),
      data_type VARCHAR(150),
      char_max_len INT,
      numeric_precision INT,
      numeric_scale INT,
      domain_name VARCHAR(150),
      data_type_derived VARCHAR(150),
      column_name_and_data_type_derived VARCHAR(150),
      derived_data_type VARCHAR(150),
      is_nullable BIT,
      is_first_column BIT,
      is_last_column BIT,
      table_schema VARCHAR(150),
      table_desc VARCHAR(500),
      column_desc VARCHAR(500)
      )

   -- create temp table
   CREATE TABLE ##PKColumns(
      table_name VARCHAR(150),
      column_name VARCHAR(150)
      )

   -- create temp table
   CREATE TABLE ##NonPKColumns(
      table_name VARCHAR(150),
      column_name VARCHAR(150),
      ordinal_position INT
      )

   SET @sql_stmt = 'USE '+@database_name+CHAR(13)+
   'SELECT T.TABLE_SCHEMA AS table_schema,
          T.TABLE_NAME AS table_name,
          C.COLUMN_NAME AS column_name,
          CASE
             WHEN COLUMNPROPERTY(OBJECT_ID(T.TABLE_NAME), C.COLUMN_NAME, ''IsIdentity'') = 1
               THEN 1
               ELSE 0
          END as is_identity
     FROM '+@database_name+'.INFORMATION_SCHEMA.TABLES T
          JOIN '+@database_name+'.INFORMATION_SCHEMA.COLUMNS C
            ON C.TABLE_SCHEMA = T.TABLE_SCHEMA
           AND C.TABLE_NAME = T.TABLE_NAME
   ORDER BY T.TABLE_SCHEMA,
            T.TABLE_NAME,
            C.ORDINAL_POSITION
   '

   EXECUTE( @sql_stmt)

END -- End Main Block