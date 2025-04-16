--At least 3 non-clustered indexes.

--IX_Review_ByRestaurant 
CREATE NONCLUSTERED INDEX IX_Review_RestaurantID
ON Review(RestaurantID);

--IX_Order_ByCustomer
CREATE NONCLUSTERED INDEX IX_Order_CustomerID
ON [Order](CustomerID);

--IX_Delivery_ByDriver
CREATE NONCLUSTERED INDEX IX_Delivery_DriverID
ON Delivery(DriverID);

--IX_Delivery_ByDriver
CREATE NONCLUSTERED INDEX IX_Order_ByStatus
ON [Order](Status);
