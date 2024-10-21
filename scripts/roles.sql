DROP ROLE 'admin';
DROP ROLE 'librarian';
DROP ROLE 'reader';

CREATE ROLE 'admin';
CREATE ROLE 'librarian';
CREATE ROLE 'reader';

GRANT ALL PRIVILEGES ON library.* TO 'admin';

GRANT SELECT, INSERT, UPDATE, DELETE ON library.Author TO 'librarian';
GRANT SELECT, INSERT, UPDATE, DELETE ON library.Book TO 'librarian';
GRANT SELECT, DELETE ON library.Loan TO 'librarian';
GRANT SELECT ON library.History TO 'librarian';

GRANT SELECT, INSERT, UPDATE, DELETE ON library.User TO 'reader';
GRANT SELECT, INSERT, DELETE ON library.Reservation TO 'reader';
GRANT SELECT, INSERT ON library.Loan TO 'reader';
GRANT SELECT ON library.History TO 'reader';