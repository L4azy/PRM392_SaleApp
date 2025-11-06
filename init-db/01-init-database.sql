-- Wait for SQL Server to start
WAITFOR DELAY '00:00:10';
GO

-- Create database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SalesAppDB')
BEGIN
    CREATE DATABASE SalesAppDB;
END
GO

USE SalesAppDB;
GO

-- Tạo bảng User
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE Users (
        UserID INT PRIMARY KEY IDENTITY(1,1),
        Username NVARCHAR(50) NOT NULL,
        PasswordHash NVARCHAR(255) NOT NULL,
        Email NVARCHAR(100) NOT NULL,
        PhoneNumber NVARCHAR(15),
        Address NVARCHAR(255),
        Role NVARCHAR(50) NOT NULL
    );
END
GO

-- Tạo bảng Category
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Categories]') AND type in (N'U'))
BEGIN
    CREATE TABLE Categories (
        CategoryID INT PRIMARY KEY IDENTITY(1,1),
        CategoryName NVARCHAR(100) NOT NULL
    );
END
GO

-- Tạo bảng Product
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    CREATE TABLE Products (
        ProductID INT PRIMARY KEY IDENTITY(1,1),
        ProductName NVARCHAR(100) NOT NULL,
        BriefDescription NVARCHAR(255),
        FullDescription NVARCHAR(MAX),
        TechnicalSpecifications NVARCHAR(MAX),
        Price DECIMAL(18, 2) NOT NULL,
        ImageURL NVARCHAR(255),
        CategoryID INT,
        FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
    );
END
GO

-- Tạo bảng Cart
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Carts]') AND type in (N'U'))
BEGIN
    CREATE TABLE Carts (
        CartID INT PRIMARY KEY IDENTITY(1,1),
        UserID INT,
        TotalPrice DECIMAL(18, 2) NOT NULL,
        Status NVARCHAR(50) NOT NULL,
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
    );
END
GO

-- Tạo bảng CartItem
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CartItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE CartItems (
        CartItemID INT PRIMARY KEY IDENTITY(1,1),
        CartID INT,
        ProductID INT,
        Quantity INT NOT NULL,
        Price DECIMAL(18, 2) NOT NULL,
        FOREIGN KEY (CartID) REFERENCES Carts(CartID),
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
    );
END
GO

-- Tạo bảng Order
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Orders]') AND type in (N'U'))
BEGIN
    CREATE TABLE Orders (
        OrderID INT PRIMARY KEY IDENTITY(1,1),
        CartID INT,
        UserID INT,
        PaymentMethod NVARCHAR(50) NOT NULL,
        BillingAddress NVARCHAR(255) NOT NULL,
        OrderStatus NVARCHAR(50) NOT NULL,
        OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
        CartItemsSnapshot NVARCHAR(MAX),
        FOREIGN KEY (CartID) REFERENCES Carts(CartID),
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
    );
END
GO

-- Add CartItemsSnapshot column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Orders]') AND name = 'CartItemsSnapshot')
BEGIN
    ALTER TABLE Orders ADD CartItemsSnapshot NVARCHAR(MAX);
END
GO

-- Tạo bảng Payment
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Payments]') AND type in (N'U'))
BEGIN
    CREATE TABLE Payments (
        PaymentID INT PRIMARY KEY IDENTITY(1,1),
        OrderID INT,
        Amount DECIMAL(18, 2) NOT NULL,
        PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
        PaymentStatus NVARCHAR(50) NOT NULL,
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
    );
END
GO

-- Tạo bảng Notification
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Notifications]') AND type in (N'U'))
BEGIN
    CREATE TABLE Notifications (
        NotificationID INT PRIMARY KEY IDENTITY(1,1),
        UserID INT,
        Message NVARCHAR(255),
        IsRead BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
    );
END
GO

-- Tạo bảng ChatMessage
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND type in (N'U'))
BEGIN
    CREATE TABLE ChatMessages (
        ChatMessageID INT PRIMARY KEY IDENTITY(1,1),
        UserID INT,
        ReceiverID INT,
        Message NVARCHAR(MAX) NOT NULL,
        SentAt DATETIME NOT NULL DEFAULT GETDATE(),
        FromAI BIT NOT NULL DEFAULT 0,
        ForwardedToHuman BIT NOT NULL DEFAULT 0,
        FOREIGN KEY (UserID) REFERENCES Users(UserID),
        FOREIGN KEY (ReceiverID) REFERENCES Users(UserID)
    );
END
GO

-- Add missing columns to existing ChatMessages table if they don't exist
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND name = 'ReceiverID')
    BEGIN
        ALTER TABLE ChatMessages ADD ReceiverID INT;
        ALTER TABLE ChatMessages ADD FOREIGN KEY (ReceiverID) REFERENCES Users(UserID);
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND name = 'FromAI')
    BEGIN
        ALTER TABLE ChatMessages ADD FromAI BIT NOT NULL DEFAULT 0;
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ChatMessages]') AND name = 'ForwardedToHuman')
    BEGIN
        ALTER TABLE ChatMessages ADD ForwardedToHuman BIT NOT NULL DEFAULT 0;
    END
END
GO

-- Tạo bảng StoreLocation
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[StoreLocations]') AND type in (N'U'))
BEGIN
    CREATE TABLE StoreLocations (
        LocationID INT PRIMARY KEY IDENTITY(1,1),
        Latitude DECIMAL(9, 6) NOT NULL,
        Longitude DECIMAL(9, 6) NOT NULL,
        Address NVARCHAR(255) NOT NULL
    );
END
GO

PRINT 'Database initialization completed successfully!';
GO
