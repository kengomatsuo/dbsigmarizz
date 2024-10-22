DELIMITER $$

CREATE FUNCTION CAP_FIRST(input VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE len INT;
  DECLARE i INT;
  DECLARE result VARCHAR(255);
  DECLARE `char` CHAR(1);

  SET len = CHAR_LENGTH(input);
  SET input = LOWER(input);
  SET result = '';
  SET i = 1;

  WHILE (i <= len) DO
    SET `char` = MID(input, i, 1);
    
    IF (i = 1 OR MID(input, i - 1, 1) = ' ') THEN
      IF (`char` REGEXP '[a-zA-Z]') THEN
        SET `char` = UPPER(`char`);
      END IF;
    END IF;

    IF (MID(input, i - 1, 1) = '.' AND `char` REGEXP '[a-zA-Z]') THEN
      SET `char` = UPPER(`char`);
    END IF;

    SET result = CONCAT(result, `char`);
    SET i = i + 1;
  END WHILE;

  RETURN result;
END $$

CREATE PROCEDURE addAuthor (
  IN AuthorName VARCHAR(50),
  IN AuthorBirthdate DATE
) 
BEGIN 
  START TRANSACTION;

  IF AuthorName IS NULL OR AuthorName = '' THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Name must not be null'; 

  ELSEIF AuthorBirthdate < '1900-01-01' OR AuthorBirthdate > CURDATE() THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid birthdate'; 
  
  ELSEIF EXISTS (
    SELECT 1
    FROM Author
    WHERE Name = AuthorName
      AND Birthdate = AuthorBirthdate
  ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '15002' SET MESSAGE_TEXT = 'Failed: Author already exists';
  END IF;

  INSERT INTO Author (Name, Birthdate)
    VALUES (CAP_FIRST(AuthorName), AuthorBirthdate);

  SELECT *
  FROM Author
  WHERE Name = AuthorName
    AND Birthdate = AuthorBirthdate;
  COMMIT;
END $$

CREATE PROCEDURE addUser (
  IN UserUsername VARCHAR(100),
  IN UserFullName VARCHAR(50),
  IN UserAddress VARCHAR(200),
  IN UserPassword VARCHAR(32)
) 
BEGIN 
  START TRANSACTION;

  IF UserUsername IS NULL OR UserUsername = '' THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username must not be null'; 

  ELSEIF LOCATE(' ', UserUsername) > 0 THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Username must not have space characters'; 

  ELSEIF EXISTS (
    SELECT 1
    FROM `User`
    WHERE Username = UserUsername
  ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Username already exists. Please choose another one';

  ELSEIF UserFullName IS NULL OR UserFullName = '' THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Name must not be null'; 

  ELSEIF UserAddress IS NULL OR UserAddress = '' THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Address must not be null'; 

  ELSEIF (SELECT LENGTH(UserPassword)) < 8 THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Password must be at least 8 characters long'; 

  ELSEIF LOCATE(' ', UserPassword) > 0 THEN 
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Password must not have space characters'; 
  END IF;

  INSERT INTO `User` (Username, Name, Address, Password)
    VALUES (LOWER(UserUsername), CAP_FIRST(UserFullName), UserAddress, SHA2(UserPassword, 256));

  SELECT *
  FROM `User` 
  WHERE Username = UserUsername;
  COMMIT;
END $$

CREATE PROCEDURE login(
  IN loginUsername VARCHAR(100),
  IN loginPassword VARCHAR(64)
)
BEGIN
  SELECT ID 
  FROM User
  WHERE loginUsername = Username
    AND SHA2(loginPassword, 256) = Password;
END $$

CREATE PROCEDURE addBook(
  IN BookTitle VARCHAR(100),
  IN BookDescription VARCHAR(2000),
  IN BookAuthorID CHAR(38),
  IN BookISBN CHAR(17),
  IN BookStock INTEGER(10)
)
BEGIN
  START TRANSACTION;

  IF BookTitle IS NULL OR BookTitle = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Title must not be null'; 

  ELSEIF BookAuthorID IS NULL OR BookAuthorID = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AuthorID must not be null'; 

  ELSEIF NOT (BookISBN REGEXP '^(978|979)-[0-9]{1,5}-[0-9]{1,7}-[0-9]{1,7}-[0-9]$') THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid ISBN format'; 

  ELSEIF NOT (BookStock REGEXP '^[0-9]+$') THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid Stock format'; 

  ELSEIF BookStock < 1 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock must not be empty'; 
  END IF;

  INSERT INTO Book (AuthorID, Title, Description, ISBN)
    VALUES (BookAuthorID, BookTitle, BookDescription, BookISBN);
  INSERT INTO Stock (BookID, Stock, InitialStock)
    SELECT ID, 
    BookStock,
    BookStock
    FROM Book
    WHERE Book.ISBN = BookISBN;
  COMMIT;
END $$ 

CREATE PROCEDURE borrowBook (
  IN LoanUserID CHAR(38),
  IN LoanBookID CHAR(38)
)
BEGIN
  START TRANSACTION;
  IF LoanUserID IS NULL OR LoanUserID = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UserID must not be null'; 
  END IF;

  IF LoanBookID IS NULL OR LoanBookID = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BookID must not be null'; 
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM Book
    WHERE ID = LoanBookID
  ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: No matching book found'; 
  END IF;

  IF EXISTS (
    SELECT 1
    FROM Reservation 
    WHERE BookID = LoanBookID 
      AND UserID = LoanUserID 
    ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: Book is already being reserved';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM Loan 
    WHERE BookID = LoanBookID 
      AND UserID = LoanUserID 
    ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: Book is currently being borrowed';
  END IF;  

  IF (SELECT Stock FROM Stock WHERE BookID = LoanBookID) > 0 THEN
    INSERT INTO Loan (UserID, BookID)
      VALUES (LoanUserID, LoanBookID);

    UPDATE Stock
      SET Stock = Stock - 1
      WHERE BookID = LoanBookID;
  ELSE
    INSERT INTO Reservation (UserID, BookID)
      VALUES (LoanUserID, LoanBookID);
  END IF;
  
  COMMIT;
END $$

CREATE TRIGGER bookUpdateCheck
  AFTER UPDATE
  ON Stock
  FOR EACH ROW
BEGIN
  IF NEW.Stock > OLD.Stock THEN

    INSERT INTO Loan (UserID, BookID)
    SELECT UserID, BookID
    FROM Reservation
    WHERE Reservation.BookID = NEW.BookID
      AND NOT EXISTS (
        SELECT 1
        FROM Loan
        WHERE Loan.UserID = Reservation.UserID
          AND Loan.BookID = Reservation.BookID
      )
    ORDER BY Reservation.ReservationDate ASC
    LIMIT 1;

    IF ROW_COUNT() > 0 THEN
      UPDATE Stock
        SET Stock = Stock - 1
        WHERE BookID = NEW.BookID;
    END IF;

  END IF;
END $$

CREATE TRIGGER onLoanCreation
  AFTER INSERT
  ON Loan
  FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM Reservation
    WHERE BookID = NEW.BookID
      AND UserID = NEW.UserID
  ) THEN
    DELETE FROM Reservation
    WHERE BookID = NEW.BookID
      AND UserID = NEW.UserID;
  END IF;
END $$

CREATE PROCEDURE returnBook(
  IN ReturnBookID CHAR(38),
  IN ReturnUserID CHAR(38)
)
BEGIN
  START TRANSACTION;
  IF ReturnUserID IS NULL OR ReturnUserID = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UserID must not be null'; 
  END IF;

  IF ReturnBookID IS NULL OR ReturnBookID = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BookID must not be null'; 
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM Book
    WHERE ID = ReturnBookID
  ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: No matching book found'; 
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM Loan 
    WHERE BookID = ReturnBookID 
      AND UserID = ReturnUserID 
    ) THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: Book is not currently being borrowed';
  END IF;

  DELETE FROM Loan
  WHERE UserID = ReturnUserID
    AND BookID = ReturnBookID;

  UPDATE Stock
    SET Stock = Stock + 1
    WHERE BookID = ReturnBookID;

  COMMIT;
END $$

CREATE TRIGGER saveLoanToHistory
  AFTER DELETE
  ON Loan
  FOR EACH ROW
BEGIN
  INSERT INTO History (UserID, BookID, LoanDate)
    VALUES (OLD.UserID, OLD.BookID, OLD.LoanDate);
END $$

CREATE PROCEDURE deleteUser(
  IN DeleteUserID CHAR(38)
)
BEGIN
  START TRANSACTION;
    IF DeleteUserID IS NULL OR DeleteUserID = '' THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UserID must not be null'; 
    END IF;

    IF EXISTS (
      SELECT 1
      FROM Loan
      WHERE UserID = DeleteUserID
    ) THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: Outstanding loans found. Return current book loans before deleting account';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM `User`
      WHERE ID = DeleteUserID
    ) THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45102' SET MESSAGE_TEXT = 'Failed: No matching user found';
    END IF;

    DELETE FROM `User`
    WHERE ID = DeleteUserID;
  COMMIT;
END $$

CREATE TRIGGER reservationCleanup
  AFTER DELETE
  ON `User`
  FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM Reservation
    WHERE UserID = OLD.ID
  ) THEN
    DELETE FROM Reservation
    WHERE UserID = OLD.ID;
  END IF;

END $$

CREATE TRIGGER saveDeletedBook
  BEFORE DELETE
  ON Book
FOR EACH ROW
BEGIN
  INSERT INTO DeletedBook (ID, AuthorID, Title, Description, ISBN)
  VALUES (OLD.ID, OLD.AuthorID, OLD.Title, OLD.Description, OLD.ISBN);

  UPDATE History
    SET DeletedBookID = OLD.ID
    WHERE History.BookID = OLD.ID;
END $$

DELIMITER ;