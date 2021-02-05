CREATE TABLE Students(
	idnr VARCHAR(10) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	login TEXT NOT NULL,
	program TEXT NOT NULL
);
CREATE TABLE Branches(
	name TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY (name,program)
);
CREATE TABLE Courses(
	code TEXT NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	credits FLOAT NOT NULL,
	department TEXT NOT NULL
);
CREATE TABLE LimitedCourses(
	code TEXT NOT NULL PRIMARY KEY REFERENCES Courses,
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
	program TEXT NOT NULL,
	PRIMARY KEY (course,program)
);
CREATE TABLE MandatoryBranch(
	course TEXT NOT NULL REFERENCES Courses (code),
	branch TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY (course,branch,program),
	FOREIGN KEY (branch,program) REFERENCES Branches (name,program)
);
CREATE TABLE RecommendedBranch(
	course TEXT NOT NULL REFERENCES Courses (code),
	branch TEXT NOT NULL,
	program TEXT NOT NULL,
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
	grade CHAR NOT NULL check (grade = 'U' OR grade = '3' OR grade = '4' OR grade = '5'),
	PRIMARY KEY (student,course)
);
CREATE TABLE WaitingList(
	student VARCHAR(10) NOT NULL REFERENCES Students (idnr),
	course TEXT NOT NULL REFERENCES Limitedcourses (code),
	position SERIAL,
	PRIMARY KEY (student,course)
);