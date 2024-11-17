-- 完整的2048游戏逻辑
CREATE PROCEDURE MoveGame @gameId INT, @direction VARCHAR(10)
AS
BEGIN
    BEGIN TRY
        DECLARE @gridData VARCHAR(MAX);
        SET @gridData = (SELECT GridData FROM Game2048 WHERE GameId = @gameId);
        
        IF @gridData IS NULL
        BEGIN
            PRINT '游戏未找到！';
            RETURN;
        END
        
        DECLARE @newRows TABLE (RowData VARCHAR(100));
        DECLARE @newRowData VARCHAR(100);
        DECLARE @canChange BIT = 0;

        -- 将网格数据插入临时表
        DECLARE @i INT = 0;
        WHILE @i < 4
        BEGIN
            INSERT INTO @newRows (RowData)
            VALUES (PARSENAME(REPLACE(@gridData, ';', '.'), 4 - @i));
            SET @i = @i + 1;
        END

        -- 移动逻辑
        IF @direction IN ('LEFT', 'RIGHT')
        BEGIN
            SET @i = 0; 
            WHILE @i < 4
            BEGIN
                SET @newRowData = '';
                DECLARE @rowData VARCHAR(100);
                SELECT @rowData = (SELECT RowData FROM @newRows WHERE ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 = @i);

                -- 向左或右移动
                DECLARE @prevNum INT = NULL;
                DECLARE @nums TABLE (Num INT);
                INSERT INTO @nums (Num)
                SELECT CASE WHEN value = '0' THEN NULL ELSE CAST(value AS INT) END 
                FROM STRING_SPLIT(@rowData, ',') WHERE value <> '0';

                IF @direction = 'LEFT'
                BEGIN
                    DECLARE cur CURSOR FOR SELECT Num FROM @nums;
                    OPEN cur;
                    FETCH NEXT FROM cur INTO @newValue;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @prevNum IS NULL OR @prevNum <> @newValue
                        BEGIN
                            SET @newRowData = @newRowData + CONVERT(VARCHAR, @newValue) + ',';
                            SET @prevNum = @newValue;
                        END
                        ELSE
                        BEGIN
                            SET @newRowData = LEFT(@newRowData, LEN(@newRowData) - 1) + CONVERT(VARCHAR, @newValue * 2) + ',';
                            SET @canChange = 1; 
                            UPDATE Game2048 SET Score = Score + @newValue * 2 WHERE GameId = @gameId;
                            SET @prevNum = NULL;
                        END
                        FETCH NEXT FROM cur INTO @newValue;
                    END
                    CLOSE cur;
                    DEALLOCATE cur;
                END
                ELSE IF @direction = 'RIGHT'
                BEGIN
                    DECLARE cur CURSOR FOR SELECT Num FROM @nums ORDER BY Num DESC;
                    OPEN cur;
                    FETCH NEXT FROM cur INTO @newValue;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @prevNum IS NULL OR @prevNum <> @newValue
                        BEGIN
                            SET @newRowData = CONVERT(VARCHAR, @newValue) + ',' + @newRowData;
                            SET @prevNum = @newValue;
                        END
                        ELSE
                        BEGIN
                            SET @newRowData = CONVERT(VARCHAR, @newValue * 2) + ',' + LEFT(@newRowData, LEN(@newRowData) - 1);
                            SET @canChange = 1; 
                            UPDATE Game2048 SET Score = Score + @newValue * 2 WHERE GameId = @gameId;
                            SET @prevNum = NULL;
                        END
                        FETCH NEXT FROM cur INTO @newValue;
                    END
                    CLOSE cur;
                    DEALLOCATE cur;
                END

                SET @newRowData = @newRowData + REPLICATE('0,', 4 - LEN(@newRowData) / LEN(@newRowData));
                INSERT INTO @newRows (RowData) VALUES (@newRowData);
                SET @i = @i + 1;
            END
        END

        -- 上下移动逻辑
        IF @direction IN ('UP', 'DOWN')
        BEGIN
            SET @i = 0; 
            WHILE @i < 4
            BEGIN
                SET @newRowData = '';
                DECLARE @columnData VARCHAR(100);
                SELECT @columnData = (SELECT STRING_AGG(value, ',') FROM (
                    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS r, 
                           value
                    FROM STRING_SPLIT(@gridData, ';') CROSS APPLY STRING_SPLIT(value, ',') 
                    WHERE RENAMED.r = @i
                ) AS tbl WHERE value IS NOT NULL);

                DECLARE @prevNum INT = NULL;
                DECLARE @nums TABLE (Num INT);
                INSERT INTO @nums (Num)
                SELECT CASE WHEN value = '0' THEN NULL ELSE CAST(value AS INT) END 
                FROM STRING_SPLIT(@columnData, ',') WHERE value <> '0';

                IF @direction = 'UP'
                BEGIN
                    DECLARE cur CURSOR FOR SELECT Num FROM @nums;
                    OPEN cur;
                    FETCH NEXT FROM cur INTO @newValue;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @prevNum IS NULL OR @prevNum <> @newValue
                        BEGIN
                            SET @newRowData = @newRowData + CONVERT(VARCHAR, @newValue) + ',';
                            SET @prevNum = @newValue;
                        END
                        ELSE
                        BEGIN
                            SET @newRowData = LEFT(@newRowData, LEN(@newRowData) - 1) + CONVERT(VARCHAR, @newValue * 2) + ',';
                            SET @canChange = 1; 
                            UPDATE Game2048 SET Score = Score + @newValue * 2 WHERE GameId = @gameId;
                            SET @prevNum = NULL;
                        END
                        FETCH NEXT FROM cur INTO @newValue;
                    END
                    CLOSE cur;
                    DEALLOCATE cur;
                END
                ELSE IF @direction = 'DOWN'
                BEGIN
                    DECLARE cur CURSOR FOR SELECT Num FROM @nums ORDER BY Num DESC;
                    OPEN cur;
                    FETCH NEXT FROM cur INTO @newValue;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF @prevNum IS NULL OR @prevNum <> @newValue
                        BEGIN
                            SET @newRowData = CONVERT(VARCHAR, @newValue) + ',' + @newRowData;
                            SET @prevNum = @newValue;
                        END
                        ELSE
                        BEGIN
                            SET @newRowData = CONVERT(VARCHAR, @newValue * 2) + ',' + LEFT(@newRowData, LEN(@newRowData) - 1);
                            SET @canChange = 1; 
                            UPDATE Game2048 SET Score = Score + @newValue * 2 WHERE GameId = @gameId;
                            SET @prevNum = NULL;
                        END
                        FETCH NEXT FROM cur INTO @newValue;
                    END
                    CLOSE cur;
                    DEALLOCATE cur;
                END

                SET @newRowData = @newRowData + REPLICATE('0,', 4 - LEN(@newRowData) / LEN(@newRowData));
                INSERT INTO @newRows (RowData) VALUES (@newRowData);
                SET @i = @i + 1;
            END
        END

        -- 更新网格数据
        SET @gridData = '';
        SELECT @gridData = @gridData + RowData + ';' FROM @newRows;
        SET @gridData = LEFT(@gridData, LEN(@gridData) - 1);
        UPDATE Game2048 SET GridData = @gridData, StepCount = StepCount + 1, LastMoveDirection = @direction WHERE GameId = @gameId;

        -- 添加新数字逻辑
        DECLARE @emptyCells TABLE (RowIndex INT, ColIndex INT);
        INSERT INTO @emptyCells (RowIndex, ColIndex)
        SELECT r, c FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS r, 
                   ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS c,
                   value
            FROM STRING_SPLIT(@gridData, ';') CROSS APPLY STRING_SPLIT(value, ',')
        ) AS tbl 
        WHERE value = '0';

        -- 随机选择空白格添加新数字
        IF EXISTS (SELECT * FROM @emptyCells)
        BEGIN
            DECLARE @randomPos INT = FLOOR(RAND() * (SELECT COUNT(*) FROM @emptyCells)) + 1;
            DECLARE @selectedCell ROWTYPE;
            SET @selectedCell = (SELECT TOP 1 * FROM @emptyCells ORDER BY NEWID() OFFSET @randomPos - 1 ROWS FETCH NEXT 1 ROWS ONLY);
            DECLARE @newValue INT = CASE WHEN FLOOR(RAND() * 2) = 0 THEN 2 ELSE 4 END;

            -- 更新网格：
            SET @gridData = STUFF(@gridData, (@selectedCell.RowIndex * 4 + @selectedCell.ColIndex + 1) * 2 - 1, 2, CONVERT(VARCHAR(1), @newValue));
        END

        -- 更新网格数据
        UPDATE Game2048 SET GridData = @gridData WHERE GameId = @gameId;

        -- 胜利条件检查
        IF CHARINDEX('2048', @gridData) > 0
        BEGIN
            UPDATE Game2048 SET IsOver = 1 WHERE GameId = @gameId;
            PRINT '恭喜！您赢得了游戏！';
        END

        -- 检查游戏状态
        IF NOT EXISTS (SELECT 1 FROM STRING_SPLIT(@gridData, ';') CROSS APPLY STRING_SPLIT(value, ',') WHERE value = '0')
        BEGIN
            DECLARE @canMerge BIT = 0;
            SELECT @canMerge = 1 FROM (
                SELECT r, c, value,
                       LAG(value, 1, NULL) OVER (PARTITION BY r ORDER BY c) prevValue,
                       LEAD(value, 1, NULL) OVER (PARTITION BY r ORDER BY c) nextValue
                FROM (
                    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) r, value c, value
                    FROM STRING_SPLIT(@gridData, ';')
                    CROSS APPLY STRING_SPLIT(value, ',')
                ) x
            ) y
            WHERE (prevValue = value OR nextValue = value) AND r IS NOT NULL AND c IS NOT NULL;

            IF @canMerge = 0
            BEGIN
                UPDATE Game2048 SET IsOver = 1 WHERE GameId = @gameId;
                PRINT '游戏结束！没有更多可用的移动。';
            END
        END

    END TRY
    BEGIN CATCH
        PRINT '移动过程中发生错误: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
