# Library Management System - Road to Sigma Rizz DBA, for B27 database technology CS GC.
This is a repository to store and document the process and results of creating a library database system from an unnormalized dataset file. This project is developed as part of the B26 Database Technology course. It involves designing and implementing a comprehensive database management system (DBMS) for a library. The system covers all core aspects of DBMS, from storage management and memory optimization to transactions, indexing, and security.

## Resources
- [Unnormalized Library Data](data/unnormalized_library_data(in).csv)

## Normalization
|   Book_ID | Title                       | Author_Name      | Author_Birthdate   | ISBN              |   User_ID | User_Name           | User_Address                                               | Loan_Date   | Return_Date   |
|----------:|:----------------------------|:-----------------|:-------------------|-------------------|----------:|:--------------------|:-----------------------------------------------------------|:------------|:--------------|
|      3115 | Particularly charge nearly. | Anita Walker     | 11/1/1962          | 978-1-4223-8315-5 |      8425 | Tracey Kelly        | PSC 6481, Box 1952, APO AA 89825                           | 4/9/2024    | 8/21/2024     |
|      3270 | Goal ability him.           | Joseph Alvarez   | 1/5/1965           | 978-1-235-83555-1 |      9366 | Brittany Kim DVM    | 80826 Miller Plaza, Shariton, PR 87489                     | 2/14/2024   | 8/5/2024      |
|      3862 | Board.                      | Kimberly Brown   | 8/3/1970           | 978-0-483-52991-5 |      4425 | Daniel Harrison DDS | 95457 Christopher Manor Suite 485, Port Samantha, MT 79549 | 5/1/2024    | 7/31/2024     |
|      5157 | Remain begin.               | Christian Mason  | 1/18/1954          | 978-1-924983-22-8 |      8425 | Tracey Kelly        | PSC 6481, Box 1952, APO AA 89825                           | 2/3/2024    | 7/17/2024     |
|      6607 | Catch form kitchen.         | Calvin Clark     | 2/5/1984           | 978-0-01-444353-6 |      6304 | Erica Davidson      | 51540 Barbara Brook, Andrewmouth, DC 89545                 | 4/15/2024   | 8/31/2024     |
|      5011 | Dinner ahead but.           | Michael Morrison | 10/25/1988         | 978-1-298-44863-7 |      8425 | Tracey Kelly        | PSC 6481, Box 1952, APO AA 89825                           | 8/23/2024   | 9/8/2024      |

The [dataset](data/unnormalized_library_data(in).csv) given is unnormalized, meaning it has a lot of data redundancy. There are several steps to normalize this database.

### 1. Identify Repeating Data
It can be seen that the `Title`, `Author_Name`, `Author_Birthdate`, `ISBN`, `User_Name`, and `User_Address` are repeating and space-taking. They can then be separated into several entities, which are `Book`, `Author`, `User`, and `Loan History`.

### 2. ID Systems
Currently, the `Author` table does not have any ID system and `Book_ID` and `User_ID` are indistinguishable from one another. Hence the usage of `UUID` system, which is already by itself universally unique, concatenated with a prefix with each table's alias (e.g., "A-c350a9cd-8eed-11ef-834d-08bfb82c14c5" for `Author_ID`). This method is used over `AUTO_INCREMENT` because of its fixed-length string result and untraceability.

### Result
The normalization process results in a [Normalized Library Data](data/normalized_library_data.xlsx).

## Setup

### Web Server
This project uses [XAMPP](https://www.apachefriends.org/index.html) as the web server for its easy setup, cross-platform support and easily usable interface to manage the built-in MySQL (MariaDB) database system. XAMPP is ideal for testing web development as it provides an isolated thus safe web application development environment, in case the projec is to be extended into a web application.

### Storage Engine
`XAMPP` provides a range of storage engine to choose:

| Storage Engine     | Description                                                                                      |
|:-------------------|:-------------------------------------------------------------------------------------------------|
| CSV                |	Stores tables as CSV files                                                                      |
| MRG_MyISAM         |	Collection of identical MyISAM tables                                                           |
| MEMORY             |	Hash based, stored in memory, useful for temporary tables                                       |
| Aria               |	Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables |
| MyISAM             |	Non-transactional engine with good performance and small data footprint                         |
| SEQUENCE           |	Generated tables filled with sequential values                                                  |
| InnoDB             |	Supports transactions, row-level locking, foreign keys and encryption for tables                |
| PERFORMANCE_SCHEMA |	Performance Schema                                                                              |

From these choices, `InnoDB` should be used for the library data tables, as it provides the most features which are essential for the database.

## Use Cases
- Users can **borrow** and **reserve** books.
- Track which books are currently **borrowed** and which are **available**.
- View **borrowing history** for record-keeping.

## Entity Relationship Diagram
![ERD](assets/erd.png)
This ERD represents the schema for a Library Management System designed to manage books, users, loans, reservations, and author information.

## Entities and Relationships

### 1. Author
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

### 2. Book
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
  - Each `Book` is associated with one `Author`.
  - Each `Book` can have multiple `Loans` and `Reservations`.

### 3. DeletedBook
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

### 4. User
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
  - Each `User` can borrow multiple `Books` (via `Loan`).
  - Each `User` can reserve multiple `Books` (via `Reservation`).

### 5. Reservation
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

### 6. Loan
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

### 7. History
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

## Indexing
For a **faster** and more **efficient** data retrieval when querying, columns which are checked using `WHERE` statements (or any that could be used for searching purposes) are `INDEX`ed at the cost of slower `INSERT` and `UPDATE`.

- **Author**:
  ```sql
    CREATE INDEX idx_authorid ON Author (ID);
  ```
  - `idx_authorid`: For faster querying of author information by `ID`. (e.g., Displaying author's `Name` and `Birthdate` when opening a book).
- **Book**:
  ```sql
    CREATE INDEX idx_bookid ON Book (ID);
    CREATE INDEX idx_bookauthorid ON Book (AuthorID);
    CREATE INDEX idx_bookisbn ON Book (ISBN);
  ```
  - `idx_bookid`: Allows faster retrieval of book data from a `Reservation` or `Loan`.
  - `idx_bookauthorid`: Useful for when looking up books written by a specific author by `ID`.
  - `idx_bookisbn`: Speeds up searching for books from its `ISBN`, unique identifiers ofen used for searching or verifying book details.
- **DeletedBook**
  ```sql
    CREATE INDEX idx_deletedisbn ON DeletedBook (ISBN);
  ```
  - `idx_deletedisbn`: For faster checking when inserting a new `Book`. If there is a `DeletedBook` with the same `ISBN` of the new `Book`, restore the `DeletedBook` instead. 
- **User**:
  ```sql
    CREATE INDEX idx_userid ON `User` (ID);
    CREATE INDEX idx_username ON `User` (Username);
  ```
  - `idx_userid`: Similar to `idx_bookid`.
  - `idx_username`: Speeds up searches by `Username`, which is helpful for user authentication and profile lookup.
- **Reservation**:
  ```sql
    CREATE INDEX idx_reservationid ON Reservation (BookID, UserID);
    CREATE INDEX idx_bookreservationbydate ON Reservation (BookID, ReservationDate);
    CREATE INDEX idx_userreservationbydate ON Reservation (UserID, ReservationDate);
  ```
  - `idx_reservationid`: A composite index on `BookID` and `UserID` for a more specific searching of reservations where a user has reserved a particular book.
  - `idx_bookreservationdate`: Used to list reservations for a specific `Book`, and could be used to find the oldest `Reservation` created for a specific `Book` for creating `Loan`.
  - `idx_userreservationdate`: Used to list `Reservation`s done by a user sorted by date.
- **Loan**:
  ```sql
    CREATE INDEX idx_loanid ON Loan (BookID, UserID);
    CREATE INDEX idx_bookloanbydate ON Loan (BookID, LoanDate);
    CREATE INDEX idx_userloanbydate ON Loan (UserID, LoanDate);
  ```
  - `idx_loanid`: Similar to `idx_reservationid`.
  - `idx_bookloandate`: Similar to `idx_bookreservationdate`.
  - `idx_userloandate`: Similar to `idx_userreservationdate`.
- **History**:
  ```sql
    CREATE INDEX idx_returnbookid ON History (BookID);
    CREATE INDEX idx_historybydate ON History (LoanDate);
    CREATE INDEX idx_bookreturnbydate ON History (BookID, LoanDate);
    CREATE INDEX idx_userreturnbydate ON History (UserID, LoanDate);
    CREATE INDEX idx_bookidbydate ON History (BookID, UserID, LoanDate);
  ```
  - `idx_returnbookid`: For faster querying to update `DeletedBookID` of `History` when a `Book` is deleted.
  - `idx_historybydate`: Used for faster sorting of the `History` of returned `Book`s as a whole.
  - `idx_bookreturnbydate`: Used for listing the `History` of returned `Loan`s for a specific `Book` sorted by `LoanDate`.
  - `idx_userreturnbydate`: Used for `User`s to view their past `Loan`s sorted by `LoanDate`.
  - `idx_returnidbydate`: Used for specifically recall past `Loan`s of a certain `Book` by a certain `User` sorted by `LoanDate`.
 
## Storage Management
By default, `InnoDB` already separates tables into their own respective files.
```plaintext
xampp/
└── mysql/
    └── data/
        └── library/
            ├── author.frm
            ├── author.ibd
            ├── book.frm
            ├── book.ibd
            ├── deletedbook.frm
            ├── deletedbook.ibd
            ├── history.frm
            ├── history.ibd
            ├── loan.frm
            ├── loan.ibd
            ├── reservation.frm
            ├── reservation.ibd
            ├── user.frm
            └── user.ibd
```
### Modifying Tablespaces
To change the default sizes of each table, configure the `my.ini` file located in `...xampp/mysql/bin`.
```ini
  [mysqld]
  ...
  # Comment the following if you are using InnoDB tables
  #skip-innodb
  innodb_file_per_table=1
  innodb_data_home_dir="F:/xampp/mysql/data"
  innodb_data_file_path=ibdata1:10M:autoextend
  innodb_log_group_home_dir="F:/xampp/mysql/data"
  #innodb_log_arch_dir = "F:/xampp/mysql/data"
  ## You can set .._buffer_pool_size up to 50 - 80 %
  ## of RAM but beware of setting memory usage too high
  innodb_buffer_pool_size=3GB
  ## Set .._log_file_size to 25 % of buffer pool size
  innodb_log_file_size=750M
  innodb_log_buffer_size=16M
  innodb_flush_log_at_trx_commit=1
  innodb_lock_wait_timeout=5
```
To see the changes, restart the `MySQL` module using the `XAMPP Control Panel`.
