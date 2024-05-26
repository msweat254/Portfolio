-- CREATE OR REPLACE VIEW IonSF.MarchMadnessTableR1 AS 
with R1Matchups as (
select
    a.Setter AS Setter_A,
    a.Setter_Region AS Region_A,
    a.Seeding_Total_Points AS Seeding_Total_Points_A,
    a.Seed AS Seed_A,
    a.Division AS Division_A,
    a.R1_Total_Points AS R1_Total_Points_A,
    b.Division AS Division_B,
    b.Setter AS Setter_B,
    b.Setter_Region AS Region_B,
    b.Seeding_Total_Points AS Seeding_Total_Points_B,
    b.Seed AS Seed_B,
    b.R1_Total_Points AS R1_Total_Points_B
from
    IonSF.MarchMadnessSeeding a
join IonSF.MarchMadnessSeeding b on a.Setter_Region = b.Setter_Region and a.Division = b.Division and (a.Seed + b.Seed = 65)
where
    (a.Seed < b.Seed)),
R1Winner as (
select
    Setter_A AS Setter_A,
    Region_A AS Region_A,
    Seeding_Total_Points_A AS Seeding_Total_Points_A,
    Seed_A AS Seed_A,
    Division_A AS Division_A,
    R1_Total_Points_A AS R1_Total_Points_A,
    Division_B AS Division_B,
    Setter_B AS Setter_B,
    Region_B AS Region_B,
    Seeding_Total_Points_B AS Seeding_Total_Points_B,
    Seed_B AS Seed_B,
    R1_Total_Points_B AS R1_Total_Points_B,
    (case
        when (R1Matchups.R1_Total_Points_A > R1Matchups.R1_Total_Points_B) then R1Matchups.Setter_A
        else R1Matchups.Setter_B
    end) AS R1Winner
from
    R1Matchups
)
select
    Setter_A AS Setter_A,
    Region_A AS Region_A,
    Seeding_Total_Points_A AS Seeding_Total_Points_A,
    Seed_A AS Seed_A,
    Division_A AS Division_A,
    R1_Total_Points_A AS R1_Total_Points_A,
    Division_B AS Division_B,
    Setter_B AS Setter_B,
    Region_B AS Region_B,
    Seeding_Total_Points_B AS Seeding_Total_Points_B,
    Seed_B AS Seed_B,
    R1_Total_Points_B AS R1_Total_Points_B,
    R1Winner AS R1Winner,
    Seed_A AS InheritedWinnerSeed ,
    CASE 
    	WHEN R1Winner = Setter_A THEN Region_A
    	ELSE Region_B
    END AS R1Winner_Region
from
    R1Winner;
    
   
-- CREATE OR REPLACE VIEW IonSF.MarchMadnessTableR2 AS
WITH R1Winners AS (
	SELECT
		*,
		InheritedWinnerSeed AS Seed
	FROM IonSF.MarchMadnessTableR1 mmtr 
),
R2Matchups AS (
    SELECT
        R1W_A.R1Winner AS Winner_A_Name,
        R1W_A.R1Winner_Region AS Winner_A_Region,
        R1W_A.Seed AS Seed_A,
        R1W_B.R1Winner AS Winner_B_Name,
        R1W_B.R1Winner_Region AS Winner_B_Region,
        R1W_B.Seed AS Seed_B
    FROM R1Winners R1W_A
    INNER JOIN R1Winners R1W_B ON R1W_A.Region_A = R1W_B.Region_A
    	AND R1W_A.Division_A = R1W_B.Division_A
        AND R1W_A.Seed + R1W_B.Seed = 33
        AND R1W_A.Seed < R1W_B.Seed
    WHERE R1W_A.R1Winner IS NOT NULL AND R1W_B.R1Winner IS NOT NULL
        AND R1W_A.Setter_A <> R1W_B.Setter_B
),
R2Points AS (
	SELECT 
		Setter AS R2Setter,
		Setter_Region AS R2Region,
		SUM(CASE WHEN RFP_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 2 ELSE 0 END) AS R2_RFP_Points,
        SUM(CASE WHEN Sit_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 10 ELSE 0 END) AS R2_Sit_Points,
        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 15 ELSE 0 END) AS R2_Sale_Points,
        SUM(
        (CASE WHEN RFP_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 2 ELSE 0 END) +
        (CASE WHEN Sit_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 10 ELSE 0 END) +
        (CASE WHEN Contract_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 15 ELSE 0 END)
        ) AS R2_Total_Points
	FROM IonSF.Sales_Info_Table sit 
	WHERE Setter_Region IS NOT NULL
        AND Setter NOT LIKE '%Corporate%'
        AND Setter NOT LIKE '%Landon Cater%' AND Setter NOT LIKE '%Richard Wright%'
        AND Setter_Active = TRUE
    GROUP BY
        Setter, Setter_Region
),
R2Winner AS (
    SELECT
        Winner_A_Name,
        Winner_A_Region AS Region_A,
        a.R2_Total_Points AS Total_Points_A,
        Seed_A,
        Winner_B_Name,
        Winner_B_Region AS Region_B,        
        b.R2_Total_Points AS Total_Points_B,
        Seed_B,
        CASE 
            WHEN a.R2_Total_Points > b.R2_Total_Points THEN Winner_A_Name
            WHEN a.R2_Total_Points < b.R2_Total_Points THEN Winner_B_Name
            WHEN a.R2_Total_Points = b.R2_Total_Points THEN
                CASE 
                    WHEN a.R2_Sit_Points > b.R2_Sit_Points THEN Winner_A_Name
                    WHEN a.R2_Sit_Points < b.R2_Sit_Points THEN Winner_B_Name
                    WHEN a.R2_Sit_Points = b.R2_Sit_Points THEN
                        CASE 
                            WHEN a.R2_RFP_Points > b.R2_RFP_Points THEN Winner_A_Name
                            ELSE Winner_B_Name
                        END -- This END closes the innermost CASE
                END -- This END closes the second CASE
        END AS R2Winner -- This END closes the first CASE
    FROM 
    	R2Matchups rm
	LEFT JOIN R2Points a ON rm.Winner_A_Name = a.R2Setter
	LEFT JOIN R2Points b ON rm.Winner_B_Name = b.R2Setter
)
SELECT 
	*,
	CASE 
		WHEN R2Winner = Winner_A_Name THEN Region_A
		ELSE Region_B
	END	AS R2Winner_Region,
	Seed_A AS R2InheritedWinnerSeed	
FROM R2Winner

DROP TABLE IF EXISTS IonSF.MarchMadnessTempTableR3;

CREATE TABLE IonSF.MarchMadnessTempTableR3 AS
WITH R2Winner AS (
	SELECT *
	FROM IonSF.MarchMadnessTableR2 mmtr 
),
R3Points AS (
	SELECT 
		Setter AS R3Setter,
		Setter_Region AS R3Region,
		SUM(CASE WHEN RFP_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 2 ELSE 0 END) AS R3_RFP_Points,
        SUM(CASE WHEN Sit_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 10 ELSE 0 END) AS R3_Sit_Points,
        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 15 ELSE 0 END) AS R3_Sale_Points,
        SUM(
        (CASE WHEN RFP_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 2 ELSE 0 END) +
        (CASE WHEN Sit_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 10 ELSE 0 END) +
        (CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 15 ELSE 0 END)
        ) AS R3_Total_Points
	FROM IonSF.Sales_Info_Table sit 
	WHERE Setter_Region IS NOT NULL
        AND Setter NOT LIKE '%Corporate%'
        AND Setter NOT LIKE '%Landon Cater%' AND Setter NOT LIKE '%Richard Wright%'
        AND Setter_Active = TRUE
    GROUP BY
        Setter, Setter_Region
),
R3Matchups AS (
	SELECT 
		a.R2Winner AS Winner_A,
		a.R2Winner_Region AS Region_A,
		a.R2InheritedWinnerSeed AS Seed_A,
		b.R2Winner AS Winner_B,
		b.R2Winner_Region AS Region_B,
		b.R2InheritedWinnerSeed AS Seed_B
	FROM R2Winner a
	INNER JOIN R2Winner b ON a.R2Winner_Region = b.R2Winner_Region
		AND a.R2InheritedWinnerSeed + b.R2InheritedWinnerSeed = 17
		AND a.R2InheritedWinnerSeed < b.R2InheritedWinnerSeed
	WHERE a.R2Winner IS NOT NULL AND b.R2Winner IS NOT NULL
),
R3Winner AS (
	SELECT 
		Winner_A,
		Region_A,
		Seed_A,
		Winner_B,
		Region_B,
		Seed_B,
		CASE 
            WHEN a.R3_Total_Points > b.R3_Total_Points THEN Winner_A
            WHEN a.R3_Total_Points < b.R3_Total_Points THEN Winner_B
            WHEN a.R3_Total_Points = b.R3_Total_Points THEN
                CASE 
                    WHEN a.R3_Sit_Points > b.R3_Sit_Points THEN Winner_A
                    WHEN a.R3_Sit_Points < b.R3_Sit_Points THEN Winner_B
                    WHEN a.R3_Sit_Points = b.R3_Sit_Points THEN
                        CASE 
                            WHEN a.R3_RFP_Points > b.R3_RFP_Points THEN Winner_A
                            ELSE Winner_B
                        END -- This END closes the innermost CASE
                END -- This END closes the second CASE
        END AS R3Winner -- This END closes the first CASE
    FROM R3Matchups r3
    LEFT JOIN R3Points a ON r3.Winner_A = a.R3Setter
    LEFT JOIN R3Points b ON r3.Winner_B = b.R3Setter
)
SELECT *,
	CASE 
		WHEN R3Winner = Winner_A THEN Region_A
		ELSE Region_B
	END AS R3Winner_Region,
	Seed_A AS R3InheritedWinnerSeed	
FROM R3Winner


-- CREATE OR REPLACE VIEW IonSF.MarchMadnessTableR4 AS
WITH R3Winner AS (
	SELECT *
	FROM IonSF.MarchMadnessTempTableR3
),
R4Points AS (
	SELECT 
		Setter AS R4Setter,
		Setter_Region AS R4Region,
		SUM(CASE WHEN RFP_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 2 ELSE 0 END) AS R4_RFP_Points,
        SUM(CASE WHEN Sit_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 10 ELSE 0 END) AS R4_Sit_Points,
        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 15 ELSE 0 END) AS R4_Sale_Points,
        SUM(
        (CASE WHEN RFP_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 2 ELSE 0 END) +
        (CASE WHEN Sit_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 10 ELSE 0 END) +
        (CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 15 ELSE 0 END)
        ) AS R4_Total_Points
	FROM IonSF.Sales_Info_Table sit 
	WHERE Setter_Region IS NOT NULL
        AND Setter NOT LIKE '%Corporate%'
        AND Setter NOT LIKE '%Landon Cater%' AND Setter NOT LIKE '%Richard Wright%'
        AND Setter_Active = TRUE
    GROUP BY
        Setter, Setter_Region
),
R4Matchups AS (
	SELECT 
		a.R3Winner AS Winner_A,
		a.R3Winner_Region AS Region_A,
		a.R3InheritedWinnerSeed AS Seed_A,
		b.R3Winner AS Winner_B,
		b.R3Winner_Region AS Region_B,
		b.R3InheritedWinnerSeed AS Seed_B
	FROM R3Winner a
	INNER JOIN R3Winner b ON a.R3Winner_Region = b.R3Winner_Region
		AND a.R3InheritedWinnerSeed + b.R3InheritedWinnerSeed = 9
		AND a.R3InheritedWinnerSeed < b.R3InheritedWinnerSeed
	WHERE a.R3Winner IS NOT NULL AND b.R3Winner IS NOT NULL
),
R4Winner AS (
	SELECT 
		Winner_A,
		Region_A,
		Seed_A,
		Winner_B,
		Region_B,
		Seed_B,
		CASE 
            WHEN a.R4_Total_Points > b.R4_Total_Points THEN Winner_A
            WHEN a.R4_Total_Points < b.R4_Total_Points THEN Winner_B
            WHEN a.R4_Total_Points = b.R4_Total_Points THEN
                CASE 
                    WHEN a.R4_Sit_Points > b.R4_Sit_Points THEN Winner_A
                    WHEN a.R4_Sit_Points < b.R4_Sit_Points THEN Winner_B
                    WHEN a.R4_Sit_Points = b.R4_Sit_Points THEN
                        CASE 
                            WHEN a.R4_RFP_Points > b.R4_RFP_Points THEN Winner_A
                            ELSE Winner_B
                        END -- This END closes the innermost CASE
                END -- This END closes the second CASE
        END AS R4Winner -- This END closes the first CASE
    FROM R4Matchups R4
    LEFT JOIN R4Points a ON R4.Winner_A = a.R4Setter
    LEFT JOIN R4Points b ON R4.Winner_B = b.R4Setter
)
SELECT *,
	CASE 
		WHEN R4Winner = Winner_A THEN Region_A
		ELSE Region_B
	END AS Winner_Region,
	Seed_A AS R4InheritedWinnerSeed	
FROM R4Winner