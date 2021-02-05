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
mathcredits.mathCredits,research.researchCredits,COALESCE(seminar.seminarcourses,0) AS seminarcourses,qualified.qualified
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
	
	


