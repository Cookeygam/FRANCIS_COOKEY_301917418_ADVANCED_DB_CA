-- Create the user with a password
CREATE USER TRANSACT IDENTIFIED BY "JpmorganChase123$$$#";
CREATE USER CUSTOMER IDENTIFIED BY "Jpmo@ganBANK1230$$#";

-- Grant basic connection and development privileges
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO TRANSACT;

-- Give the user permission to actually store data on the system
ALTER USER TRANSACT QUOTA UNLIMITED ON USERS;
