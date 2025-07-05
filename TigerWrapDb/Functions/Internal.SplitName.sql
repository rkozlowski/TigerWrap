CREATE FUNCTION [Internal].[SplitName]
(
	@name NVARCHAR(4000)
)
RETURNS 
@result TABLE 
(
	[ItemNumber] SMALLINT,
	[Item] NVARCHAR(4000)
)
AS
BEGIN
	DECLARE @l INT = LEN(@name);

	DECLARE @CT_START TINYINT = 0;
	DECLARE @CT_SEPARATOR TINYINT = 1;
	DECLARE @CT_DIGIT TINYINT = 2;
	DECLARE @CT_LOWER_LETTER TINYINT = 3;
	DECLARE @CT_UPPER_LETTER TINYINT = 4;

	DECLARE @IT_NONE TINYINT = 0;
	DECLARE @IT_UPPER TINYINT = 1;
	DECLARE @IT_LOWER TINYINT = 2;
	DECLARE @IT_PASCAL TINYINT = 3;
	DECLARE @IT_UPPER_DIGIT TINYINT = 4;
	
	DECLARE @item NVARCHAR(4000) = NULL;
	DECLARE @itemNo SMALLINT = 1;
	DECLARE @i INT = 0;
	DECLARE @pc CHAR(1) = NULL;
	DECLARE @c CHAR(1) = NULL;
	DECLARE @pct TINYINT = @CT_START;
	DECLARE @ct TINYINT;
	DECLARE @il INT = 0;
	DECLARE @it TINYINT = @IT_NONE;

	WHILE @i < @l
	BEGIN
		SET @i += 1;
		SET @c = SUBSTRING(@name, @i, 1);
		IF @c LIKE '[A-Z]' COLLATE Latin1_General_100_BIN2
		BEGIN
			SET @ct = @CT_UPPER_LETTER;
		END
		ELSE IF @c LIKE '[a-z]' COLLATE Latin1_General_100_BIN2
		BEGIN
			SET @ct = @CT_LOWER_LETTER;
		END
		ELSE IF @c LIKE '[0-9]'
		BEGIN
			SET @ct = @CT_DIGIT;
		END
		ELSE
		BEGIN
			SET @ct = @CT_SEPARATOR;
		END

		IF @ct = @CT_SEPARATOR
		BEGIN
			IF @il > 0
			BEGIN
				INSERT INTO @result ([ItemNumber], [Item]) VALUES (@itemNo, @item);
				SET @itemNo += 1;
				SET @item = NULL;
				SET @il = 0;
				SET @it = @IT_NONE;
			END
		END
		ELSE IF @ct = @CT_DIGIT
		BEGIN
			IF @it <> @IT_NONE
			BEGIN
				IF @it = @IT_UPPER
				BEGIN
					SET @it = @IT_UPPER_DIGIT
				END
				SET @item += @c;
				SET @il += 1;
			END
		END
		ELSE IF @ct = @CT_UPPER_LETTER
		BEGIN
			IF @it = @IT_NONE
			BEGIN
				SET @item = @c;
				SET @il = 1;
				SET @it = @IT_UPPER;
			END
			ELSE IF @it = @IT_UPPER
			BEGIN
				SET @item += @c;
				SET @il += 1;
			END
			ELSE -- @IT_LOWER, @IT_PASCAL, @IT_UPPER_DIGIT
			BEGIN
				INSERT INTO @result ([ItemNumber], [Item]) VALUES (@itemNo, @item);
				SET @itemNo += 1;
				SET @item = @c;
				SET @il = 1;
				SET @it = @IT_UPPER;
			END 
		END
		ELSE IF @ct = @CT_LOWER_LETTER
		BEGIN
			IF @it = @IT_NONE
			BEGIN
				SET @item = @c;
				SET @il = 1;
				SET @it = @IT_LOWER;
			END
			ELSE IF @it = @IT_UPPER
			BEGIN
				IF @il > 1
				BEGIN
					INSERT INTO @result ([ItemNumber], [Item]) VALUES (@itemNo, LEFT(@item, @il - 1));
					SET @itemNo += 1;
					SET @item = RIGHT(@item, 1);
					SET @il = 1;
				END
				
				SET @item += @c;
				SET @il += 1;
				SET @it = @IT_PASCAL;
			END
			ELSE IF @it = @IT_UPPER_DIGIT
			BEGIN
				INSERT INTO @result ([ItemNumber], [Item]) VALUES (@itemNo, @item);
				SET @itemNo += 1;
				SET @item = @c;
				SET @il = 1;
				SET @it = @IT_LOWER;
			END
			ELSE -- @IT_LOWER, @IT_PASCAL
			BEGIN				
				SET @item += @c;
				SET @il += 1;				
			END
		END
	END;
	IF @item IS NOT NULL
	BEGIN
		INSERT INTO @result ([ItemNumber], [Item]) VALUES (@itemNo, @item);
	END
	RETURN;
END