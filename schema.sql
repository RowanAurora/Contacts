CREATE TABLE contact (
    id serial PRIMARY KEY,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    email varchar(75) NOT NULL,
    phone text NOT NULL CHECK (LENGTH(phone) BETWEEN 8 AND 12),
    Contact text
);
