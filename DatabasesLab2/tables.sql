CREATE TABLE Programs(
	name TEXT NOT NULL PRIMARY KEY,
	abbr TEXT NOT NULL
);
CREATE TABLE Departments(
	name TEXT NOT NULL PRIMARY KEY,
	abbr TEXT NOT NULL UNIQUE
);
CREATE TABLE Students(
	idnr VARCHAR(10) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	login TEXT NOT NULL UNIQUE,
	program TEXT NOT NULL REFERENCES Programs
);
CREATE TABLE Branches(
	name TEXT NOT NULL,
	program TEXT NOT NULL REFERENCES Programs,
	PRIMARY KEY (name,program)
);
CREATE TABLE Courses(
	code CHAR(6) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL UNIQUE,
	credits FLOAT NOT NULL,
	department TEXT NOT NULL REFERENCES Departments
);
CREATE TABLE LimitedCourses(
	code CHAR(6) NOT NULL PRIMARY KEY REFERENCES Courses,
	capacity INTEGER NOT NULL
);
CREATE TABLE StudentBranches(
	student TEXT NOT NULL PRIMARY KEY REFERENCES Students,
	branch TEXT NOT NULL,
	program TEXT NOT NULL,
	FOREIGN KEY (branch,program) REFERENCES Branches (name,program)
);
CREATE TABLE Classifications(
	name TEXT NOT NULL PRIMARY KEY
);
CREATE TABLE Classified(
	course TEXT NOT NULL REFERENCES courses (code),
	classification TEXT NOT NULL REFERENCES classifications (name),
	PRIMARY KEY (course,classification)
);
CREATE TABLE MandatoryProgram(
	course TEXT NOT NULL REFERENCES Courses (code),
	program TEXT NOT NULL REFERENCES Programs,
	PRIMARY KEY (course,program)
);
CREATE TABLE MandatoryBranch(
	course TEXT NOT NULL REFERENCES Courses (code),
	branch TEXT NOT NULL,
	program TEXT NOT NULL REFERENCES Programs,
	PRIMARY KEY (course,branch,program),
	FOREIGN KEY (branch,program) REFERENCES Branches (name,program)
);
CREATE TABLE RecommendedBranch(
	course TEXT NOT NULL REFERENCES Courses (code),
	branch TEXT NOT NULL,
	program TEXT NOT NULL REFERENCES Programs,
	PRIMARY KEY (course,branch,program),
	FOREIGN KEY (branch,program) REFERENCES Branches (name,program)
);
CREATE TABLE Registered(
	student VARCHAR(10) NOT NULL REFERENCES Students (idnr),
	course TEXT NOT NULL REFERENCES Courses (code),
	PRIMARY KEY(student,course)
);
CREATE TABLE Taken(
	student VARCHAR(10) NOT NULL REFERENCES Students (idnr),
	course TEXT NOT NULL REFERENCES Courses (code),
	grade CHAR NOT NULL check (grade IN ('U', '3', '4', '5')),
	PRIMARY KEY (student,course)
);
CREATE TABLE WaitingList(
	student VARCHAR(10) NOT NULL REFERENCES Students (idnr),
	course TEXT NOT NULL REFERENCES Limitedcourses (code),
	position SERIAL,
	PRIMARY KEY (student,course)
);