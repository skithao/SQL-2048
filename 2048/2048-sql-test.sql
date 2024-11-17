-- 测试游戏逻辑
CREATE PROCEDURE TestGame2048
AS
BEGIN
    PRINT '开始测试...';

    -- 1. 初始化游戏并测试
    DECLARE @difficultyLevel INT = 1;
    EXEC InitGame2048 @difficultyLevel;

    -- 获取游戏ID
    DECLARE @gameId INT = (SELECT TOP 1 GameId FROM Game2048);
    PRINT '游戏ID: ' + CONVERT(VARCHAR, @gameId);

    -- 2. 测试移动
    EXEC MoveGame @gameId, 'LEFT';
    EXEC MoveGame @gameId, 'RIGHT';  -- 测试右移
    EXEC MoveGame @gameId, 'UP';     -- 测试上移
    EXEC MoveGame @gameId, 'DOWN';   -- 测试下移

    -- 3. 检查移动后分数是否增加
    DECLARE @score INT = (SELECT Score FROM Game2048 WHERE GameId = @gameId);
    IF @score > 0
    BEGIN
        PRINT '测试通过：分数增加。';
    END
    ELSE
    BEGIN
        PRINT '测试失败：分数未增加。';
    END

    -- 4. 测试保存和加载功能
    DECLARE @fileName VARCHAR(100) = 'C:\Game2048SaveData.txt';  
    EXEC SaveGame @gameId, @fileName;
    EXEC LoadGame @fileName;

    -- 5. 测试记录分数
    DECLARE @playerName VARCHAR(100) = '测试玩家';
    EXEC RecordScore @gameId, @playerName;

    -- 6. 查询并显示排行榜
    EXEC GetLeaderboard @topN = 10;

    PRINT '所有操作都已完成。';
END;
GO

-- 运行测试
EXEC TestGame2048;
