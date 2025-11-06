USE SalesAppDB;
GO

-- Add ReceiverID column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND name = 'ReceiverID')
BEGIN
    ALTER TABLE ChatMessages ADD ReceiverID INT;
    ALTER TABLE ChatMessages ADD FOREIGN KEY (ReceiverID) REFERENCES Users(UserID);
END
GO

-- Add FromAI column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND name = 'FromAI')
BEGIN
    ALTER TABLE ChatMessages ADD FromAI BIT NOT NULL DEFAULT 0;
END
GO

-- Add ForwardedToHuman column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND name = 'ForwardedToHuman')
BEGIN
    ALTER TABLE ChatMessages ADD ForwardedToHuman BIT NOT NULL DEFAULT 0;
END
GO

SELECT 'ChatMessages table updated successfully' AS Result;
GO
