SELECT TOP 5 * 
FROM stg_diabetic_data;

select * 
from stg_ids_mapping;

--- Add row numbering to identify the location of each section 
--- and create the 1st table named dim_admission_type

WITH RankedRows AS (
    SELECT 
        column1, 
        column2,
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS row_num
    FROM stg_ids_mapping
)
SELECT 
    CAST(column1 AS INT) AS admission_type_id,
    column2 AS description
INTO dim_admission_type
FROM RankedRows
WHERE row_num BETWEEN 2 AND 9;

SELECT * 
FROM dim_admission_type;

--- Add row numbering to identify the location of each section 
--- and create the 2nd table named dim_discharge_disposition

WITH RankedRows AS (
    SELECT 
        column1, 
        column2,
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS row_num
    FROM stg_ids_mapping
)
SELECT 
    CAST(column1 AS INT) AS discharge_disposition_id,
    column2 AS description
INTO dim_discharge_disposition
FROM RankedRows
WHERE row_num BETWEEN 12 AND 41;


select * 
from dim_discharge_disposition;


--- Add row numbering to identify the location of each section 
--- and create the 3rd table named dim_admission_source

WITH RankedRows AS (
    SELECT 
        column1, 
        column2,
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS row_num
    FROM stg_ids_mapping
)
SELECT 
    CAST(column1 AS INT) AS admission_source_id,
    column2 AS description
INTO dim_admission_source
FROM RankedRows
WHERE row_num BETWEEN 44 AND 68;

--Data Cleaning Stage

--- Approximately 49% of all patients with specialized medical care are unregistered (NULL)
SELECT TOP 10 
    medical_specialty, 
    COUNT(*) AS total_patients
FROM stg_diabetic_data
GROUP BY medical_specialty
ORDER BY total_patients DESC;


--- Create a new, clean table with this name containing the data fully prepared for analysis.

SELECT 
    encounter_id,
    patient_nbr,
    race,
    gender,
    age,
    --- Replacing "NULL" with "Unspecified" in  medical specialty
    ISNULL(medical_specialty, 'Unspecified') AS medical_specialty,
    
    --- Replacing "NULL" with "Unspecified" in Payer Code
    ISNULL(payer_code, 'Unspecified') AS payer_code,
    
    --- Other medical indicators and measurements
    time_in_hospital,
    num_lab_procedures,
    num_procedures,
    num_medications,
    number_outpatient,
    number_emergency,
    number_inpatient,
    
    --- Diagnosis and Medications
    diag_1,
    diag_2,
    diag_3,
    number_diagnoses,
    max_glu_serum,
    A1Cresult,
    change,
    diabetesMed,
    readmitted,
    
    --- Reference codes for linking to Dimensions tables
    admission_type_id,
    discharge_disposition_id,
    admission_source_id

INTO fact_diabetic_encounters
FROM stg_diabetic_data;


---Testing the validity of the Star Schema model and the purity of the data after cleaning.

/*This query performs a left join between the main fact table (fact_diabetic_encounters) 
 and the three reference tables (Dimensions) to translate ambiguous codes into clear
 and understandable medical terms */

 SELECT TOP 10 
    f.encounter_id,
    f.patient_nbr,
    f.medical_specialty,
    a.description AS admission_type_description,
    d.description AS discharge_disposition_description,
    s.description AS admission_source_description
FROM fact_diabetic_encounters f
LEFT JOIN dim_admission_type a 
    ON f.admission_type_id = a.admission_type_id
LEFT JOIN dim_discharge_disposition d 
    ON f.discharge_disposition_id = d.discharge_disposition_id
LEFT JOIN dim_admission_source s 
    ON f.admission_source_id = s.admission_source_id;


-- Exploratory Data Analysis stage

--- Calculate total encounters, unique patients, avg stay, and medical activity
SELECT 
    COUNT(encounter_id) AS total_encounters,
    COUNT(DISTINCT patient_nbr) AS total_patients,
    ROUND(AVG(CAST(time_in_hospital AS FLOAT)), 2) AS avg_days_in_hospital,
    ROUND(AVG(CAST(num_lab_procedures AS FLOAT)), 2) AS avg_lab_procedures,
    ROUND(AVG(CAST(num_medications AS FLOAT)), 2) AS avg_medications
FROM fact_diabetic_encounters;

--- Calculate total visits and percentage for each readmission category
SELECT 
    readmitted,
    COUNT(*) AS total_encounters,
    ROUND(CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS FLOAT), 2) AS percentage
FROM fact_diabetic_encounters
GROUP BY readmitted
ORDER BY total_encounters DESC;

--- Find which age brackets are most vulnerable to 30-day readmissions
SELECT 
    age,
    COUNT(*) AS total_encounters,
    
    -- Calculating the number of readmissions in less than 30 days for each age group
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    
    -- Calculating the percentage of readmissions in less than 30 days for age group
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1.0 ELSE 0 END) * 100.0 / COUNT(*) ,2) 
    AS readmit_rate_percentage

FROM fact_diabetic_encounters
GROUP BY age
ORDER BY total_encounters DESC;

--- Analyze top medical specialties driving high hospital stays and readmissions
SELECT TOP 10
    medical_specialty,
    COUNT(*) AS total_encounters,
    
    -- Average number of days of stay per specialty
    ROUND(AVG(CAST(time_in_hospital AS FLOAT)), 2) AS avg_days_in_hospital,
    
    -- Number of readmissions in less than 30 days
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    
    -- Percentage of readmission per specialty
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1.0 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS readmit_rate_percentage

FROM fact_diabetic_encounters
GROUP BY medical_specialty
ORDER BY total_encounters DESC;

--- Analyze top discharge locations and their readmission rates
SELECT TOP 10
    d.description AS discharge_location,
    COUNT(*) AS total_encounters,
    
    -- Count of readmissions under 30 days
    SUM(CASE WHEN f.readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    
    -- Readmission rate percentage for each discharge location
    ROUND(
        SUM(CASE WHEN f.readmitted = '<30' THEN 1.0 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS readmit_rate_percentage

FROM fact_diabetic_encounters f
LEFT JOIN dim_discharge_disposition d 
    ON f.discharge_disposition_id = d.discharge_disposition_id
GROUP BY d.description
ORDER BY total_encounters DESC;


