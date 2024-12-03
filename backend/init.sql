CREATE database testdb;

\c testdb;

CREATE TABLE users (
  id VARCHAR(100) PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
	email VARCHAR(100) NOT NULL UNIQUE,
	password VARCHAR(100) NOT NULL,
  profile_image TEXT DEFAULT '',
  weight FLOAT NOT NULL,
  weekly_goal VARCHAR(100) DEFAULT '',
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100) DEFAULT '',
  creator_id VARCHAR(100) NOT NULL,
  public BOOLEAN DEFAULT false,
  description TEXT DEFAULT '',
  copy_course_id VARCHAR(100) DEFAULT '',
  total_distance VARCHAR(100) DEFAULT '0.00',
  total_time VARCHAR(100) DEFAULT '0',
  FOREIGN KEY (creator_id) REFERENCES users(id)
);

CREATE TABLE points (
  id VARCHAR(100) PRIMARY KEY,
  course_id VARCHAR(100) NOT NULL,
  latitude VARCHAR(100) NOT NULL,
  longitude VARCHAR(100) NOT NULL,
  "order" INT DEFAULT 0,
  "current_time" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- export PATH=$HOME/flutter/bin:$PATH 