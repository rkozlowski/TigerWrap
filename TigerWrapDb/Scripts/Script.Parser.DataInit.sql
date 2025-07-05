GO
IF NOT EXISTS (SELECT 1 FROM [Static].[Number])
BEGIN
	PRINT(N'Populating table [Static].[Number]. This may take a while...');
	-- https://www.sommarskog.se/Short%20Stories/table-of-numbers.html#creatingnumbers
	WITH L0 AS (SELECT 1 AS c UNION ALL SELECT 1),
     L1   AS (SELECT 1 AS c FROM L0 AS A, L0 AS B),
     L2   AS (SELECT 1 AS c FROM L1 AS A, L1 AS B),
     L3   AS (SELECT 1 AS c FROM L2 AS A, L2 AS B),
     L4   AS (SELECT 1 AS c FROM L3 AS A, L3 AS B),
     L5   AS (SELECT 1 AS c FROM L4 AS A, L4 AS B),
     Nums AS (SELECT row_number() OVER(ORDER BY c) AS n FROM L5)
	INSERT INTO [Static].[Number] ([N])
	SELECT n-1 
	FROM  Nums 
	WHERE n <= 1000001;
END
GO
IF NOT EXISTS (SELECT 1 FROM [Parser].[CharTypeMap])
BEGIN
	PRINT(N'Populating table [Parser].[CharTypeMap]...');
	INSERT INTO [Parser].[CharTypeMap]([Char], [TypeId])
	SELECT CHAR(n.[N]), [Parser].[GetCharType](CHAR(n.[N]))
	FROM [Static].[Number] n
	WHERE n.[N] BETWEEN 1 AND 127 AND [Parser].[GetCharType](CHAR(n.[N]))<>0;
END
GO
