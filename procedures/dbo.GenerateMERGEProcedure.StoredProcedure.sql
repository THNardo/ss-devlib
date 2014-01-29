USE devlib
GO
ALTER PROCEDURE dbo.GenerateMERGEProcedure(
   @schema_name VARCHAR(150),
   @proc_prefix VARCHAR(150),
   @proc_suffix VARCHAR(150),
   @database_name VARCHAR(150)
   )
AS 
/*
** ============================================================================
** General
**    Proc Name:     GenerateMERGEProcedure
**    Author:        T. Henry Nardo
**    Date Created:  01/26/2014 (Original 05/13/2009)
**    Purpose:       Procedure that will generate MERGE procedures for tables
**                   in the database passed in parameter @database_name.
**
** Modification History
**    Date        By   Modification
**    ----------  ---  ------------
**    MM/DD/YYYY  XXX  XXX...
** ============================================================================
*/
-- Local Variables and Program Data
DECLARE
   @table_name VARCHAR(150),
   @temp_table_name VARCHAR(150),
   @column_name VARCHAR(150),
   @is_first_column BIT,
   @is_last_column BIT,
   @proc_name VARCHAR(150),
   @proc_line_num INTEGER = 1,
   @proc_line_value VARCHAR(200),
   @seq_start_val INT,
   @dt_derived VARCHAR(150),
   @is_nullable BIT

-- Main T-SQL Block
BEGIN -- Begin Main Block

   IF OBJECT_ID('tempdb..##TableData') IS NOT NULL
      DROP TABLE ##TableData

   EXECUTE dbo.GatherTableData @database_name = @database_name

   IF OBJECT_ID('tempdb..##generated_proc') IS NOT NULL
      DROP TABLE ##generated_proc

   CREATE TABLE ##generated_proc(
      proc_name VARCHAR(150),
      line_num INT IDENTITY(1,1),
      line_value VARCHAR(200)
   )

   DECLARE TableCur CURSOR
   FOR SELECT DISTINCT 
              table_name
         FROM ##TableData
       ORDER BY table_name

   DECLARE TableDataCur CURSOR
   FOR SELECT column_name,
              is_identity,
              ordinal_position,
              dt_derived,
              is_nullable,
              is_last_column
         FROM ##TableData
        WHERE table_name = ''
          AND is_identity = 0
          AND @table_name <> 'error_log'
       ORDER BY ordinal_position

   --DECLARE @table_name VARCHAR(150)

   OPEN TableCur

   FETCH NEXT FROM TableCur INTO @table_name

   WHILE( @@FETCH_STATUS = 0 )
   BEGIN

      SET @proc_name = @schema_name+'.'+@proc_prefix+' '+@table_name+ISNULL(@proc_suffix,'')
      SET @proc_line_value = 'CREATE PROCEDURE '+@proc_name+'()'

      INSERT INTO ##generated_proc (proc_name, line_value)
      VALUES (@proc_name, @proc_line_value)

      INSERT INTO ##generated_proc (proc_name, line_value)
      SELECT @proc_name, line_value
        FROM (
              VALUES
                 ('/*'),
                 ('** =============================================================================='),
                 ('** General'),
                 ('**    Proc Name:    '+@proc_name),
                 ('**    Author:       '+SUSER_SNAME()),
                 ('**    Date Created: '+CONVERT(VARCHAR(30), GETDATE())),
                 ('**    Purpose:       Generate a MERGE style procedure for '+@table_name),
                 ('**'),
                 ('** Modification History'),
                 ('**    Date        By   Modification'),
                 ('**    ----------  ---  ------------'),
                 ('**    MM/DD/YYYY  XXX  XXX...'),
                 ('** =============================================================================='),
                 ('*/'),
                 ('-- Local Variables and Program Data'),
                 ('DECLARE'),
                 ('   @error_num = INT,'),
                 ('   @error_message = VARCHAR(255)'),
                 ('   @procedure_name = VARCHAR(150) = '+''''+@proc_name+''''+','),
                 ('   @table_name VARCHAR(150) = '+@table_name+','),
                 ('   @prev_rec_count INT = 0,'),
                 ('   @curr_rec_count INT = 0,'),
                 ('   @recs_inserted INT = 0,'), 
                 (' '),
                 ('-- Main T-SQL Block'),
                 ('BEGIN -- Begin Main Block'),
                 ('   SET NOCOUNT ON'),
                 (' '),
                 ('   -- Set Audit Information'),
                 ('   SET @audit_user = 1'),
                 ('   SET @audit_date = getDate()'),
                 (' '),
                 ('   -- Load Status Information'),
                 ('   SET @table_name = '''+@table_name+''''),
                 ('   SET @program_unit = '''+@proc_name+''''),
                 ('   SET @pu_type = ''SP'''),
                 ('   SET @dbname = DB_Name()'),
                 ('   SET @start_date = @audit_date'),
                 ('   SET @system_name = @dbname'),
                 ('   PRINT @program_unit'),
                 (' '),
                 ('   -- Get the count of records before processing'),
                 ('   SELECT @prev_rec_count = COUNT(*)'),
                 ('     FROM dbo.'+@table_name+''),
                 (' '),
                 ('   PRINT ''   Previous Record Count = ''+CONVERT(VARCHAR(30), @prev_rec_count)'),
                 (' '),
                 ('   --Check if the table exists and drop it'),
                 ('   IF OBJECT_ID(''tempdb..#'+@table_name+''+''')'' IS NOT NULL'),
                 ('      DROP TABLE #'+@table_name+''),
                 (' '),
                 ('   -- Create temp table'),
                 ('   CREATE TABLE #'+@table_name+' (')


                 --('   OPEN TableDataCur'),
                 --('   SET @CharString = '''),
                 --(' '),
                 --('   FETCH NEXT FROM TableDataCur INTO @column_name,'),
                 --('                                     @ordinal_position,'),
                 --('                                     @column_default,'),
                 --('                                     @dt_derived,'),
                 --('                                     @is_nullable,'),
                 --('                                     @is_last_column'),
                 --('   WHILE( @@FETCH_STATUS = 0 )'),
                 --('   BEGIN'),
                 --('      SET @CharString = '      '+@column_name'),
                 --(' '),
                 --('      FETCH NEXT FROM TableDataCur INTO @column_name,'),
                 --('                                        @ordinal_position,'),
                 --('                                        @column_default,'),
                 --('                                        @dt_derived,'),
                 --('                                        @is_nullable,'),
                 --('                                        @is_last_column'),
                 --('      SET @CharString = '''),
                 --('   END'),
                 --('   CLOSE TableDataCur'),
             ) tmp (line_value)


      INSERT INTO ##generated_proc(proc_name, line_value)
      SELECT @proc_name, line_value
        FROM (
              VALUES
                 (''),
                 ('END -- End Main Block'),
                 ('GO'),
                 ('')
             ) tmp (line_value)


      FETCH NEXT FROM TableCur INTO @table_name
   END

   CLOSE TableCur
   DEALLOCATE TableCur
END -- End Main Block