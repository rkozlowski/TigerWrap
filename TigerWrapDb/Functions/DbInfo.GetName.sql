﻿


CREATE FUNCTION [DbInfo].[GetName]
(	
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @name VARCHAR(50) = 'TigerWrapDb';	

	RETURN @name;
END