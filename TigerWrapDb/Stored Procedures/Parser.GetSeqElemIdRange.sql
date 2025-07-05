
CREATE PROCEDURE [Parser].[GetSeqElemIdRange]
	@rangeLen INT = 1
AS
BEGIN
	DECLARE @firstId INT;

    IF ISNULL(@rangeLen, 0) < 1
    BEGIN
        SET @rangeLen = 1;
    END

    DROP TABLE IF EXISTS #SeqElemIdRange;

    CREATE TABLE #SeqElemIdRange
    (
        [NextId] INT NOT NULL PRIMARY KEY,
    );

    INSERT INTO #SeqElemIdRange ([NextId])
    SELECT NEXT VALUE FOR [Parser].[TSqlSeqEl] OVER (ORDER BY n.[N]) [NextId]
    FROM [Static].[Number] n 
    WHERE n.[N] BETWEEN 1 AND @rangeLen    
    ORDER BY n.[N];

    SELECT @firstId = MIN([NextId])
    FROM #SeqElemIdRange;

    DROP TABLE IF EXISTS #SeqElemIdRange;

	RETURN @firstId;
END