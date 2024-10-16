CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL,
	password VARCHAR(100) NOT NULL,
	email VARCHAR(100) NOT NULL,
	nickname VARCHAR(100) NOT NULL,
  profile_image TEXT DEFAULT '',
  weight INT NOT NULL,
  weekly_goal VARCHAR(100) DEFAULT 0,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
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

CREATE TABLE courses (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL, 
  description TEXT DEFAULT "",
  length FLOAT64 NOT NULL,
  estimated_time VARCHAR(100) NOT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE points {
  id SERIAL PRIMARY KEY,
  course_id INT NOT NULL,
  latitude VARCHAR(100) NOT NULL,
  longitude VARCHAR(100) NOT NULL,
  start_point INT(1) DEFAULT FALSE,
  end_point INT(1) DEFAULT FALSE,
  order INT DEFAULT 0
}