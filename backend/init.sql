CREATE database testdb;

\c testdb;

CREATE TABLE users (
  id VARCHAR(100) PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
	email VARCHAR(100) NOT NULL UNIQUE,
	password VARCHAR(100) NOT NULL,
  profile_image TEXT DEFAULT '',
  weight FLOAT NOT NULL,
  weekly_goal VARCHAR(100) DEFAULT 0,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(100) NOT NULL,
  name VARCHAR(100) NOT NULL, 
  description TEXT DEFAULT '',
  length FLOAT NOT NULL,
  estimated_time VARCHAR(100) NOT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE sessions (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(100) NOT NULL,
  course_id INT NOT NULL,
  distance FLOAT NOT NULL,
  time VARCHAR(100) NOT NULL,
  start_time VARCHAR(100) NOT NULL,
  end_time VARCHAR(100) NOT NULL,
  average_pace VARCHAR(100) NOT NULL,
  calories_burned VARCHAR(100) NOT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE competitions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
	date VARCHAR(100) NOT NULL,
  details VARCHAR(100) NOT NULL,
	latitude VARCHAR(100) NOT NULL,
	longitude VARCHAR(100) NOT NULL,
  link VARCHAR(100) NOT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE coursestest (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100) DEFAULT '',
  creator_id VARCHAR(100) NOT NULL, 
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE points (
  id VARCHAR(100) PRIMARY KEY,
  user_id VARCHAR(100) NOT NULL,
  course_id VARCHAR(100) NOT NULL,
  latitude VARCHAR(100) NOT NULL,
  longitude VARCHAR(100) NOT NULL,
  start_point BOOLEAN DEFAULT 'false',
  end_point BOOLEAN DEFAULT 'false',
  "order" INT DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- export PATH=$HOME/flutter/bin:$PATH 