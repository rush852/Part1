CREATE VIEW CourseQueuePositions AS(
	SELECT student, course, position AS place FROM Waitinglist
);

CREATE FUNCTION try_register() RETURNS trigger AS $$
    BEGIN
		IF EXISTS (SELECT * FROM Registrations 
				   WHERE student = NEW.student AND course = NEW.course)
		THEN RAISE EXCEPTION 'Already Registered';
		END IF;
        -- Checks for prerequisites
        IF EXISTS (SELECT prerequisite FROM Prerequisites
				  WHERE course = NEW.course
				  EXCEPT
				  SELECT course FROM passedcourses
				  WHERE student = NEW.student)
		THEN RAISE EXCEPTION 'prerequisites missing';
		END IF;

        -- Check if the course is full.
        IF NEW.COURSE IN (SELECT LimitedCourses.code FROM LimitedCourses)
            AND 
			(
                (SELECT COUNT(DISTINCT Registered.student) FROM Registered
                WHERE Registered.course = NEW.Course)
                >=
                (SELECT capacity FROM LimitedCourses
                WHERE LimitedCourses.code = NEW.course)
            )
        THEN
            -- Course full, insert into waitinglist
            INSERT INTO WaitingList VALUES (NEW.student, NEW.course,(SELECT COUNT (*) + 1
																	FROM Waitinglist
																	WHERE NEW.course = course));
        ELSE
            -- Course not full, insert into registered
            INSERT INTO Registered VALUES (NEW.student, NEW.course);
        END IF;
        RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER register_to_course INSTEAD OF INSERT ON Registrations 
    FOR EACH ROW EXECUTE FUNCTION try_register();


CREATE  FUNCTION unregister_from_course() RETURNS TRIGGER AS $$
	DECLARE
		--First person in waitlist or NULL.
		first_in_queue TEXT = (SELECT student FROM CourseQueuePositions
				 WHERE course = OLD.course AND place = 1);
		currentpos INTEGER = (SELECT place FROM CourseQueuePositions
				 WHERE course = OLD.course AND student = OLD.student);
	BEGIN
		-- Check if student is in waitinglist
		IF OLD.student IN
			(SELECT coursequeuepositions.student FROM coursequeuepositions
			 WHERE  coursequeuepositions.course = OLD.course)
		THEN 
		-- Delete student from list, and decrease the position for everyone behind 
			DELETE FROM Waitinglist WHERE student = OLD.student AND course = OLD.course;
			UPDATE waitinglist
			SET position = position-1
			WHERE course = OLD.course AND position > currentpos;
			RETURN NULL;
		END IF;
		-- Check if student is registered
		IF OLD.student IN(SELECT Registered.student FROM registered WHERE registered.course = OLD.course)
		THEN
			-- Deletes student form registered
			DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
			-- Checks if there is room for new student to be registered from waitinglist
			IF OLD.course IN (SELECT LimitedCourses.code FROM LimitedCourses)
			AND (SELECT COUNT(Registered.student) FROM Registered
				WHERE Registered.course = OLD.course)
				<
				(SELECT capacity FROM LimitedCourses
				WHERE LimitedCourses.code = OLD.course)
			AND first_in_queue IS NOT NULL 
			THEN
				DELETE FROM WaitingList WHERE student = first_in_queue AND course = OLD.course;
				INSERT INTO Registered VALUES (first_in_queue, OLD.course);
			END IF;
		END IF;
		RETURN NULL;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER unregister_from_course INSTEAD OF DELETE ON Registrations 
    FOR EACH ROW EXECUTE FUNCTION unregister_from_course();