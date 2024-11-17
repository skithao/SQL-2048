-- 创建数据库
CREATE DATABASE Game2048DB;
GO

-- 使用数据库
USE Game2048DB;
GO

-- 数据库表设计
CREATE TABLE Game2048 (
    RowID INT,
    ColID INT,
    Value INT
);
GO

-- 初始化游戏
-- 插入初始空格子
INSERT INTO Game2048 (RowID, ColID, Value) VALUES
(0, 0, 0), (0, 1, 0), (0, 2, 0), (0, 3, 0),
(1, 0, 0), (1, 1, 0), (1, 2, 0), (1, 3, 0),
(2, 0, 0), (2, 1, 0), (2, 2, 0), (2, 3, 0),
(3, 0, 0), (3, 1, 0), (3, 2, 0), (3, 3, 0);

-- 随机插入两个数字 2 或 4
DECLARE @row1 INT, @col1 INT, @val1 INT;
DECLARE @row2 INT, @col2 INT, @val2 INT;

DECLARE @validInsertion BIT;

SET @validInsertion = 0;

-- 插入第一个数字
WHILE @validInsertion = 0
BEGIN
    SET @row1 = ROUND(RAND() * 3, 0);
    SET @col1 = ROUND(RAND() * 3, 0);
    IF NOT EXISTS (SELECT 1 FROM Game2048 WHERE RowID = @row1 AND ColID = @col1)
    BEGIN
        SET @val1 = CASE WHEN RAND() < 0.5 THEN 2 ELSE 4 END;
        INSERT INTO Game2048 (RowID, ColID, Value) VALUES (@row1, @col1, @val1);
        SET @validInsertion = 1;
    END
END

SET @validInsertion = 0;

-- 插入第二个数字
WHILE @validInsertion = 0
BEGIN
    SET @row2 = ROUND(RAND() * 3, 0);
    SET @col2 = ROUND(RAND() * 3, 0);
    IF NOT EXISTS (SELECT 1 FROM Game2048 WHERE RowID = @row2 AND ColID = @col2 AND (RowID != @row1 OR ColID != @col1))
    BEGIN
        SET @val2 = CASE WHEN RAND() < 0.5 THEN 2 ELSE 4 END;
        INSERT INTO Game2048 (RowID, ColID, Value) VALUES (@row2, @col2, @val2);
        SET @validInsertion = 1;
    END
END
GO

-- 重构通用合并逻辑
CREATE PROCEDURE MoveDirection(@isHorizontal BIT)
AS
BEGIN
    DECLARE @i INT, @j INT, @index INT, @value INT;
    DECLARE @newValues TABLE (IndexID INT, Value INT);

    SET @i = 0;
    WHILE @i < 4
    BEGIN
        SET @j = IIF(@isHorizontal = 1, 0, 3);
        SET @index = IIF(@isHorizontal = 1, 1, -1); -- 左右移动或上下移动

        -- 收集非零值
        WHILE (@isHorizontal = 1 AND @j < 4) OR (@isHorizontal = 0 AND @j >= 0)
        BEGIN
            SELECT @value = Value FROM Game2048 WHERE RowID = @i AND ColID = @j;
            IF @value > 0
            BEGIN
                INSERT INTO @newValues (IndexID, Value) VALUES (@j, @value);
            END
            SET @j = @j + @index;
        END

        -- 合并值
        SET @j = 0;
        WHILE @j < (SELECT COUNT(*) FROM @newValues)
        BEGIN
            DECLARE @nextIndex INT;
            SELECT @value = Value FROM @newValues WHERE IndexID = @j;

            SET @nextIndex = @j + 1;
            IF @nextIndex < (SELECT COUNT(*) FROM @newValues)
            BEGIN
                IF @value = (SELECT Value FROM @newValues WHERE IndexID = @nextIndex)
                BEGIN
                    UPDATE Game2048 SET Value = @value * 2 WHERE RowID = @i AND ColID = (IIF(@isHorizontal = 1, @j, @i));
                    DELETE FROM Game2048 WHERE RowID = @i AND ColID = (IIF(@isHorizontal = 1, @nextIndex, @i));
                    SET @j = @j + 1; -- 跳过已合并的值
                END
            END
            SET @j = @j + 1;
        END

        -- 填充空位
        SET @j = IIF(@isHorizontal = 1, 0, 3);
        WHILE (@isHorizontal = 1 AND @j < 4) OR (@isHorizontal = 0 AND @j >= 0)
        BEGIN
            IF (SELECT Value FROM Game2048 WHERE RowID = @i AND ColID = @j) = 0
            BEGIN
                DECLARE @k INT = @j + @index;
                WHILE (@isHorizontal = 1 AND @k < 4) OR (@isHorizontal = 0 AND @k >= 0)
                BEGIN
                    IF (SELECT Value FROM Game2048 WHERE RowID = @i AND ColID = @k) > 0
                    BEGIN
                        UPDATE Game2048 SET Value = (SELECT Value FROM Game2048 WHERE RowID = @i AND ColID = @k) WHERE RowID = @i AND ColID = @j;
                        UPDATE Game2048 SET Value = 0 WHERE RowID = @i AND ColID = @k;
                        BREAK;
                    END
                    SET @k = @k + @index;
                END
            END
            SET @j = @j + @index;
        END

        SET @i = @i + 1;
    END
END;
GO

-- 向左移动的逻辑
CREATE PROCEDURE MoveLeft
AS
BEGIN
    EXEC MoveDirection 1; -- 1表示水平移动
END;
GO

-- 向上移动的逻辑
CREATE PROCEDURE MoveUp
AS
BEGIN
    EXEC MoveDirection 0; -- 0表示垂直移动
END;
GO

-- 向下移动的逻辑
CREATE PROCEDURE MoveDown
AS
BEGIN
    EXEC MoveDirection 0; -- 0表示垂直移动
END;
GO

-- 向右移动的逻辑
CREATE PROCEDURE MoveRight
AS
BEGIN
    EXEC MoveDirection 1; -- 1表示水平移动
END;
GO

-- 插入新数字
DECLARE @emptyRow INT, @emptyCol INT;
SELECT TOP 1 @emptyRow = RowID, @emptyCol = ColID FROM Game2048 WHERE Value = 0 ORDER BY NEWID();

IF @emptyRow IS NOT NULL
BEGIN
    UPDATE Game2048 SET Value = CASE WHEN RAND() < 0.5 THEN 2 ELSE 4 END WHERE RowID = @emptyRow AND ColID = @emptyCol;
END
GO

-- 检查游戏状态
SELECT CASE 
        WHEN EXISTS (SELECT 1 FROM Game2048 WHERE Value = 0) OR 
        (EXISTS (SELECT 1 FROM Game2048 AS a JOIN Game2048 AS b ON a.RowID = b.RowID AND a.ColID + 1 = b.ColID AND a.Value = b.Value) OR
         EXISTS (SELECT 1 FROM Game2048 AS a JOIN Game2048 AS b ON a.RowID + 1 = b.RowID AND a.ColID = b.ColID AND a.Value = b.Value)) 
        THEN 0 ELSE 1 END AS GameOver;
GO
