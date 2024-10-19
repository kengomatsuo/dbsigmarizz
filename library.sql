SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

SHOW VARIABLES LIKE 'have_query_cache';

SHOW VARIABLES LIKE 'query_cache_size';

DROP DATABASE IF EXISTS library;

CREATE DATABASE library;

USE library;

CREATE TABLE
  Author (
    ID CHAR(38) PRIMARY KEY DEFAULT CONCAT ('A-', UUID ()),
    Name VARCHAR(50) NOT NULL,
    CHECK (Name != ''),
    Birthdate DATE NOT NULL,
    CHECK (Birthdate > '0000-00-00'),
    UNIQUE (Name, Birthdate)
  ) ENGINE = InnoDB;

CREATE INDEX idx_authorid ON Author (ID);

CREATE TABLE
  Book (
    ID CHAR(38) PRIMARY KEY DEFAULT CONCAT ('B-', UUID ()),
    AuthorID CHAR(38) NOT NULL,
    CHECK (AuthorID != ''),
    Title VARCHAR(100) NOT NULL,
    CHECK (Title != ''),
    Description VARCHAR(2000) NULL,
    CHECK (Description != ''),
    ISBN CHAR(17) NOT NULL UNIQUE,
    CHECK (ISBN REGEXP '^(978|979)-[0-9]{1,5}-[0-9]{1,7}-[0-9]{1,7}-[0-9]$'),
    Stock INTEGER (10) NOT NULL,
    CHECK (Stock >= 0),
    FOREIGN KEY (AuthorID) REFERENCES Author (ID)
      ON UPDATE CASCADE 
      ON DELETE RESTRICT,
    InitialStock INTEGER (10) NOT NULL
  ) ENGINE = InnoDB;

CREATE INDEX idx_booktitle ON Book (Title);

CREATE FULLTEXT INDEX idx_bookdescription ON Book(Description);

CREATE INDEX idx_bookauthorid ON Book (AuthorID);

CREATE TABLE
  `User` (
    ID CHAR(38) PRIMARY KEY DEFAULT CONCAT ('U-', UUID ()),
    Username VARCHAR(100) NOT NULL UNIQUE,
    CHECK (Username != ''),
    Role VARCHAR(10) NOT NULL DEFAULT 'reader',
    CHECK (Role = 'reader' OR Role = 'librarian' OR Role = 'admin'),
    Name VARCHAR(50) NOT NULL,
    CHECK (Name != ''),
    Address VARCHAR(200) NOT NULL,
    CHECK (Address != ''),
    `Password` CHAR(64) NOT NULL,
    CHECK (CHAR_LENGTH(`Password`) = 64)
  ) ENGINE = InnoDB;

CREATE INDEX idx_userid ON `User` (ID);

CREATE TABLE
  Reservation (
    BookID CHAR(38) NOT NULL,
    UserID CHAR(38) NOT NULL,
    ReservationDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (BookID, UserID),
    FOREIGN KEY (UserID) REFERENCES `User` (ID)
      ON UPDATE CASCADE 
      ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book (ID) 
      ON UPDATE CASCADE 
      ON DELETE CASCADE
  ) ENGINE = InnoDB;

CREATE INDEX idx_reservationbookid ON Reservation (BookID);

CREATE INDEX idx_reservationuserid ON Reservation (UserID);

CREATE INDEX idx_reservationdate ON Reservation (ReservationDate);

CREATE TABLE
  Loan (
    BookID CHAR(38) NOT NULL,
    UserID CHAR(38) NOT NULL,
    LoanDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (LoanDate > '0000-00-00 00-00-00'),
    PRIMARY KEY (BookID, UserID, LoanDate),
    FOREIGN KEY (UserID) REFERENCES `User` (ID) 
      ON UPDATE CASCADE 
      ON DELETE RESTRICT,
    FOREIGN KEY (BookID) REFERENCES Book (ID) 
      ON UPDATE CASCADE 
      ON DELETE RESTRICT
  ) ENGINE = InnoDB;

CREATE INDEX idx_loanbookid ON Loan (BookID);

CREATE INDEX idx_loanuserid ON Loan (UserID);

CREATE INDEX idx_loandate ON Loan (LoanDate);

CREATE TABLE
  History (
    BookID CHAR(38) NULL,
    UserID CHAR(38) NOT NULL,
    LoanDate TIMESTAMP NOT NULL,
    CHECK (LoanDate > '0000-00-00 00-00-00'),
    ReturnDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (ReturnDate > '0000-00-00 00-00-00'),
    PRIMARY KEY (BookID, UserID, LoanDate),
    FOREIGN KEY (BookID) REFERENCES Book (ID)
      ON UPDATE CASCADE
      ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES `User` (ID) 
      ON UPDATE CASCADE
      ON DELETE CASCADE
  ) ENGINE = InnoDB;

CREATE INDEX idx_returnbookid ON History (BookID);

CREATE INDEX idx_returnuserid ON History (UserID);
















-- roles
DROP ROLE 'admin';
DROP ROLE 'librarian';
DROP ROLE 'reader';

CREATE ROLE 'admin';
GRANT ALL PRIVILEGES ON library.* TO 'admin';

CREATE ROLE 'librarian';
GRANT SELECT, INSERT, UPDATE, DELETE ON library.Author TO 'librarian';
GRANT SELECT, INSERT, UPDATE, DELETE ON library.Book TO 'librarian';
GRANT SELECT, DELETE ON library.Loan TO 'librarian';

CREATE ROLE 'reader';
GRANT SELECT, INSERT, UPDATE, DELETE ON library.User TO 'reader';
GRANT SELECT, INSERT, DELETE ON library.Reservation TO 'reader';
GRANT SELECT, INSERT ON library.Loan TO 'reader';
GRANT SELECT ON library.History TO 'reader';
















-- procedures
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
  COMMIT;
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
  END IF;

  -- IF BookDescription IS NULL OR BookDescription = '' THEN
  --   ROLLBACK;
  --   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Description must not be null'; 
  -- END IF;

  IF BookAuthorID IS NULL OR BookAuthorID = '' THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AuthorID must not be null'; 
  END IF;

  IF NOT (BookISBN REGEXP '^(978|979)-[0-9]{1,5}-[0-9]{1,7}-[0-9]{1,7}-[0-9]$') THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid ISBN format'; 
  END IF;

  IF NOT (BookStock REGEXP '^[0-9]+$') THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid Stock format'; 
  END IF;

  IF BookStock < 1 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock must not be empty'; 
  END IF;

  INSERT INTO Book (AuthorID, Title, Description, ISBN, Stock, InitialStock)
    VALUES (BookAuthorID, BookTitle, BookDescription, BookISBN, BookStock, BookStock);

  COMMIT;
END $$ 

CREATE PROCEDURE login(
  IN loginUsername VARCHAR(100),
  IN loginPassword VARCHAR(64)
)
BEGIN

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

  IF (SELECT Stock FROM Book WHERE ID = LoanBookID) > 0 THEN
    INSERT INTO Loan (UserID, BookID)
      VALUES (LoanUserID, LoanBookID);

    UPDATE Book
      SET Stock = Stock - 1
      WHERE ID = LoanBookID;
  ELSE
    INSERT INTO Reservation (UserID, BookID)
      VALUES (LoanUserID, LoanBookID);
  END IF;
  
  COMMIT;
END $$

CREATE TRIGGER bookUpdateCheck
  AFTER UPDATE
  ON Book
  FOR EACH ROW
BEGIN
  IF NEW.Stock > OLD.Stock THEN

    INSERT INTO Loan (UserID, BookID)
    SELECT UserID, BookID
    FROM Reservation
    WHERE Reservation.BookID = NEW.ID
      AND NOT EXISTS (
        SELECT 1
        FROM Loan
        WHERE Loan.UserID = Reservation.UserID
          AND Loan.BookID = Reservation.BookID
      )
    ORDER BY Reservation.ReservationDate ASC
    LIMIT 1;

    IF ROW_COUNT() > 0 THEN
      UPDATE Book
        SET Stock = Stock - 1
        WHERE ID = NEW.ID;

      -- DELETE FROM Reservation
      -- WHERE UserID IN (
      --   SELECT UserID
      --   FROM Loan
      --   WHERE BookID = NEW.ID
      --   ORDER BY LoanDate DESC
      --   LIMIT 1
      -- )
      -- AND BookID = NEW.ID;
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

  UPDATE Book
    SET Stock = Stock + 1
    WHERE ID = ReturnBookID;

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


DELIMITER ;
















-- import csv
CREATE TABLE
  Imported (
    OldBookID CHAR(4),
    BookTitle VARCHAR(100),
    AuthorName VARCHAR(50),
    AuthorBirthdate VARCHAR(10),
    ISBN CHAR(17),
    OldUserID CHAR(4),
    UserName VARCHAR(50),
    UserAddress VARCHAR(200),
    LoanDate VARCHAR(10),
    ReturnDate VARCHAR(10)
) ENGINE = InnoDB;

LOAD DATA INFILE 'C:/Users/kenne/Downloads/unnormalized_library_data(in).csv'
  INTO TABLE Imported
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES;

INSERT INTO Author (Name, Birthdate)
SELECT DISTINCT AuthorName, STR_TO_DATE(AuthorBirthdate, '%m/%d/%y') 
FROM Imported
ON DUPLICATE KEY UPDATE Name=Name;

INSERT INTO Book (AuthorID, Title, ISBN, Stock, InitialStock)
SELECT DISTINCT
  Author.ID,
  Imported.BookTitle,
  Imported.ISBN,
  @random_number := FLOOR(1+(RAND() * 15)),
  @random_number 
FROM Imported
LEFT JOIN Author
  ON Author.Name = Imported.AuthorName
  AND Author.Birthdate = STR_TO_DATE(Imported.AuthorBirthdate, '%m/%d/%y')
WHERE Author.ID IS NOT NULL
ON DUPLICATE KEY UPDATE Title=Title;

INSERT INTO `User` (Username, Name, Address, Password)
SELECT DISTINCT 
  LOWER(REPLACE(Imported.UserName, ' ', '')), 
  Imported.UserName, 
  UserAddress, 
  SHA2(LOWER(REPLACE(Imported.UserName, ' ', '')), 256)
FROM Imported
ON DUPLICATE KEY UPDATE User.Username=User.Username;

INSERT INTO History (BookID, UserID, LoanDate, ReturnDate)
SELECT
  Book.ID,
  User.ID,
  STR_TO_DATE(Imported.LoanDate, '%m/%d/%y'),
  STR_TO_DATE(Imported.ReturnDate, '%m/%d/%y')
FROM Imported
LEFT JOIN Book
  ON Book.ISBN = Imported.ISBN
LEFT JOIN User 
  ON User.Username = LOWER(REPLACE(Imported.UserName, ' ', ''))
WHERE Book.ID IS NOT NULL AND User.ID IS NOT NULL;

DROP TABLE Imported;