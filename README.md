USE elevatelabs;

CREATE TABLE Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    phone VARCHAR(15)
);
CREATE TABLE Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    ailment VARCHAR(100),
    doctor_id INT,                               -- Foreign key referencing Doctors table
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);
INSERT INTO Doctors (doctor_name, specialization, phone) VALUES
('Dr. Mehta', 'Cardiologist', '9876543210'),
('Dr. Sharma', 'Orthopedic', '8765432109'),
('Dr. Rao', 'Dermatologist', '7654321098');

INSERT INTO Patients (patient_name, ailment, doctor_id) VALUES
('Ananya', 'Heart Pain', 1),
('Ravi', 'Skin Allergy', 3),
('Sonia', 'Knee Pain', 2),
('Arun', 'Fever', NULL);         -- Arun hasn’t been assigned a doctor

SELECT * FROM Doctors;
SELECT * FROM Patients;

SELECT 
    p.patient_name,
    p.ailment,
    d.doctor_name,
    d.specialization
FROM Patients p
INNER JOIN Doctors d ON p.doctor_id = d.doctor_id;

SELECT 
    p.patient_name,
    p.ailment,
    d.doctor_name,
    d.specialization
FROM Patients p
LEFT JOIN Doctors d ON p.doctor_id = d.doctor_id;

SELECT 
    p.patient_name,
    p.ailment,
    d.doctor_name,
    d.specialization
FROM Patients p
RIGHT JOIN Doctors d ON p.doctor_id = d.doctor_id;
SELECT 
    p.patient_name,
    p.ailment,
    d.doctor_name,
    d.specialization
FROM Patients p
LEFT JOIN Doctors d ON p.doctor_id = d.doctor_id

UNION

SELECT 
    p.patient_name,
    p.ailment,
    d.doctor_name,
    d.specialization
FROM Patients p
RIGHT JOIN Doctors d ON p.doctor_id = d.doctor_id;     // upto here refer to the Task5 in my repository.



-- SCALAR SUBQUERIES
SELECT patient_name
FROM Patients
WHERE doctor_id = (
      SELECT doctor_id
      FROM Doctors
      ORDER BY LENGTH(doctor_name) DESC
      LIMIT 1
);
/*Outer SELECT patient_name FROM Patients WHERE doctor_id = ( ... ): we’ll return patient(s) whose doctor_id equals the single value produced by the inner query.
Inner subquery:
SELECT doctor_id FROM Doctors ORDER BY LENGTH(doctor_name) DESC LIMIT 1: returns the doctor_id of the doctor with the longest doctor_name (largest LENGTH(...)). LIMIT 1 ensures the subquery yields exactly one value — hence scalar.
Result: Patients of the doctor with the longest name.
Gotchas:
If two doctors have equal LENGTH(doctor_name) and tie for longest, ORDER BY returns one of them (no deterministic tiebreaker unless you add one).
LENGTH() returns byte-length (for multi-byte chars CHAR_LENGTH() might be more appropriate).*/



SELECT 
    doctor_name,
    (SELECT COUNT(*) FROM Patients) AS total_patients
FROM Doctors;
/*select doctor_name
total_patients: the same scalar value for every row — the total number of rows currently in Patients.

Notes:
The scalar subquery (SELECT COUNT(*) FROM Patients) is non-correlated (doesn’t reference the outer row) so the DB can compute it once and reuse it; still, semantically it returns one number.
If you want the number of patients per doctor, you’d use a correlated subquery or LEFT JOIN + GROUP BY (see below).*/



-- CORRELATED SUBQUERIES

SELECT patient_name, ailment
FROM Patients p
WHERE EXISTS (
      SELECT 1
      FROM Doctors d
      WHERE d.doctor_id = p.doctor_id
      AND d.specialization = 'Orthopedic'
);
/*FROM Patients p — alias patient table as p.
WHERE EXISTS ( ... ) — evaluates to TRUE if the inner query returns at least one row for this outer-row context.
Inner query SELECT 1 FROM Doctors d WHERE d.doctor_id = p.doctor_id AND d.specialization = 'Orthopedic':
This is correlated because it uses p.doctor_id from the outer query.
For each Patients row, it checks: "Is there a doctor whose doctor_id matches this patient’s doctor_id AND whose specialization is 'Orthopedic'?"
Result: returns patients who are assigned to an Orthopedic doctor. Arun (doctor_id NULL) will not match.*/



SELECT d.doctor_name,
       (SELECT COUNT(*) 
        FROM Patients p 
        WHERE p.doctor_id = d.doctor_id) AS patient_count
FROM Doctors d;
/*Outer query iterates over Doctors (alias d).
Correlated subquery (SELECT COUNT(*) FROM Patients p WHERE p.doctor_id = d.doctor_id) counts how many patients reference the current doctor_id. Because it references d.doctor_id, it is correlated and is executed in the context of each outer row (or logically so — optimizer may optimize).
Result: each doctor with the number of patients assigned to them.*/


-- Subqueries with IN
SELECT doctor_name
FROM Doctors
WHERE doctor_id IN (
      SELECT doctor_id
      FROM Patients
      WHERE doctor_id IS NOT NULL
);
/*What it does: The inner query returns all non-NULL doctor_id values present in Patients. The outer query returns doctor_name for doctors whose doctor_id is in that list — i.e., doctors who have at least one patient.
Notes: doctor_id IS NOT NULL is used to avoid NULL appearing in the IN list (NULLs in IN lists are tricky). IN works like: check membership in the returned list.*/

-- Find patients whose doctor is either ‘Dr. Mehta’ or ‘Dr. Sharma’
SELECT patient_name, ailment
FROM Patients
WHERE doctor_id IN (
      SELECT doctor_id
      FROM Doctors
      WHERE doctor_name IN ('Dr. Mehta', 'Dr. Sharma')
);
/*Inner subquery selects doctor_id values of doctors named 'Dr. Mehta' or 'Dr. Sharma'. Outer query returns patients whose doctor_id is in that set — i.e., patients of those two doctors.
Notes: This is a two-level IN. Alternatively you could do a JOIN:*/

-- Subqueries with EXISTS
SELECT doctor_name
FROM Doctors d
WHERE EXISTS (
      SELECT 1
      FROM Patients p
      WHERE p.doctor_id = d.doctor_id
);
/*What it does: For each doctor d, the correlated subquery checks if there exists at least one Patients row with p.doctor_id = d.doctor_id. If yes, that doctor_name is included.
Result: doctors who currently have at least one patient. EXISTS is often efficient because the subquery can stop as soon as it finds one matching row.*/


SELECT patient_name
FROM Patients p
WHERE EXISTS (
      SELECT 1
      FROM Doctors d
      WHERE d.doctor_id = p.doctor_id
);
/*For each patient p, checks that a matching doctor exists in Doctors. Returns patients who have a valid doctor record.
Notes: Because of the foreign-key constraint, a non-NULL doctor_id should normally always match a doctor (unless referential integrity was temporarily broken). So this query is mainly useful if you suspect orphaned references or to filter out NULL doctor_id cases.*/


-- Subqueries with =
SELECT patient_name, ailment
FROM Patients
WHERE doctor_id = (
      SELECT MIN(doctor_id) FROM Doctors
);
/*Inner subquery SELECT MIN(doctor_id) FROM Doctors returns the smallest doctor_id value in the Doctors table (usually the earliest inserted doctor). Outer query selects patients whose doctor_id equals that value.
Caveat: If the Doctors table is empty, the subquery returns NULL and doctor_id = NULL is false, so no rows are returned. If the subquery returns multiple rows (it shouldn’t here), you’ll get an error — = expects a single scalar value.*/

SELECT specialization
FROM Doctors
WHERE doctor_id = (
      SELECT doctor_id
      FROM Patients
      WHERE patient_name = 'Ananya'
);
/*Inner subquery: SELECT doctor_id FROM Patients WHERE patient_name = 'Ananya' — attempts to return the doctor_id assigned to patient Ananya.
Outer query: SELECT specialization FROM Doctors WHERE doctor_id = (<that value>) — finds the specialization of Ananya’s doctor.
