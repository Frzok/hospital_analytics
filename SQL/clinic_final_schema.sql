-- ========================================
-- FINAL SQL PACKAGE FOR HOSPITAL ANALYTICS
-- Includes: PK, FK, Indexes, Views
-- ========================================

-- === PRIMARY KEYS ===
ALTER TABLE Ref_Doctor ADD CONSTRAINT PK_RefDoctor PRIMARY KEY (Doctor_ID);
ALTER TABLE Ref_Patient ADD CONSTRAINT PK_RefPatient PRIMARY KEY (Patient_ID);
ALTER TABLE Ref_Diagnosis ADD CONSTRAINT PK_RefDiagnosis PRIMARY KEY (Diagnosis_Code);

-- === FOREIGN KEYS ===
ALTER TABLE Fact_Inpatient ADD CONSTRAINT FK_Inpatient_Patient FOREIGN KEY (Patient_ID) REFERENCES Ref_Patient(Patient_ID);
ALTER TABLE Fact_Inpatient ADD CONSTRAINT FK_Inpatient_Doctor FOREIGN KEY (Doctor_ID) REFERENCES Ref_Doctor(Doctor_ID);
ALTER TABLE Fact_Inpatient ADD CONSTRAINT FK_Inpatient_Department FOREIGN KEY (Department_ID) REFERENCES Ref_Department(Department_ID);
ALTER TABLE Fact_Inpatient ADD CONSTRAINT FK_Inpatient_Diagnosis FOREIGN KEY (Diagnos_ID) REFERENCES Ref_Diagnosis(Diagnosis_Code);

ALTER TABLE Fact_Outpatient ADD CONSTRAINT FK_Outpatient_Patient FOREIGN KEY (Patient_ID) REFERENCES Ref_Patient(Patient_ID);
ALTER TABLE Fact_Outpatient ADD CONSTRAINT FK_Outpatient_Doctor FOREIGN KEY (Doctor_ID) REFERENCES Ref_Doctor(Doctor_ID);
ALTER TABLE Fact_Outpatient ADD CONSTRAINT FK_Outpatient_Department FOREIGN KEY (Department_ID) REFERENCES Ref_Department(Department_ID);
ALTER TABLE Fact_Outpatient ADD CONSTRAINT FK_Outpatient_Diagnosis FOREIGN KEY (Diagnosis_ID) REFERENCES Ref_Diagnosis(Diagnosis_Code);

ALTER TABLE Fact_Lab ADD CONSTRAINT FK_Lab_Patient FOREIGN KEY (Patient_ID) REFERENCES Ref_Patient(Patient_ID);
ALTER TABLE Fact_Lab ADD CONSTRAINT FK_Lab_Doctor FOREIGN KEY (Doctor_ID) REFERENCES Ref_Doctor(Doctor_ID);
ALTER TABLE Fact_Lab ADD CONSTRAINT FK_Lab_Diagnosis FOREIGN KEY (Diagnosis_ID) REFERENCES Ref_Diagnosis(Diagnosis_Code);

ALTER TABLE Ref_Doctor ADD CONSTRAINT FK_Doctor_Specialty FOREIGN KEY (Specialty_ID) REFERENCES Ref_Specialty(Specialty_ID);

-- === INDEXES ===
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Inpatient_Patient_ID_Admission_Date' AND object_id = OBJECT_ID('Fact_Inpatient')
)
CREATE INDEX IX_Fact_Inpatient_Patient_ID_Admission_Date ON Fact_Inpatient (Patient_ID, Admission_Date);

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Outpatient_Patient_ID_Visit_Date' AND object_id = OBJECT_ID('Fact_Outpatient')
)
CREATE INDEX IX_Fact_Outpatient_Patient_ID_Visit_Date ON Fact_Outpatient (Patient_ID, Visit_Date);

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Lab_Patient_ID_Assigned_Date' AND object_id = OBJECT_ID('Fact_Lab')
)
CREATE INDEX IX_Fact_Lab_Patient_ID_Assigned_Date ON Fact_Lab (Patient_ID, Assigned_Date);

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Inpatient_Doctor_ID' AND object_id = OBJECT_ID('Fact_Inpatient')
)
CREATE INDEX IX_Fact_Inpatient_Doctor_ID ON Fact_Inpatient (Doctor_ID);

-- === VIEWS ===
-- vw_Outpatient
CREATE VIEW [dbo].[vw_Outpatient] AS
SELECT
    f.Visit_Date,
    CAST(f.Patient_ID AS NVARCHAR) AS Patient_ID,
    p.Sex,
    p.BirthDate,
    DATEDIFF(YEAR, p.BirthDate, f.Visit_Date) AS Age,
    CASE 
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Visit_Date) < 18 THEN '0Ц17'
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Visit_Date) BETWEEN 18 AND 35 THEN '18Ц35'
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Visit_Date) BETWEEN 36 AND 50 THEN '36Ц50'
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Visit_Date) BETWEEN 51 AND 65 THEN '51Ц65'
        ELSE '65+'
    END AS Age_Group,
    CAST(f.Doctor_ID AS NVARCHAR) AS Doctor_ID,
    CAST(d.Specialty_ID AS NVARCHAR) AS Specialty_ID,
    s.Specialty_Name,
    CAST(f.Diagnosis_ID AS NVARCHAR) AS Diagnosis_Code,
    dx.Diagnosis_Group_Name AS Diagnosis_Name,
    dx.Diagnosis_Group_ID,
    icd.ICD_Group_Name,

    -- ƒата дл€ агрегации по мес€цам
    (CAST(YEAR(f.Visit_Date) AS varchar(4)) + '-' +
     RIGHT('0' + CAST(MONTH(f.Visit_Date) AS varchar(2)), 2)) AS YearMonth,

    (CAST(YEAR(f.Visit_Date) AS INT) * 100 + CAST(MONTH(f.Visit_Date) AS INT)) AS YearMonthNum,

    CAST(CAST(YEAR(f.Visit_Date) AS varchar(4)) + '-' +
         RIGHT('0' + CAST(MONTH(f.Visit_Date) AS varchar(2)), 2) + '-01'
         AS DATE) AS YearMonthDate,
    DATEPART(WEEKDAY, f.Visit_Date) AS WeekdayNumber,
    -- Ќомер мес€ца
MONTH(f.Visit_Date) AS MonthNumber, -- число 1Ц12
CASE MONTH(f.Visit_Date)
    WHEN 1 THEN N'январь'
    WHEN 2 THEN N'‘евраль'
    WHEN 3 THEN N'ћарт'
    WHEN 4 THEN N'јпрель'
    WHEN 5 THEN N'ћай'
    WHEN 6 THEN N'»юнь'
    WHEN 7 THEN N'»юль'
    WHEN 8 THEN N'јвгуст'
    WHEN 9 THEN N'—ент€брь'
    WHEN 10 THEN N'ќкт€брь'
    WHEN 11 THEN N'Ќо€брь'
    WHEN 12 THEN N'ƒекабрь'
END AS MonthName

FROM Fact_Outpatient f
LEFT JOIN Ref_Patient p ON f.Patient_ID = p.Patient_ID
LEFT JOIN Ref_Doctor d ON f.Doctor_ID = d.Doctor_ID
LEFT JOIN Ref_Specialty s ON d.Specialty_ID = s.Specialty_ID
LEFT JOIN Ref_Diagnosis dx ON f.Diagnosis_ID = dx.Diagnosis_Code
LEFT JOIN Ref_ICD_Groups icd 
    ON SUBSTRING(dx.Diagnosis_Group_ID, 1, 3) BETWEEN icd.ICD_Start AND icd.ICD_End
WHERE
    f.Visit_Date >= '2021-03-03'
    AND f.Diagnosis_ID IS NOT NULL AND f.Diagnosis_ID <> 0
    AND s.Specialty_Name IS NOT NULL
    AND dx.Diagnosis_Group_Name IS NOT NULL;
GO



-- vw_Inpatient

CREATE VIEW [dbo].[vw_Inpatient] AS
SELECT
    f.Admission_Date,
    f.Discharge_Date,                -- исправлено
    CAST(f.Patient_ID AS NVARCHAR) AS Patient_ID,
    p.Sex,
    p.BirthDate,                     -- исправлено
    DATEDIFF(YEAR, p.BirthDate, f.Admission_Date) AS Age,
    CASE 
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Admission_Date) < 18 THEN '0Ц17'
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Admission_Date) BETWEEN 18 AND 35 THEN '18Ц35'
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Admission_Date) BETWEEN 36 AND 50 THEN '36Ц50'
        WHEN DATEDIFF(YEAR, p.BirthDate, f.Admission_Date) BETWEEN 51 AND 65 THEN '51Ц65'
        ELSE '65+'
    END AS Age_Group,
    CAST(f.Doctor_ID AS NVARCHAR) AS Doctor_ID,
    CAST(d.Specialty_ID AS NVARCHAR) AS Specialty_ID,
    s.Specialty_Name,
    CAST(f.Diagnos_ID AS NVARCHAR) AS Diagnosis_Code,
    dx.Diagnosis_Group_Name AS Diagnosis_Name,
    dx.Diagnosis_Group_ID,
    icd.ICD_Group_Name,
    CAST(f.Department_ID AS NVARCHAR) AS Department_ID,
    dept.Department_Name,
    f.Bed_Days AS BedDays,
    f.Admission_Type,
    CASE 
        WHEN f.Admission_Type = 1 THEN N'плановое'
        WHEN f.Admission_Type = 2 THEN N'экстренное'
        ELSE N'неизвестно'
    END AS Admission_Type_Name,
(CAST(YEAR(f.Admission_Date) AS varchar(4)) + '-' +
 RIGHT('0' + CAST(MONTH(f.Admission_Date) AS varchar(2)), 2)) AS YearMonth,
(CAST(YEAR(f.Admission_Date) AS INT) * 100 + CAST(MONTH(f.Admission_Date) AS INT)) AS YearMonthNum,
CAST(CAST(YEAR(f.Admission_Date) AS varchar(4)) + '-' +
     RIGHT('0' + CAST(MONTH(f.Admission_Date) AS varchar(2)), 2) + '-01'
     AS DATE) AS YearMonthDate
FROM Fact_Inpatient f
LEFT JOIN Ref_Patient p ON f.Patient_ID = p.Patient_ID
LEFT JOIN Ref_Doctor d ON f.Doctor_ID = d.Doctor_ID
LEFT JOIN Ref_Specialty s ON d.Specialty_ID = s.Specialty_ID
LEFT JOIN Ref_Diagnosis dx ON f.Diagnos_ID = dx.Diagnosis_Code
LEFT JOIN Ref_ICD_Groups icd 
    ON SUBSTRING(dx.Diagnosis_Group_ID, 1, 3) BETWEEN icd.ICD_Start AND icd.ICD_End
LEFT JOIN Ref_Department dept ON f.Department_ID = dept.Department_ID
WHERE
    f.Doctor_ID IS NOT NULL
    AND f.Admission_Type IS NOT NULL
    AND s.Specialty_Name IS NOT NULL
	AND dx.Diagnosis_Group_Name IS NOT NULL
;
GO



-- vw_Laboratory

CREATE VIEW [dbo].[vw_Laboratory] AS
SELECT
    -- ƒата назначени€ и выполнени€ анализа (date)
    TRY_CAST(f.Assigned_Date AS DATE) AS Assigned_Date,
    TRY_CAST(f.Performed_Date AS DATE) AS Performed_Date,

    -- √руппировка по мес€цам/годам (назначение)
    (CAST(YEAR(f.Assigned_Date) AS varchar(4)) + '-' +
     RIGHT('0' + CAST(MONTH(f.Assigned_Date) AS varchar(2)), 2)) AS Assigned_YearMonth,

    (CAST(YEAR(f.Assigned_Date) AS INT) * 100 + CAST(MONTH(f.Assigned_Date) AS INT)) AS Assigned_YearMonthNum,

    CAST(CAST(YEAR(f.Assigned_Date) AS varchar(4)) + '-' +
         RIGHT('0' + CAST(MONTH(f.Assigned_Date) AS varchar(2)), 2) + '-01'
         AS DATE) AS Assigned_YearMonthDate,

    DATEPART(WEEKDAY, f.Assigned_Date) AS Assigned_WeekdayNumber,

    MONTH(f.Assigned_Date) AS Assigned_MonthNumber,

    CASE MONTH(f.Assigned_Date)
        WHEN 1 THEN N'январь'
        WHEN 2 THEN N'‘евраль'
        WHEN 3 THEN N'ћарт'
        WHEN 4 THEN N'јпрель'
        WHEN 5 THEN N'ћай'
        WHEN 6 THEN N'»юнь'
        WHEN 7 THEN N'»юль'
        WHEN 8 THEN N'јвгуст'
        WHEN 9 THEN N'—ент€брь'
        WHEN 10 THEN N'ќкт€брь'
        WHEN 11 THEN N'Ќо€брь'
        WHEN 12 THEN N'ƒекабрь'
        ELSE N'Ќеизвестно'
    END AS Assigned_MonthName,

    -- јналогично дл€ даты выполнени€ (Performed_Date)
    (CAST(YEAR(f.Performed_Date) AS varchar(4)) + '-' +
     RIGHT('0' + CAST(MONTH(f.Performed_Date) AS varchar(2)), 2)) AS Performed_YearMonth,

    (CAST(YEAR(f.Performed_Date) AS INT) * 100 + CAST(MONTH(f.Performed_Date) AS INT)) AS Performed_YearMonthNum,

    CAST(CAST(YEAR(f.Performed_Date) AS varchar(4)) + '-' +
         RIGHT('0' + CAST(MONTH(f.Performed_Date) AS varchar(2)), 2) + '-01'
         AS DATE) AS Performed_YearMonthDate,

    DATEPART(WEEKDAY, f.Performed_Date) AS Performed_WeekdayNumber,

    MONTH(f.Performed_Date) AS Performed_MonthNumber,

    CASE MONTH(f.Performed_Date)
        WHEN 1 THEN N'январь'
        WHEN 2 THEN N'‘евраль'
        WHEN 3 THEN N'ћарт'
        WHEN 4 THEN N'јпрель'
        WHEN 5 THEN N'ћай'
        WHEN 6 THEN N'»юнь'
        WHEN 7 THEN N'»юль'
        WHEN 8 THEN N'јвгуст'
        WHEN 9 THEN N'—ент€брь'
        WHEN 10 THEN N'ќкт€брь'
        WHEN 11 THEN N'Ќо€брь'
        WHEN 12 THEN N'ƒекабрь'
        ELSE N'Ќеизвестно'
    END AS Performed_MonthName,

    -- ѕациент и демографи€
    ISNULL(CAST(f.Patient_ID AS NVARCHAR), '0') AS Patient_ID,
    ISNULL(p.Sex, 'unknown') AS Sex,
    ISNULL(CAST(p.BirthDate AS NVARCHAR), '1900-01-01') AS BirthDate,
    DATEDIFF(YEAR, TRY_CAST(p.BirthDate AS DATE), TRY_CAST(f.Assigned_Date AS DATE)) AS Age,
    CASE 
        WHEN DATEDIFF(YEAR, TRY_CAST(p.BirthDate AS DATE), TRY_CAST(f.Assigned_Date AS DATE)) < 18 THEN '0Ц17'
        WHEN DATEDIFF(YEAR, TRY_CAST(p.BirthDate AS DATE), TRY_CAST(f.Assigned_Date AS DATE)) BETWEEN 18 AND 35 THEN '18Ц35'
        WHEN DATEDIFF(YEAR, TRY_CAST(p.BirthDate AS DATE), TRY_CAST(f.Assigned_Date AS DATE)) BETWEEN 36 AND 50 THEN '36Ц50'
        WHEN DATEDIFF(YEAR, TRY_CAST(p.BirthDate AS DATE), TRY_CAST(f.Assigned_Date AS DATE)) BETWEEN 51 AND 65 THEN '51Ц65'
        ELSE '65+'
    END AS Age_Group,

    -- ¬рач и специальность
    ISNULL(CAST(f.Doctor_ID AS NVARCHAR), '0') AS Doctor_ID,
    ISNULL(CAST(d.Specialty_ID AS NVARCHAR), '0') AS Specialty_ID,
    ISNULL(s.Specialty_Name, 'unknown') AS Specialty_Name,

    -- ƒиагнозы и группы
    ISNULL(CAST(f.Diagnosis_ID AS NVARCHAR), '0') AS Diagnosis_ID,
    ISNULL(CAST(dx.Diagnosis_Name AS NVARCHAR), 'unknown') AS Diagnosis_Name,
    ISNULL(CAST(dx.Diagnosis_Group_ID AS NVARCHAR), 'unknown') AS Diagnosis_Group_ID,
    ISNULL(CAST(icd.ICD_Group_Name AS NVARCHAR), 'unknown') AS ICD_Group_Name,

    --  од анализа
    ISNULL(CAST(f.ACHI_Code AS NVARCHAR), 'unknown') AS ACHI_Code

FROM Fact_Lab f
LEFT JOIN Ref_Patient p ON f.Patient_ID = p.Patient_ID
LEFT JOIN Ref_Doctor d ON f.Doctor_ID = d.Doctor_ID
LEFT JOIN Ref_Specialty s ON d.Specialty_ID = s.Specialty_ID
LEFT JOIN Ref_Diagnosis dx ON f.Diagnosis_ID = dx.Diagnosis_Group_ID
LEFT JOIN Ref_ICD_Groups icd ON dx.Diagnosis_Group_ID BETWEEN icd.ICD_Start AND icd.ICD_End
WHERE
    dx.Diagnosis_Name IS NOT NULL
    AND dx.Diagnosis_Group_ID IS NOT NULL
    AND icd.ICD_Group_Name IS NOT NULL
    AND f.ACHI_Code <> 'unknown'
;
GO


