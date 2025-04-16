CREATE DATABASE FoodDeliverySystem;
GO
USE FoodDeliverySystem;
GO
DROP TABLE IF EXISTS Review, PaymentMethod, OrderItem, Delivery, [Order], Address, Customer, Driver, Restaurant, MenuItem, MenuCategory;
GO
-- Customer Table
CREATE TABLE Customer (
   CustomerID INT IDENTITY(1,1),
   CustomerFirstName VARCHAR(50) NOT NULL,
   CustomerLastName VARCHAR(50) NOT NULL,
   PhoneNumber VARCHAR(15) NOT NULL,
   Email VARCHAR(100) NOT NULL UNIQUE,
   Password VARCHAR(255) NOT NULL,
   CONSTRAINT PK_Customer PRIMARY KEY (CustomerID),
   CONSTRAINT chk_PhoneNumber CHECK (PhoneNumber LIKE '[0-9]%'),
   CONSTRAINT chk_EmailFormat CHECK (Email LIKE '%@%.%')
);


-- Address Table
CREATE TABLE Address (
   AddressID INT IDENTITY(1,1),
   CustomerID INT NOT NULL,
   StreetName VARCHAR(100) NOT NULL,
   StreetNumber VARCHAR(20) NOT NULL,
   City VARCHAR(50) NOT NULL,
   State VARCHAR(50) NOT NULL,
   ZipCode VARCHAR(10) NOT NULL,
   CONSTRAINT PK_Address PRIMARY KEY (AddressID),
   CONSTRAINT FK_Address_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


-- Driver Table
CREATE TABLE Driver (
   DriverID INT IDENTITY(1,1),
   DriverName VARCHAR(100) NOT NULL,
   PhoneNumber VARCHAR(15) NOT NULL,
   VehicleInfo VARCHAR(100) NOT NULL,
   CONSTRAINT PK_Driver PRIMARY KEY (DriverID),
   CONSTRAINT CHK_Driver_Phone CHECK (PhoneNumber LIKE '[0-9]%')
);


-- Restaurant Table
CREATE TABLE Restaurant (
   RestaurantID INT IDENTITY(1,1),
   Name VARCHAR(100) NOT NULL,
   Address VARCHAR(255) NOT NULL,
   Rating DECIMAL(3,2),
   CuisineType VARCHAR(50),
   CONSTRAINT PK_Restaurant PRIMARY KEY (RestaurantID)
);


-- Payment Method Table
CREATE TABLE PaymentMethod (
   PaymentID INT IDENTITY(1,1),
   CustomerID INT NOT NULL,
   CardNumber VARCHAR(16),
   ExpDate DATE,
   PaymentType VARCHAR(50),
   CONSTRAINT PK_PaymentMethod PRIMARY KEY (PaymentID),
   CONSTRAINT FK_PaymentMethod_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


-- Order Table
CREATE TABLE [Order] (
   OrderID INT IDENTITY(1,1),
   CustomerID INT NOT NULL,
   PaymentID INT NOT NULL,
   TotalAmount DECIMAL(10,2) NOT NULL,
   Status VARCHAR(50) NOT NULL,
   OrderDate DATE,
   DeliveryType VARCHAR(50),
   CONSTRAINT PK_Order PRIMARY KEY (OrderID),
   CONSTRAINT CHK_Delivery_Type CHECK (DeliveryType IN ('Standard', 'Express', 'Pickup')),
   CONSTRAINT FK_Order_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
   CONSTRAINT FK_Order_PaymentMethod FOREIGN KEY (PaymentID) REFERENCES PaymentMethod(PaymentID),
   CONSTRAINT CHK_Order_Status CHECK (Status IN ('Pending', 'Completed', 'Cancelled')),
   CONSTRAINT CHK_Total_Amount CHECK (TotalAmount > 0)
);


-- Delivery Table
CREATE TABLE Delivery (
   OrderID INT,
   DriverID INT NOT NULL,
   AddressID INT NOT NULL,
   DeliveryStatus VARCHAR(50) NOT NULL,
   PickupTime DATETIME,
   ArrivalTime DATETIME,
   CONSTRAINT PK_Delivery PRIMARY KEY (OrderID),
   CONSTRAINT FK_Delivery_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID),
   CONSTRAINT FK_Delivery_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
   CONSTRAINT FK_Delivery_Address FOREIGN KEY (AddressID) REFERENCES Address(AddressID)
);


-- MenuCategory Table
CREATE TABLE MenuCategory (
   MenuCategoryID INT IDENTITY(1,1),
   MenuCategoryName VARCHAR(100),
   CONSTRAINT PK_MenuCategory PRIMARY KEY (MenuCategoryID)
);


-- MenuItem Table
CREATE TABLE MenuItem (
   MenuItemID INT IDENTITY(1,1),
   MenuCategoryID INT,
   Name VARCHAR(100) NOT NULL,
   Description VARCHAR(255),
   Price DECIMAL(8,2) NOT NULL,
   Available BIT,
   CONSTRAINT PK_MenuItem PRIMARY KEY (MenuItemID),
   CONSTRAINT FK_MenuItem_MenuCategory FOREIGN KEY (MenuCategoryID) REFERENCES MenuCategory(MenuCategoryID)
);


-- OrderItem Table
CREATE TABLE OrderItem (
   OrderItemID INT IDENTITY(1,1),
   RestaurantID INT NOT NULL,
   OrderID INT NOT NULL,
   MenuItemID INT NOT NULL,
   Quantity INT NOT NULL,
   UnitPrice DECIMAL(10,2) NOT NULL,
   Notes VARCHAR(255),
   CONSTRAINT PK_OrderItem PRIMARY KEY (OrderItemID),
   CONSTRAINT FK_OrderItem_Restaurant FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID),
   CONSTRAINT FK_OrderItem_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID),
   CONSTRAINT FK_OrderItem_MenuItem FOREIGN KEY (MenuItemID) REFERENCES MenuItem(MenuItemID)
);


-- Review Table
CREATE TABLE Review (
   ReviewID INT IDENTITY(1,1),
   RestaurantID INT NOT NULL,
   CustomerID INT NOT NULL,
   Rating INT NOT NULL,
   Comment VARCHAR(255),
   ReviewDate DATE NOT NULL,
   CONSTRAINT PK_Review PRIMARY KEY (ReviewID),
   CONSTRAINT FK_Review_Restaurant FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID),
   CONSTRAINT FK_Review_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
   CONSTRAINT CHK_Review_Rating CHECK (Rating BETWEEN 1 AND 5)
);
