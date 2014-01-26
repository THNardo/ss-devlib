USE master
GO
DECLARE @database_name VARCHAR(150) = 'HR'

DECLARE @sql_stmt VARCHAR(8000)

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

