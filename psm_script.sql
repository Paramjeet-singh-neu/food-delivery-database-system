----------------------------------------------------------At least 3 stored procedures with input and output parameters.
--Create a New Order and Return the OrderID
CREATE PROCEDURE CreateOrder
   @CustomerID INT,
   @PaymentID INT,
   @TotalAmount DECIMAL(10,2),
   @Status VARCHAR(50),
   @OrderDate DATE,
   @DeliveryType VARCHAR(50),
   @NewOrderID INT OUTPUT
AS
BEGIN
   IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
   BEGIN
       RAISERROR ('Invalid CustomerID: Customer does not exist.', 16, 1);
       RETURN;
   END  
   IF NOT EXISTS (SELECT 1 FROM PaymentMethod WHERE PaymentID = @PaymentID AND CustomerID = @CustomerID)
   BEGIN
       RAISERROR ('Invalid PaymentID: Payment method does not belong to this customer.', 16, 1);
       RETURN;
   END

   INSERT INTO [Order] (CustomerID, PaymentID, TotalAmount, Status, OrderDate, DeliveryType)
   VALUES (@CustomerID, @PaymentID, @TotalAmount, @Status, @OrderDate, @DeliveryType);

   SET @NewOrderID = SCOPE_IDENTITY();
END;
--UpdateOrderStatus
CREATE PROCEDURE UpdateOrderStatus
   	@OrderID INT,
   	@NewStatus VARCHAR(50),
   	@Success BIT OUTPUT
AS
BEGIN
   	SET @Success = 0;
   	IF NOT EXISTS (SELECT 1 FROM [Order] WHERE OrderID = @OrderID)
   	BEGIN
       	RETURN;
   	END
   	IF @NewStatus NOT IN ('Pending', 'Completed', 'Cancelled')
   	BEGIN
       	RETURN;
   	END
   	UPDATE [Order]
   	SET Status = @NewStatus
  	WHERE OrderID = @OrderID;
   	SET @Success = 1;
END;
--GetCustomerTotalSpent 
CREATE PROCEDURE GetCustomerTotalSpent
   @CustomerID INT,
   @TotalAmountSpent DECIMAL(10,2) OUTPUT
AS
BEGIN
   SELECT @TotalAmountSpent = ISNULL(SUM(TotalAmount), 0)
   FROM [Order]
   WHERE CustomerID = @CustomerID;
END;
----------------------insert Order and OrderItem simultaneously 
CREATE PROCEDURE CreateOrderWithItems
    @CustomerID INT,
    @PaymentID INT,
    @TotalAmount DECIMAL(10,2),
    @Status VARCHAR(50),
    @OrderDate DATE,
    @DeliveryType VARCHAR(50),
    @OrderID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Insert into [Order]
        INSERT INTO [Order] (CustomerID, PaymentID, TotalAmount, Status, OrderDate, DeliveryType)
        VALUES (@CustomerID, @PaymentID, @TotalAmount, @Status, @OrderDate, @DeliveryType);

        SET @OrderID = SCOPE_IDENTITY(); -- Get new OrderID

        -- Step 2: insert multipel OrderItem
        INSERT INTO OrderItem (RestaurantID, OrderID, MenuItemID, Quantity, UnitPrice)
        VALUES 
            (1, @OrderID, 3, 2, 5.99),
            (2, @OrderID, 5, 1, 9.99);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- cast error message
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Transaction failed: %s', 16, 1, @ErrMsg);
    END CATCH
END;
--------------------Cancel Order 
CREATE PROCEDURE CancelOrder
    @OrderID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Make sure the Order is existed or not
        IF NOT EXISTS (SELECT 1 FROM [Order] WHERE OrderID = @OrderID)
        BEGIN
            RAISERROR('Order with ID %d does not exist.', 16, 1, @OrderID);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Step 2: Update Order status 
        UPDATE [Order]
        SET Status = 'Cancelled'
        WHERE OrderID = @OrderID;

        -- Step 3: delete Deliver
        DELETE FROM Delivery
        WHERE OrderID = @OrderID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Order cancelation failed %s', 16, 1, @ErrMsg);
    END CATCH
END;
--------------------Ｕpdate Review
CREATE PROCEDURE UpdateReview
    @ReviewID INT,
    @NewRating INT,
    @NewComment VARCHAR(255)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check if this Review is existed or not
        IF NOT EXISTS (SELECT 1 FROM Review WHERE ReviewID = @ReviewID)
        BEGIN
            RAISERROR('Review with ID %d does not exist.', 16, 1, @ReviewID);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the Rating is legal(1~5)
        IF @NewRating < 1 OR @NewRating > 5
        BEGIN
            RAISERROR('Rating must be between 1 and 5.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update
        UPDATE Review
        SET 
            Rating = @NewRating,
            Comment = @NewComment,
            ReviewDate = GETDATE()
        WHERE ReviewID = @ReviewID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Review Updating failed：%s', 16, 1, @ErrMsg);
    END CATCH
END;

----------------------------------------------------------At least 3 views, often used for reporting purposes.
CREATE OR ALTER VIEW CustomerOrderHistory AS
SELECT
  c.CustomerID,
  c.CustomerFirstName + ' ' + c.CustomerLastName AS FullName,
  o.OrderID,
  o.OrderDate,
  o.Total_Amount,
  o.Status
FROM [Order] o
JOIN Customer c ON o.CustomerID = c.CustomerID;
GO
-- View 2: Restaurant Performance
CREATE OR ALTER VIEW RestaurantPerformance AS
SELECT
   r.RestaurantID,
   r.Name AS RestaurantName,
   r.CuisineType,
   COUNT(DISTINCT o.OrderID) AS TotalOrders,
   SUM(o.Total_Amount) AS TotalRevenue,
   AVG(r2.Rating) AS AverageRating,
   COUNT(DISTINCT r2.ReviewID) AS ReviewCount
FROM Restaurant r
LEFT JOIN OrderItem oi ON r.RestaurantID = oi.RestaurantID
LEFT JOIN [Order] o ON oi.OrderID = o.OrderID
LEFT JOIN Review r2 ON r.RestaurantID = r2.RestaurantID
GROUP BY r.RestaurantID, r.Name, r.CuisineType;
GO
-- View 3: Delivery Analytics
CREATE OR ALTER VIEW DeliveryAnalytics AS
SELECT
   d.DriverID,
   dr.DriverName,
   COUNT(d.OrderID) AS TotalDeliveries,
   AVG(DATEDIFF(MINUTE, d.PickupTime, d.ArrivalTime)) AS AvgDeliveryTimeMinutes,
   SUM(CASE WHEN d.DeliveryStatus = 'Completed' THEN 1 ELSE 0 END) AS CompletedDeliveries,
   SUM(CASE WHEN d.DeliveryStatus = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledDeliveries,
   SUM(o.Total_Amount) AS TotalDeliveryRevenue
FROM Delivery d
JOIN Driver dr ON d.DriverID = dr.DriverID
JOIN [Order] o ON d.OrderID = o.OrderID
GROUP BY d.DriverID, dr.DriverName;
GO

----------------------------------------------------------At least 3 user-defined functions
CREATE FUNCTION GetTotalOrders(@CustomerID INT) 
RETURNS INT 
AS 
BEGIN 
   DECLARE @TotalOrders INT; 
   SELECT @TotalOrders = COUNT(*) FROM [Order] WHERE CustomerID = @CustomerID; 
   RETURN @TotalOrders; 
END; 


CREATE FUNCTION GetAverageRating(@RestaurantID INT) 
RETURNS DECIMAL(3,2) 
AS 
BEGIN 
   DECLARE @AvgRating DECIMAL(3,2); 
   SELECT @AvgRating = AVG(CAST(Rating AS DECIMAL(3,2))) FROM Review 
   WHERE RestaurantID = @RestaurantID; 
   RETURN ISNULL(@AvgRating, 0); 
END;

CREATE FUNCTION GetOrderTotalAmount() 
RETURNS TABLE 
AS 
RETURN 
( 
   SELECT o.OrderID, SUM(oi.Quantity * oi.UnitPrice) AS TotalAmount 
   FROM [Order] o 
   JOIN OrderItem oi ON o.OrderID = oi.OrderID 
   GROUP BY o.OrderID 
);

----------------------------------------------------------At least 1 DML Trigger
--This trigger logs the order status changes into an audit table.
CREATE TABLE OrderAuditLog (
   AuditID INT IDENTITY(1,1) PRIMARY KEY,
   OrderID INT,
   OldStatus VARCHAR(50),
   NewStatus VARCHAR(50),
   ChangedAt DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_LogOrderStatusUpdate
ON [Order]
AFTER UPDATE
AS
BEGIN
   IF UPDATE(Status)
   BEGIN
       INSERT INTO OrderAuditLog (OrderID, OldStatus, NewStatus)
       SELECT
           i.OrderID,
           d.Status AS OldStatus,
           i.Status AS NewStatus
       FROM inserted i
       JOIN deleted d ON i.OrderID = d.OrderID
       WHERE i.Status <> d.Status;
   END
END;
or
This trigger blocks changing a status from 'Completed' to any other.
CREATE TRIGGER trg_PreventInvalidStatusChange
ON [Order]
INSTEAD OF UPDATE
AS
BEGIN
   IF EXISTS (
       SELECT 1
       FROM inserted i
       JOIN deleted d ON i.OrderID = d.OrderID
       WHERE d.Status = 'Completed' AND i.Status <> 'Completed'
   )
   BEGIN
       RAISERROR('Cannot change status from Completed to another status.', 16, 1);
       ROLLBACK;
   END
   ELSE
   BEGIN
       UPDATE o
       SET
           o.TotalAmount = i.TotalAmount,
           o.Status = i.Status,
           o.OrderDate = i.OrderDate,
           o.DeliveryType = i.DeliveryType,
           o.CustomerID = i.CustomerID,
           o.PaymentID = i.PaymentID
       FROM [Order] o
       JOIN inserted i ON o.OrderID = i.OrderID;
   END
END;
