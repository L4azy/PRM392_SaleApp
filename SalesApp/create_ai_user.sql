-- Create AI Assistant User for Chat System
-- This user will be used as the AI chatbot in the chat system
-- UserID must be 23 to match the AI_USER_ID constant in ChatMessageService.java

-- First, enable IDENTITY_INSERT to allow manual ID insertion
SET IDENTITY_INSERT [dbo].[Users] ON;
GO

-- Insert AI User with ID = 23
INSERT INTO [dbo].[Users] (
    [UserID],
    [Username],
    [PasswordHash],
    [Email],
    [PhoneNumber],
    [Address],
    [Role]
)
VALUES (
    23,                                                          -- UserID (must be 23)
    'Skibdi AI Assistant',                                      -- Username
    '$2a$10$1u1atWn1nXM/dvb/2/9LeJjNKTPZZos80Jdy',            -- PasswordHash (dummy - AI doesn't login)
    'ai-assistant@skibdi.com',                                  -- Email
    'N/A',                                                       -- PhoneNumber
    'Cloud Server',                                              -- Address
    'AI'                                                         -- Role (matches RoleEnum.AI)
);
GO

-- Disable IDENTITY_INSERT after insertion
SET IDENTITY_INSERT [dbo].[Users] OFF;
GO

-- Verify the AI user was created
SELECT * FROM [dbo].[Users] WHERE [UserID] = 23;
GO
