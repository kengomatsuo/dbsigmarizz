# Introduction to DBSigmaRizz
This is a repository to store and document the process and results of creating a library database system from an unnormalized dataset file.

[Unnormalized Library Data](unnormalized_library_data(in).csv)

# Setup
This project uses **XAMPP** as the web server for its easy setup, cross-platform support and easily usable interface to manage the built-in MySQL (MariaDB) database system. XAMPP is ideal for testing web development as it provides an isolated thus safe web application development environment, in case the projec is to be extended into a web application.

# Database Design
The ERD for the library system is createdusing the free **Visual Paradigm Community Edition**.
![ERD](assets/erd.png)
This ERD represents the schema for a Library Management System designed to manage books, users, loans, reservations, and author information.

## Entities and Relationships

### 1. Author
- **Attributes**:
  - `ID` (Primary Key): Unique identifier for each author.
  - `Name`: The name of the author.
  - `Birthdate`: The date of birth of the author.
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
- **Relationships**:
  - Each `Book` is associated with one `Author` but can have multiple `Loans` and `Reservations`.

### 3. User
- **Attributes**:
  - `ID` (Primary Key): Unique identifier for each user.
  - `Name`: The name of the user.
  - `Address`: The address of the user.
  - `Username`: Unique username for user login.
  - `Password`: Encrypted password for user authentication.
- **Relationships**:
  - Each `User` can borrow multiple `Books` (via `Loan`), and reserve multiple `Books` (via `Reservation`).

### 4. Loan
- **Attributes**:
  - `BookID` (Foreign Key): Refers to the `ID` of the `Book`.
  - `UserID` (Foreign Key): Refers to the `ID` of the `User`.
  - `LoanDate`: The date when the book was borrowed.
- **Relationships**:
  - A `Loan` connects a `User` to a `Book`. Each loan represents a book that is currently borrowed.

### 5. Reservation
- **Attributes**:
  - `BookID` (Foreign Key): Refers to the `ID` of the `Book`.
  - `UserID` (Foreign Key): Refers to the `ID` of the `User`.
  - `ReservationDate`: The date when the reservation was made.
- **Relationships**:
  - A `Reservation` links a `User` to a `Book`. It represents a reserved copy that will be borrowed when available.

### 6. History
- **Attributes**:
  - `BookID` (Foreign Key): Refers to the `ID` of the `Book`.
  - `UserID` (Foreign Key): Refers to the `ID` of the `User`.
  - `LoanDate`: The date when the book was borrowed.
  - `ReturnDate`: The date when the book was returned.
- **Relationships**:
  - The `History` entity logs past loans, showing which `User` borrowed which `Book`, and when.

## Use Cases Supported
- Users can **borrow** and **reserve** books.
- Track which books are currently **borrowed** and which are **available**.
- View **borrowing history** for record-keeping.

