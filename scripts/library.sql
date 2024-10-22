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
    FOREIGN KEY (AuthorID) REFERENCES Author (ID)
      ON UPDATE CASCADE 
      ON DELETE RESTRICT
  ) ENGINE = InnoDB;

CREATE INDEX idx_bookid ON Book (ID);

CREATE INDEX idx_bookauthorid ON Book (AuthorID);

CREATE INDEX idx_bookisbn ON Book (ISBN);

CREATE TABLE
  Stock (
    BookID CHAR(38) PRIMARY KEY,
    Stock INTEGER (10) NOT NULL,
    CHECK (Stock >= 0 AND Stock <= InitialStock),
    InitialStock INTEGER (10) NOT NULL,
    FOREIGN KEY (BookID) REFERENCES Book(ID)
    ON UPDATE CASCADE
    ON DELETE CASCADE
  ) ENGINE = InnoDB;

CREATE INDEX idx_stock ON Stock (Stock);

CREATE TABLE
  DeletedBook (
    ID CHAR(38) PRIMARY KEY,
    AuthorID CHAR(38) NULL,
    CHECK (AuthorID != ''),
    Title VARCHAR(100) NOT NULL,
    CHECK (Title != ''),
    Description VARCHAR(2000) NULL,
    CHECK (Description != ''),
    ISBN CHAR(17) NOT NULL UNIQUE,
    CHECK (ISBN REGEXP '^(978|979)-[0-9]{1,5}-[0-9]{1,7}-[0-9]{1,7}-[0-9]$'),
    FOREIGN KEY (AuthorID) REFERENCES Author (ID)
      ON UPDATE CASCADE 
      ON DELETE RESTRICT
  ) ENGINE = InnoDB;

CREATE INDEX idx_deletedisbn ON DeletedBook (ISBN);

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

CREATE INDEX idx_username ON `User` (Username);

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

CREATE INDEX idx_reservationid ON Reservation (BookID, UserID);

CREATE INDEX idx_bookreservationbydate ON Reservation (BookID, ReservationDate);

CREATE INDEX idx_userreservationbydate ON Reservation (UserID, ReservationDate);

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

CREATE INDEX idx_loanid ON Loan (BookID, UserID);

CREATE INDEX idx_bookloanbydate ON Loan (BookID, LoanDate);

CREATE INDEX idx_userloanbydate ON Loan (UserID, LoanDate);

CREATE TABLE
  History (
    BookID CHAR(38) NULL,
    UserID CHAR(38) NOT NULL,
    DeletedBookID CHAR(38) NULL,
    LoanDate TIMESTAMP NOT NULL,
    CHECK (LoanDate > '0000-00-00 00-00-00'),
    ReturnDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (ReturnDate > '0000-00-00 00-00-00'),
    FOREIGN KEY (BookID) REFERENCES Book (ID)
      ON UPDATE CASCADE
      ON DELETE SET NULL,
    FOREIGN KEY (UserID) REFERENCES `User` (ID) 
      ON UPDATE CASCADE
      ON DELETE CASCADE,
    FOREIGN KEY (DeletedBookID) REFERENCES DeletedBook (ID)
      ON UPDATE CASCADE
      ON DELETE RESTRICT
  ) ENGINE = InnoDB;

CREATE INDEX idx_historybydate ON History (LoanDate);

CREATE INDEX idx_bookreturnbydate ON History (BookID, LoanDate);

CREATE INDEX idx_userreturnbydate ON History (UserID, LoanDate);

CREATE INDEX idx_returnidbydate ON History (BookID, UserID, LoanDate);

