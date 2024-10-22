DROP TABLE IF EXISTS Imported;

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
) ENGINE = MEMORY;

LOAD DATA INFILE 'C:/Users/kenne/Downloads/unnormalized_library_data(in).csv'
  INTO TABLE Imported
  FIELDS TERMINATED BY ',' ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES;

INSERT INTO Author (Name, Birthdate)
SELECT DISTINCT AuthorName, STR_TO_DATE(AuthorBirthdate, '%c/%e/%Y') 
FROM Imported
ON DUPLICATE KEY UPDATE Name=Name;

INSERT INTO Book (AuthorID, Title, ISBN)
SELECT DISTINCT
  Author.ID,
  Imported.BookTitle,
  Imported.ISBN
FROM Imported
LEFT JOIN Author
  ON Author.Name = Imported.AuthorName
  AND Author.Birthdate = STR_TO_DATE(Imported.AuthorBirthdate, '%c/%e/%Y') 
WHERE Author.ID IS NOT NULL
ON DUPLICATE KEY UPDATE Title=Title;

INSERT INTO Stock (BookID, Stock, InitialStock)
SELECT ID, 
  @random_number := FLOOR(1+(RAND() * 15)),
  @random_number 
FROM Book;

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
  STR_TO_DATE(Imported.LoanDate, '%c/%e/%Y') ,
  STR_TO_DATE(Imported.ReturnDate, '%c/%e/%Y') 
FROM Imported
LEFT JOIN Book
  ON Book.ISBN = Imported.ISBN
LEFT JOIN User 
  ON User.Username = LOWER(REPLACE(Imported.UserName, ' ', ''))
WHERE Book.ID IS NOT NULL AND User.ID IS NOT NULL;

DROP TABLE Imported;