# Library Management System - Road to Sigma Rizz DBA, for B27 database technology CS GC.
This is a repository to store and document the process and results of creating a library database system from an unnormalized dataset file. This project is developed as part of the B26 Database Technology course. It involves designing and implementing a comprehensive database management system (DBMS) for a library. The system covers all core aspects of DBMS, from storage management and memory optimization to transactions, indexing, and security.

## Resources
- [Unnormalized Library Data](unnormalized_library_data(in).csv)

## Setup
This project uses **XAMPP** as the web server for its easy setup, cross-platform support and easily usable interface to manage the built-in MySQL (MariaDB) database system. XAMPP is ideal for testing web development as it provides an isolated thus safe web application development environment, in case the projec is to be extended into a web application.

## Database Design
![ERD](assets/erd.png)
This ERD represents the schema for a Library Management System designed to manage books, users, loans, reservations, and author information.

### Entities and Relationships

#### 1. Author
- **Attributes**:
  - `ID` (Primary Key): Unique identifier for each author.
  - `Name`: The name of the author.
  - `Birthdate`: The date of birth of the author.
- **Script**:
  ```sql
  CREATE TABLE
  Author (
    ID CHAR(38) PRIMARY KEY DEFAULT CONCAT ('A-', UUID ()),
    Name VARCHAR(50) NOT NULL,
    CHECK (Name != ''),
    Birthdate DATE NOT NULL,
    CHECK (Birthdate > '0000-00-00'),
    UNIQUE (Name, Birthdate)
  ) ENGINE = InnoDB;
  ```
- **Relationships**:
  - Each `Author` can write multiple `Books`.

#### 2. Book
- **Attributes**:
  - `ID` (Primary Key): Unique identifier for each book.
  - `AuthorID` (Foreign Key): Refers to the `ID` of the `Author`.
  - `Title`: The title of the book.
  - `Description`: A brief description of the book.
  - `ISBN`: Unique identifier for the book's edition.
  - `Stock`: The current number of available copies.
  - `InitialStock`: The original number of copies added to the library.
- **Script**:
  ```sql
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
  ```
- **Relationships**:
  - Each `Book` is associated with one `Author` but can have multiple `Loans` and `Reservations`.

#### 3. DeletedBook
- **Attributes**:
  - `ID` (Primary Key): Unique identifier for each deleted book.
  - `AuthorID` (Foreign Key): Refers to the `ID` of the `Author`.
  - `Title`: The title of the deleted book.
  - `Description`: A brief description of the deleted book.
  - `ISBN`: Unique identifier for the deleted book's edition.
- **Script**:
  ```sql
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
  ```
- **Relationships**:
  - Each `DeletedBook` acts as a place for deleted `Book`s to preserve their information while not being available for loan.

#### 4. User
- **Attributes**:
  - `ID` (Primary Key): Unique identifier for each user.
  - `Name`: The name of the user.
  - `Address`: The address of the user.
  - `Username`: Unique username for user login.
  - `Password`: Encrypted password for user authentication.
```sql
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
  ```
- **Relationships**:
  - Each `User` can borrow multiple `Books` (via `Loan`), and reserve multiple `Books` (via `Reservation`).

#### 5. Reservation
- **Attributes**:
  - `BookID` (Foreign Key): Refers to the `ID` of the `Book`.
  - `UserID` (Foreign Key): Refers to the `ID` of the `User`.
  - `ReservationDate`: The date when the reservation was made.
- **Script**:
  ```sql
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
  ```
- **Relationships**:
  - A `Reservation` links a `User` to a `Book`. It represents a reserved copy that will be borrowed when available.

#### 6. Loan
- **Attributes**:
  - `BookID` (Foreign Key): Refers to the `ID` of the `Book`.
  - `UserID` (Foreign Key): Refers to the `ID` of the `User`.
  - `LoanDate`: The date when the book was borrowed.
- **Script**:
  ```sql
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
  ```
- **Relationships**:
  - A `Loan` connects a `User` to a `Book`. Each loan represents a book that is currently borrowed.

#### 7. History
- **Attributes**:
  - `BookID` (Foreign Key): Refers to the `ID` of the `Book`.
  - `UserID` (Foreign Key): Refers to the `ID` of the `User`.
  - `LoanDate`: The date when the book was borrowed.
  - `ReturnDate`: The date when the book was returned.
- **Script**:
  ```sql
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
  ```
- **Relationships**:
  - The `History` entity logs past loans, showing which `User` borrowed which `Book`, and when.

## Use Cases
- Users can **borrow** and **reserve** books.
- Track which books are currently **borrowed** and which are **available**.
- **Returning** borrowed books will add to the **borrowing history**.
- View **borrowing history** for record-keeping.



