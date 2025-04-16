IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
   CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'C0mpl3x_M@ster_Encryption_Key_DAMG2025!';
END
GO


IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'FoodDeliveryCertificate')
BEGIN
   CREATE CERTIFICATE FoodDeliveryCertificate
   WITH SUBJECT = 'Food Delivery System Encryption Certificate',
   EXPIRY_DATE = '20340630';
END
GO


IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'FoodDeliverySymmetricKey')
BEGIN
   CREATE SYMMETRIC KEY FoodDeliverySymmetricKey
   WITH ALGORITHM = AES_256
   ENCRYPTION BY CERTIFICATE FoodDeliveryCertificate;
END
GO


ALTER TABLE Customer
ADD EncryptedPhoneNumber VARBINARY(MAX),
   EncryptedEmail VARBINARY(MAX);
GO


ALTER TABLE PaymentMethod
ADD EncryptedCardNumber VARBINARY(MAX),
   EncryptedExpDate VARBINARY(MAX);
GO


OPEN SYMMETRIC KEY FoodDeliverySymmetricKey
DECRYPTION BY CERTIFICATE FoodDeliveryCertificate;


UPDATE Customer
SET EncryptedPhoneNumber = EncryptByKey(Key_GUID('FoodDeliverySymmetricKey'), PhoneNumber),
   EncryptedEmail = EncryptByKey(Key_GUID('FoodDeliverySymmetricKey'), Email);


UPDATE PaymentMethod
SET EncryptedCardNumber = EncryptByKey(Key_GUID('FoodDeliverySymmetricKey'), CardNumber),
   EncryptedExpDate = EncryptByKey(Key_GUID('FoodDeliverySymmetricKey'), CONVERT(VARCHAR(10), ExpDate, 120));


CLOSE SYMMETRIC KEY FoodDeliverySymmetricKey;
GO


CREATE OR ALTER VIEW EncryptedCustomerView
AS
SELECT
   CustomerID,
   CustomerFirstName,
   CustomerLastName,
   EncryptedPhoneNumber,
   EncryptedEmail,
   Password
FROM Customer;
GO


CREATE OR ALTER VIEW EncryptedPaymentMethodView
AS
SELECT
   PaymentID,
   CustomerID,
   EncryptedCardNumber,
   EncryptedExpDate,
   PaymentType
FROM PaymentMethod;
GO


CREATE OR ALTER PROCEDURE DecryptCustomerData
   @CustomerID INT
AS
BEGIN
   OPEN SYMMETRIC KEY FoodDeliverySymmetricKey
   DECRYPTION BY CERTIFICATE FoodDeliveryCertificate;


   SELECT
       CustomerID,
       CustomerFirstName,
       CustomerLastName,
       CONVERT(VARCHAR(15), DecryptByKey(EncryptedPhoneNumber)) AS DecryptedPhoneNumber,
       CONVERT(VARCHAR(100), DecryptByKey(EncryptedEmail)) AS DecryptedEmail
   FROM EncryptedCustomerView
   WHERE CustomerID = @CustomerID;


   CLOSE SYMMETRIC KEY FoodDeliverySymmetricKey;
END

GO
CREATE OR ALTER PROCEDURE DecryptPaymentMethodData
   @PaymentID INT
AS
BEGIN
   OPEN SYMMETRIC KEY FoodDeliverySymmetricKey
   DECRYPTION BY CERTIFICATE FoodDeliveryCertificate;


   SELECT
       PaymentID,
       CustomerID,
       CONVERT(VARCHAR(16), DecryptByKey(EncryptedCardNumber)) AS DecryptedCardNumber,
       CONVERT(DATE, CAST(DecryptByKey(EncryptedExpDate) AS VARCHAR(10))) AS DecryptedExpDate,
       PaymentType
   FROM EncryptedPaymentMethodView
   WHERE PaymentID = @PaymentID;


   CLOSE SYMMETRIC KEY FoodDeliverySymmetricKey;
END
GO
	
SELECT * FROM EncryptedCustomerView;
SELECT * FROM EncryptedPaymentMethodView;

-- Decrypt specific row


EXEC DecryptCustomerData @CustomerID = 4;


EXEC DecryptPaymentMethodData @PaymentID = 1;
