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
RIGHT JOIN Doctors d ON p.doctor_id = d.doctor_id;
-- SCALAR SUBQUERIES
SELECT patient_name
FROM Patients
WHERE doctor_id = (
      SELECT doctor_id
      FROM Doctors
      ORDER BY LENGTH(doctor_name) DESC
      LIMIT 1
);
SELECT 
    doctor_name,
    (SELECT COUNT(*) FROM Patients) AS total_patients
FROM Doctors;
-- CORRELATED SUBQUERIES
SELECT patient_name, ailment
FROM Patients p
WHERE EXISTS (
      SELECT 1
      FROM Doctors d
      WHERE d.doctor_id = p.doctor_id
      AND d.specialization = 'Orthopedic'
);

SELECT d.doctor_name,
       (SELECT COUNT(*) 
        FROM Patients p 
        WHERE p.doctor_id = d.doctor_id) AS patient_count
FROM Doctors d;

-- Subqueries with IN
SELECT doctor_name
FROM Doctors
WHERE doctor_id IN (
      SELECT doctor_id
      FROM Patients
      WHERE doctor_id IS NOT NULL
);

-- Find patients whose doctor is either ‘Dr. Mehta’ or ‘Dr. Sharma’
SELECT patient_name, ailment
FROM Patients
WHERE doctor_id IN (
      SELECT doctor_id
      FROM Doctors
      WHERE doctor_name IN ('Dr. Mehta', 'Dr. Sharma')
);

-- Subqueries with EXISTS
SELECT doctor_name
FROM Doctors d
WHERE EXISTS (
      SELECT 1
      FROM Patients p
      WHERE p.doctor_id = d.doctor_id
);

SELECT patient_name
FROM Patients p
WHERE EXISTS (
      SELECT 1
      FROM Doctors d
      WHERE d.doctor_id = p.doctor_id
);
-- Subqueries with =
SELECT patient_name, ailment
FROM Patients
WHERE doctor_id = (
      SELECT MIN(doctor_id) FROM Doctors
);

SELECT specialization
FROM Doctors
WHERE doctor_id = (
      SELECT doctor_id
      FROM Patients
      WHERE patient_name = 'Ananya'
);