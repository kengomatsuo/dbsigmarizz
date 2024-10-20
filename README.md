# Library Management System - Road to Sigma Rizz DBA, for B27 database technology CS GC.
This is a repository to store and document the process and results of creating a library database system from an unnormalized dataset file. This project is developed as part of the B26 Database Technology course. It involves designing and implementing a comprehensive database management system (DBMS) for a library. The system covers all core aspects of DBMS, from storage management and memory optimization to transactions, indexing, and security.

## Resources
- [Unnormalized Library Data](data/unnormalized_library_data(in).csv)

## Normalization
|   Book_ID | Title                       | Author_Name      | Author_Birthdate   | ISBN              |   User_ID | User_Name           | User_Address                                               | Loan_Date   | Return_Date   |
|----------:|:----------------------------|:-----------------|:-------------------|:------------------|----------:|:--------------------|:-----------------------------------------------------------|:------------|:--------------|
|      3115 | Particularly charge nearly. | Anita Walker     | 11/1/1962          | 978-1-4223-8315-5 |      8425 | Tracey Kelly        | PSC 6481, Box 1952, APO AA 89825                           | 4/9/2024    | 8/21/2024     |
|      3270 | Goal ability him.           | Joseph Alvarez   | 1/5/1965           | 978-1-235-83555-1 |      9366 | Brittany Kim DVM    | 80826 Miller Plaza, Shariton, PR 87489                     | 2/14/2024   | 8/5/2024      |
|      3862 | Board.                      | Kimberly Brown   | 8/3/1970           | 978-0-483-52991-5 |      4425 | Daniel Harrison DDS | 95457 Christopher Manor Suite 485, Port Samantha, MT 79549 | 5/1/2024    | 7/31/2024     |
|      5157 | Remain begin.               | Christian Mason  | 1/18/1954          | 978-1-924983-22-8 |      8425 | Tracey Kelly        | PSC 6481, Box 1952, APO AA 89825                           | 2/3/2024    | 7/17/2024     |
|      6607 | Catch form kitchen.         | Calvin Clark     | 2/5/1984           | 978-0-01-444353-6 |      6304 | Erica Davidson      | 51540 Barbara Brook, Andrewmouth, DC 89545                 | 4/15/2024   | 8/31/2024     |
|      5011 | Dinner ahead but.           | Michael Morrison | 10/25/1988         | 978-1-298-44863-7 |      8425 | Tracey Kelly        | PSC 6481, Box 1952, APO AA 89825                           | 8/23/2024   | 9/8/2024      |

The [dataset](data/unnormalized_library_data(in).csv) given is unnormalized, meaning it has a lot of data redundancy. There are several steps to normalize this database.

### 1. Identify Repeating Data
It can be seen that the `Title`, `Author_Name`, `Author_Birthdate`, `ISBN`, `User_Name`, and `User_Address` are repeating and space-taking. They can then be separated into several entities, which are `Book`, `Author`, `User`, and `Loan History`.

### 2. ID-ing
Currently, the `Author` table does not have any ID system and `Book_ID` and `User_ID` are indistinguishable from one another. Hence the usage of `UUID` system, which is already by itself universally unique, concatenated with a prefix with each table's alias (eg. "A-c350a9cd-8eed-11ef-834d-08bfb82c14c5" for `Author_ID`). This method is used over `AUTO_INCREMENT` because of its fixed-length string result and untraceability.

### Result
The normalization process results in a [Normalized Library Data](data/normalized_library_data.xlsx).

## Setup
This project uses [XAMPP](https://www.apachefriends.org/index.html) as the web server for its easy setup, cross-platform support and easily usable interface to manage the built-in MySQL (MariaDB) database system. XAMPP is ideal for testing web development as it provides an isolated thus safe web application development environment, in case the projec is to be extended into a web application.

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
  - Each `DeletedBook` acts as a place for deleted `Book` rows to preserve their information while not being available for loan.

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
- View **borrowing history** for record-keeping.
