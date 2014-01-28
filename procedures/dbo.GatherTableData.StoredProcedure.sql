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
--      column_default VARCHAR(150),
--      data_type VARCHAR(150),
--      char_max_len INT,
--      numeric_precision INT,
--      numeric_scale INT,
--      domain_name VARCHAR(150),
      dt_derived VARCHAR(150),
--      column_name_and_data_type_derived VARCHAR(150),
--      derived_data_type VARCHAR(150),
      is_nullable BIT,
      is_first_column BIT,
      is_last_column BIT,
      is_pk_column BIT DEFAULT 0,
      table_schema VARCHAR(150),
      table_desc VARCHAR(500),
      column_desc VARCHAR(500)
      )

   EXECUTE('
      INSERT INTO ##TableData
         (table_schema, table_name, column_name, is_identity, ordinal_position,
          dt_derived, is_first_column, is_last_column, is_nullable)
      SELECT T.TABLE_SCHEMA AS table_schema,
             T.TABLE_NAME AS table_name,
             C.COLUMN_NAME AS column_name,
             CASE
                WHEN (SELECT is_identity
                        FROM '+@database_name+'.sys.columns SC
                       WHERE SC.object_id = OBJECT_ID(T.TABLE_NAME)
                         AND SC.name = C.COLUMN_NAME
                       ) = 1
                  THEN 1
                  ELSE 0
             END  AS is_identity,
             C.ORDINAL_POSITION AS ordinal_position,
             CASE
                WHEN C.DATA_TYPE = ''int''
                   THEN ''INT''
                WHEN C.DATA_TYPE = ''varchar''
                   THEN ''VARCHAR''+CASE
                                     WHEN C.CHARACTER_MAXIMUM_LENGTH IS NOT NULL
                                        THEN ''(''+CONVERT(VARCHAR(30),CHARACTER_MAXIMUM_LENGTH)+'')''
                                     ELSE ''''
                                  END
                   ELSE UPPER(C.DATA_TYPE)
             END AS dt_derived,
             CASE
                WHEN ordinal_position = (SELECT MIN(ordinal_position)
                                           FROM '+@database_name+'.INFORMATION_SCHEMA.COLUMNS FC
                                          WHERE FC.TABLE_SCHEMA = T.TABLE_SCHEMA
                                            AND FC.TABLE_NAME = T.TABLE_NAME)
                   THEN 1
                   ELSE 0
             END AS is_first_column,
             CASE
                WHEN ordinal_position = (SELECT MAX(ordinal_position)
                                           FROM '+@database_name+'.INFORMATION_SCHEMA.COLUMNS LC
                                          WHERE LC.TABLE_SCHEMA = T.TABLE_SCHEMA
                                            AND LC.TABLE_NAME = T.TABLE_NAME)
                   THEN 1
                   ELSE 0
             END AS is_last_column,
             CASE
                WHEN C.IS_NULLABLE = ''YES''
                   THEN 1
                ELSE 0
             END AS is_nullable
        FROM '+@database_name+'.INFORMATION_SCHEMA.TABLES T
             JOIN '+@database_name+'.INFORMATION_SCHEMA.COLUMNS C
               ON C.TABLE_SCHEMA = T.TABLE_SCHEMA
              AND C.TABLE_NAME = T.TABLE_NAME
       WHERE T.TABLE_NAME NOT IN (''sysdiagrams'')
      ORDER BY T.TABLE_SCHEMA,
               T.TABLE_NAME,
               C.ORDINAL_POSITION'
         )

   EXECUTE('UPDATE ##TableData
               SET is_pk_column = 1
              FROM ##TableData TD
                   JOIN (SELECT KCU.TABLE_SCHEMA AS table_schema,
                                KCU.TABLE_NAME AS table_name,
                                KCU.COLUMN_NAME AS column_name
                           FROM '+@database_name+'.INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
                                JOIN '+@database_name+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
                                  ON TC.TABLE_SCHEMA = KCU.TABLE_SCHEMA
                                 AND TC.TABLE_NAME = KCU.TABLE_NAME
                                 AND TC.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
                          WHERE TC.CONSTRAINT_TYPE = ''PRIMARY KEY''
                        ) tmp
                     ON tmp.table_schema = TD.table_schema
                    AND tmp.table_name = TD.table_name
                    AND tmp.column_name = TD.column_name'
          )      

END -- End Main Block