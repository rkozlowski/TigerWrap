/*
Post-Deployment Script							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

:r .\Script.StaticDataInserts.sql
:r .\Script.LanguageOptions.sql
:r .\Script.Templates.sql

:r .\Script.Parser.StaticDataInserts.sql
:r .\Script.Parser.DataInit.sql
:r .\Script.Parser.Data.sql

:r .\Script.Version.sql
