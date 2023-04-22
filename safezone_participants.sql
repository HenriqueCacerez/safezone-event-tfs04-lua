CREATE TABLE safezone_participants (
  id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  cid varchar(255) NOT NULL,
  life tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;