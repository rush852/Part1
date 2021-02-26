CREATE TABLE Programs(
	name TEXT NOT NULL PRIMARY KEY,
	abbr TEXT NOT NULL
);
CREATE TABLE Departments(
	name TEXT NOT NULL PRIMARY KEY,
	abbr TEXT NOT NULL UNIQUE
);
CREATE TABLE ProgramDepartments(
	program TEXT NOT NULL REFERENCES Programs (name),
	department TEXT NOT NULL REFERENCES Departments (name),
	PRIMARY KEY (program,department)
);
CREATE TABLE Students(
	idnr VARCHAR(10) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	login TEXT NOT NULL UNIQUE,
	program TEXT NOT NULL REFERENCES Programs,
	UNIQUE (idnr,program) 
);
CREATE TABLE Branches(
	name TEXT NOT NULL,
	program TEXT NOT NULL REFERENCES Programs,
	PRIMARY KEY (name,program)
);
CREATE TABLE Courses(
	code CHAR(6) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,  
	credits FLOAT NOT NULL,
	department TEXT NOT NULL REFERENCES Departments
);
CREATE TABLE Prerequisites(
	course CHAR(6) REFERENCES Courses (code),
	prerequisite CHAR(6) REFERENCES Courses (code),
	PRIMARY KEY (course,prerequisite)
);
CREATE TABLE LimitedCourses(
	code CHAR(6) NOT NULL PRIMARY KEY REFERENCES Courses,
	capacity INTEGER NOT NULL
);
CREATE TABLE StudentBranches(
	student TEXT NOT NULL PRIMARY KEY REFERENCES Students,
	branch TEXT NOT NULL,
	program TEXT NOT NULL,
	FOREIGN KEY (student, program) REFERENCES Students(idnr,program), 
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
	UNIQUE (position,course),
	PRIMARY KEY (student,course)
);


CREATE VIEW BasicInformation AS(
	SELECT idnr,name,login,students.program,branch 
	FROM students
	LEFT JOIN studentbranches
	ON students.idnr = studentbranches.student
	ORDER BY idnr ASC
);
CREATE VIEW FinishedCourses AS(
	SELECT student,course,grade,credits FROM taken
	LEFT JOIN courses
	ON courses.code = taken.course
);
CREATE VIEW PassedCourses AS(
	SELECT student,course,credits FROM finishedcourses
	WHERE grade != 'U'
);
CREATE VIEW Registrations AS(
	SELECT student,course,'registered' AS status FROM registered
	UNION
	SELECT student,course,'waiting' AS status FROM waitinglist
	ORDER BY student ASC
);

CREATE VIEW UnreadMandatory AS (
	SELECT idnr AS student,course FROM students
	LEFT JOIN mandatoryprogram
	ON students.program  = mandatoryprogram.program
	WHERE course IS NOT NULL
	UNION
	SELECT student,course FROM studentbranches
	LEFT JOIN mandatorybranch
	ON studentbranches.program = mandatorybranch.program 
	AND studentbranches.branch = mandatorybranch.branch
	WHERE course IS NOT NULL
	EXCEPT 
	SELECT student,course FROM passedcourses
	);
CREATE VIEW pathToGraduation AS (
WITH 
totalcredits AS (SELECT idnr,COALESCE(sum(passedcourses.credits),0) AS totalCredits FROM students
LEFT JOIN passedcourses
ON students.idnr = passedcourses.student
GROUP BY idnr
ORDER BY idnr),

mandatoryleft AS (SELECT students.idnr,COALESCE(count(unreadmandatory.student),0) AS mandatoryLeft FROM students
LEFT JOIN unreadmandatory
ON students.idnr = unreadmandatory.student
GROUP BY students.idnr
ORDER BY students.idnr),

mathcredits AS (SELECT student, COALESCE(sum(passedcourses.credits),0) AS mathCredits FROM passedcourses, classified
WHERE classified.classification = 'math'  AND passedcourses.course = classified.course
GROUP BY student
UNION
SELECT idnr, 0 AS mathCredits FROM students
EXCEPT 
SELECT student,0 AS mathCredits FROM passedcourses
ORDER BY student),

research AS (SELECT student, COALESCE(sum(passedcourses.credits),0) AS researchCredits FROM passedcourses, classified
WHERE classified.classification = 'research'  AND passedcourses.course = classified.course
GROUP BY student
UNION
SELECT idnr, 0 AS researchCredits FROM students
EXCEPT 
SELECT student,0 AS researchCredits FROM passedcourses
ORDER BY student),

seminar AS (SELECT student, COALESCE(count(passedcourses.credits),0) AS seminarCourses FROM passedcourses, classified
WHERE classified.classification = 'seminar'  AND passedcourses.course = classified.course
GROUP BY student
UNION
SELECT idnr, 0 AS seminarCourses FROM students
EXCEPT 
SELECT student,0 AS seminarCourses FROM passedcourses
ORDER BY student),

recommended AS(SELECT student,course FROM studentbranches
LEFT JOIN recommendedbranch
ON recommendedbranch.branch = studentbranches.branch AND
recommendedbranch.program = studentbranches.program),
recommendedCredits AS(
SELECT passedcourses.student,passedcourses.credits FROM passedcourses,recommended
WHERE passedcourses.student = recommended.student
AND passedcourses.course = recommended.course
UNION
SELECT idnr, 0 AS credits FROM students
EXCEPT 
SELECT passedcourses.student, 0 AS credits FROM passedcourses,recommended
WHERE passedcourses.student = recommended.student
AND passedcourses.course = recommended.course
ORDER BY student ASC),

qualifiedTrue AS (SELECT totalcredits.idnr , TRUE AS qualified FROM totalcredits,mathcredits,research,seminar,mandatoryleft,recommendedCredits
WHERE 
(totalcredits.idnr = mathcredits.student AND mathcredits >= 20)
AND
(totalcredits.idnr = research.student AND researchCredits >=10)
AND
(totalcredits.idnr = seminar.student AND seminarcourses >=1)
AND
(totalcredits.idnr = mandatoryleft.idnr AND mandatoryleft = 0
AND
totalcredits.idnr = recommendedCredits.student AND recommendedCredits.credits >= 10)
GROUP BY totalcredits.idnr),

qualified AS (
SELECT idnr,qualified FROM qualifiedtrue
UNION 
SELECT idnr, FALSE AS qualified FROM students
EXCEPT
SELECT idnr, FALSE AS qualified FROM qualifiedTrue)

SELECT totalcredits.idnr AS student,totalcredits.totalcredits,mandatoryleft.mandatoryleft,
COALESCE(mathcredits.mathCredits,0) AS mathCredits,COALESCE(research.researchCredits,0) AS researchCredits,COALESCE(seminar.seminarcourses,0) AS seminarcourses,qualified.qualified
FROM totalcredits
LEFT JOIN mandatoryleft
ON totalcredits.idnr = mandatoryleft.idnr
LEFT JOIN mathcredits
ON totalcredits.idnr = mathcredits.student
LEFT JOIN research
ON totalcredits.idnr = research.student
LEFT JOIN seminar
ON totalcredits.idnr = seminar.student
LEFT JOIN qualified
ON totalcredits.idnr = qualified.idnr
);
	

INSERT INTO Departments VALUES ('Dep1', 'D1');
INSERT INTO Departments VALUES ('Dep2', 'D2');

INSERT INTO Programs VALUES ('Prog1', 'P1');
INSERT INTO Programs VALUES ('Prog2', 'P2');

INSERT INTO Students VALUES ('1111111111', 'N1', 'ls1', 'Prog1');
INSERT INTO Students VALUES ('2222222222', 'N2', 'ls2', 'Prog1');
INSERT INTO Students VALUES ('3333333333', 'N3', 'ls3', 'Prog2');

INSERT INTO Courses VALUES ('CCC111', 'C1', 22.5, 'Dep1');
INSERT INTO Courses VALUES ('CCC222', 'C2', 20,   'Dep1');
INSERT INTO Courses VALUES ('CCC333', 'C3', 30,   'Dep1');
INSERT INTO Courses VALUES ('CCC444', 'C4', 25,   'Dep1');
INSERT INTO Courses VALUES ('CCC555', 'C5', 25,   'Dep1');
INSERT INTO Courses VALUES ('CCC666', 'C6', 20,   'Dep1');

INSERT INTO Prerequisites VALUES ('CCC333', 'CCC111');

INSERT INTO LimitedCourses VALUES ('CCC111',1);
INSERT INTO LimitedCourses VALUES ('CCC222',2);
INSERT INTO LimitedCourses VALUES ('CCC555',0);
INSERT INTO LimitedCourses VALUES ('CCC666',1);

INSERT INTO Registered VALUES ('1111111111', 'CCC666');
INSERT INTO Registered VALUES ('3333333333', 'CCC666');
INSERT INTO Waitinglist VALUES ('2222222222', 'CCC666');

INSERT INTO Taken VALUES ('2222222222', 'CCC222', 4);
INSERT INTO Taken VALUES ('2222222222', 'CCC111', 5);