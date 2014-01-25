SELECT T.TABLE_SCHEMA, 
       T.TABLE_NAME,
       C.COLUMN_NAME
  FROM INFORMATION_SCHEMA.TABLES T
       JOIN INFORMATION_SCHEMA.COLUMNS C
         ON C.TABLE_SCHEMA = T.TABLE_SCHEMA 
        AND C.TABLE_NAME = T.TABLE_NAME
ORDER BY T.TABLE_SCHEMA,
         T.TABLE_NAME,
         C.ORDINAL_POSITION