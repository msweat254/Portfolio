DROP TABLE IF EXISTS IonSF.MarchMadnessSeedingD2Locked;

CREATE TABLE IonSF.MarchMadnessSeedingD2Locked AS
WITH ShortFalls AS(
	SELECT
		Setter_Region,
		CASE 
			WHEN (64 - COUNT(DISTINCT Seed)) < 0 THEN 'Over'
			WHEN (64 - COUNT(DISTINCT Seed)) > 0 THEN 'Under'
			ELSE 'Even'
		END AS `Over/Under`,
		64 - COUNT(DISTINCT Seed) AS ShortFall
	FROM IonSF.MarchMadnessSeedingTable mms 
	WHERE Seeding_Total_Points > 0 AND Seed > 64
	GROUP BY Setter_Region
),
TotalD2Setters AS (
	SELECT 
	    s.Setter,
	    s.Setter_Region AS Original_Region,
	    sf.`Over/Under`,
	    sf.ShortFall AS RegionShortFall,
	    s.Setter_Region AS Comp_Region,
	    s.Seeding_Total_Points,
	    s.Seeding_Sale_Points,
	    s.Seeding_Sit_Points,
	    s.Seeding_RFP_Points,
	    s.Seed AS RegionalSeed,
	    ROW_NUMBER() OVER (ORDER BY Seeding_Total_Points DESC, Seeding_Sit_Points DESC, Seeding_RFP_Points DESC) AS GlobalRank
	FROM IonSF.MarchMadnessSeedingTable s
	LEFT JOIN ShortFalls sf ON s.Setter_Region = sf.Setter_Region
	WHERE (s.Seed BETWEEN 65 AND 128) AND s.Seeding_Total_Points > 0
	UNION ALL
	SELECT 
	    s.Setter,
	    s.Setter_Region AS Original_Region,
	    sf.`Over/Under`,
	    sf.ShortFall AS RegionShortFall,
	    'Central' AS Comp_Region,
	    s.Seeding_Total_Points,
	    s.Seeding_Sale_Points,
	    s.Seeding_Sit_Points,
	    s.Seeding_RFP_Points,
	    s.Seed AS RegionalSeed,
	    ROW_NUMBER() OVER (ORDER BY s.Seeding_Total_Points DESC, s.Seeding_Sit_Points DESC, s.Seeding_RFP_Points DESC) AS GlobalRank
	FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Setter_Region ORDER BY Seeding_Total_Points DESC, Seeding_Sit_Points DESC, Seeding_RFP_Points DESC) AS RegionRank
    FROM IonSF.MarchMadnessSeedingTable
    WHERE Setter_Region = 'East' AND Seed > 128 AND Seeding_Total_Points > 0
	) s
	LEFT JOIN ShortFalls sf ON s.Setter_Region = sf.Setter_Region
	WHERE s.RegionRank <= 24
)
SELECT
	Setter,
	Original_Region,
	Comp_Region,
	ROW_NUMBER() OVER (PARTITION BY Comp_Region ORDER BY Seeding_Total_Points DESC, Seeding_Sit_Points DESC, Seeding_RFP_Points DESC) AS Seed
FROM TotalD2Setters



DROP TABLE IF EXISTS IonSF.MarchMadnessTableR1D2Locked;

CREATE TABLE IonSF.MarchMadnessTableR1D2Locked AS 
WITH R1Matchups AS (
	SELECT 
		a.Setter AS Setter_A,
		a.Comp_Region AS Region_A,
		a.Seed AS Seed_A,
		b.Setter AS Setter_B,
		b.Comp_Region AS Region_B,
		b.Seed AS Seed_B
	FROM IonSF.MarchMadnessSeedingD2Locked a
	INNER JOIN IonSF.MarchMadnessSeedingD2Locked b ON a.Comp_Region = b.Comp_Region
		AND a.Seed + b.Seed = 65
		AND a.Seed < b.Seed
),
R1Winner AS (
	SELECT 
		Setter_A,
		Region_A,
		Seed_A,
		a.R1_Total_Points AS R1_Total_Points_A,
		Setter_B,
		Region_B,
		Seed_B,
		b.R1_Total_Points AS R1_Total_Points_B,
		CASE 
			WHEN CURDATE() >= '2024-03-03' THEN
				CASE 
					WHEN Setter_B IS NULL THEN Setter_A	
					ELSE
						CASE 
				            WHEN a.R1_Total_Points > b.R1_Total_Points THEN Setter_A
				            WHEN a.R1_Total_Points < b.R1_Total_Points THEN Setter_B
				            WHEN a.R1_Total_Points = b.R1_Total_Points THEN
				                CASE 
				                    WHEN a.R1_Sit_Points > b.R1_Sit_Points THEN Setter_A
				                    WHEN a.R1_Sit_Points < b.R1_Sit_Points THEN Setter_B
				                    WHEN a.R1_Sit_Points = b.R1_Sit_Points THEN
				                        CASE 
				                            WHEN a.R1_RFP_Points < b.R1_RFP_Points THEN Setter_B
				                            ELSE Setter_A
				                        END -- This END closes the innermost CASE
				                END -- This END closes the second CASE
				        END
		        END
	        ELSE 'Round Not Started'
        END AS R1Winner -- This END closes the first CASE
    FROM R1Matchups R1
    LEFT JOIN IonSF.MarchMadnessSeedingTable a ON R1.Setter_A = a.Setter
    LEFT JOIN IonSF.MarchMadnessSeedingTable b ON R1.Setter_B = b.Setter
)
SELECT *,
	CASE 
		WHEN R1Winner = Setter_A THEN Region_A
		ELSE Region_B
	END AS Winner_Region,
	Seed_A AS InheritedSeed	
FROM R1Winner
ORDER BY Region_A ASC,Seed_A ASC
    
   
-- CREATE OR REPLACE VIEW IonSF.MarchMadnessTableR2D2 AS
WITH R1Winners AS (
	SELECT
		*,
		InheritedSeed AS Seed
	FROM IonSF.MarchMadnessTableR1D2Locked mmtr 
),
R2Matchups AS (
    SELECT
        R1W_A.R1Winner AS Winner_A_Name,
        R1W_A.Winner_Region AS Winner_A_Region,
        R1W_A.Seed AS Seed_A,
        R1W_B.R1Winner AS Winner_B_Name,
        R1W_B.Winner_Region AS Winner_B_Region,
        R1W_B.Seed AS Seed_B
    FROM R1Winners R1W_A
    INNER JOIN R1Winners R1W_B ON R1W_A.Region_A = R1W_B.Region_A
        AND R1W_A.Seed + R1W_B.Seed = 33
        AND R1W_A.Seed < R1W_B.Seed
    WHERE R1W_A.R1Winner IS NOT NULL AND R1W_B.R1Winner IS NOT NULL
        AND R1W_A.Setter_A <> R1W_B.Setter_B
--     UNION ALL 
--     SELECT
--         R1W_A.R1Winner AS Winner_A_Name,
--         R1W_A.Winner_Region AS Winner_A_Region,
--         R1W_A.Seed AS Seed_A,
--         R1W_B.R1Winner AS Winner_B_Name,
--         R1W_B.Winner_Region AS Winner_B_Region,
--         R1W_B.Seed AS Seed_B
--     FROM R1Winners R1W_A
--     INNER JOIN R1Winners R1W_B ON R1W_A.Region_A = R1W_B.Region_A
--         AND R1W_A.Seed + R1W_B.Seed = 33
--         AND R1W_A.Seed < R1W_B.Seed
--     WHERE R1W_A.Winner_Region = 'Central'
--     UNION ALL 
--     SELECT 
--     	R1Winner AS Winner_A_Name,
--         Winner_Region AS Winner_A_Region,
--         Seed AS Seed_A,
--         NULL AS Winner_B_Name,
--         'Central' AS Winner_B_Region,
--         33 - Seed AS Seed_B
--     FROM R1Winners
--     WHERE Seed < 8 AND Winner_Region = 'Central'
),
R2Winner AS (
    SELECT
        Winner_A_Name,
        Winner_A_Region AS Region_A,
        Seed_A,
        a.R2_Total_Points AS R2_Total_Points_A,
        Winner_B_Name,
        Winner_B_Region AS Region_B,
        Seed_B,
        b.R2_Total_Points AS R2_Total_Points_B,
        CASE
	        WHEN CURDATE() >= '2024-03-07' THEN
	        	CASE 
	        		WHEN Winner_B_Name IS NULL THEN Winner_A_Name
	        		ELSE
				        CASE 
				            WHEN a.R2_Total_Points > b.R2_Total_Points THEN Winner_A_Name
				            WHEN a.R2_Total_Points < b.R2_Total_Points THEN Winner_B_Name
				            WHEN a.R2_Total_Points = b.R2_Total_Points THEN
				                CASE 
				                    WHEN a.R2_Sit_Points > b.R2_Sit_Points THEN Winner_A_Name
				                    WHEN a.R2_Sit_Points < b.R2_Sit_Points THEN Winner_B_Name
				                    WHEN a.R2_Sit_Points = b.R2_Sit_Points THEN
				                        CASE 
				                            WHEN a.R2_RFP_Points < b.R2_RFP_Points THEN Winner_B_Name
				                            ELSE Winner_A_Name
				                        END -- This END closes the innermost CASE
				                END -- This END closes the second CASE
			            END
	            END
            ELSE 'Round Not Started'
        END AS R2Winner -- This END closes the first CASE
    FROM 
    	R2Matchups rm
	LEFT JOIN IonSF.MarchMadnessPointsTable a ON rm.Winner_A_Name = a.Setter
	LEFT JOIN IonSF.MarchMadnessPointsTable b ON rm.Winner_B_Name = b.Setter
)
SELECT *,
	CASE 
		WHEN R2Winner = Winner_A_Name THEN Region_A
		ELSE Region_B
	END	AS Winner_Region,
	Seed_A AS InheritedSeed	
FROM R2Winner
ORDER BY Region_A ASC, Seed_A ASC



SELECT *
FROM IonSF.MarchMadnessR3D2Table mmrdt 


DROP TABLE IonSF.MarchMadnessR3D2Table ;
CREATE TABLE IonSF.MarchMadnessR3D2Table AS
WITH R2Winner AS (
		SELECT *
		FROM IonSF.MarchMadnessTableR2D2 mmtr 
	),
	R3Matchups AS (
		SELECT 
			a.R2Winner AS Winner_A,
			a.Winner_Region AS Region_A,
			a.InheritedSeed AS Seed_A,
			b.R2Winner AS Winner_B,
			b.Winner_Region AS Region_B,
			b.InheritedSeed AS Seed_B
		FROM R2Winner a
		INNER JOIN R2Winner b ON a.Winner_Region = b.Winner_Region
			AND a.InheritedSeed + b.InheritedSeed = 17
			AND a.InheritedSeed < b.InheritedSeed
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
				WHEN CURDATE() >= '2024-03-10' THEN
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
	                END
                ELSE 'Round Not Started'
	        END AS R3Winner -- This END closes the first CASE
	    FROM R3Matchups r3
	    LEFT JOIN IonSF.MarchMadnessPointsTable a ON r3.Winner_A = a.Setter
	    LEFT JOIN IonSF.MarchMadnessPointsTable b ON r3.Winner_B = b.Setter
	)
	SELECT *,
		CASE 
			WHEN R3Winner = Winner_A THEN Region_A
			ELSE Region_B
		END AS Winner_Region,
		Seed_A AS InheritedSeed	
	FROM R3Winner
	ORDER BY Region_A ASC, Seed_A ASC

	
	
DROP Table IonSF.MarchMadnessTableR4D2;
CREATE TABLE IonSF.MarchMadnessTableR4D2 AS
WITH R3Winner AS (
	SELECT *
	FROM IonSF.MarchMadnessR3D2Table mmtr 
	GROUP BY Winner_A
),
R4Matchups AS (
	SELECT 
		a.R3Winner AS Winner_A,
		a.Winner_Region AS Region_A,
		a.InheritedSeed AS Seed_A,
		b.R3Winner AS Winner_B,
		b.Winner_Region AS Region_B,
		b.InheritedSeed AS Seed_B
	FROM R3Winner a
	INNER JOIN R3Winner b ON a.Winner_Region = b.Winner_Region
		AND a.InheritedSeed + b.InheritedSeed = 9
		AND a.InheritedSeed < b.InheritedSeed
	WHERE a.R3Winner IS NOT NULL AND b.R3Winner IS NOT NULL
),
R4Winner AS (
	SELECT 
		Winner_A,
		Region_A,
		Seed_A,
		a.R4_Total_Points AS R4_Total_Points_A,
		Winner_B,
		Region_B,
		Seed_B,
		b.R4_Total_Points AS R4_Total_Points_B,
		CASE 
			WHEN CURDATE() >= '2024-03-14' THEN		
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
                END
            ELSE 'Round Not Started'
        END AS R4Winner -- This END closes the first CASE
    FROM R4Matchups R4
    LEFT JOIN IonSF.MarchMadnessPointsTable a ON R4.Winner_A = a.Setter
    LEFT JOIN IonSF.MarchMadnessPointsTable b ON R4.Winner_B = b.Setter
)
SELECT *,
	CASE 
		WHEN R4Winner = Winner_A THEN Region_A
		ELSE Region_B
	END AS Winner_Region,
	Seed_A AS InheritedSeed	
FROM R4Winner



DROP TABLE IonSF.MarchMadnessWildcardD2 ;
CREATE TABLE IonSF.MarchMadnessWildcardD2 AS
WITH Points AS (
	SELECT 
		mms.Setter,
		mms.Original_Region,
		mms.Comp_Region AS Setter_Region,
		mmw.RFP_Points,
		mmw.Sit_Points,
		mmw.Sale_Points,
		mmw.Total_Points
	FROM IonSF.MarchMadnessSeedingD2 mms
	LEFT JOIN IonSF.MarchMadnessWildcard mmw ON mms.Setter = mmw.Setter
)
SELECT *
FROM Points
-- WHERE Setter NOT IN(SELECT R4Winner FROM IonSF.MarchMadnessTableR4D2)



DROP VIEW IonSF.MarchMadnessTableR5D2 ;
CREATE TABLE IonSF.MarchMadnessTableR5D2 AS 
WITH R4Winner AS (
	SELECT *
	from IonSF.MarchMadnessTableR4D2
),
D1Wildcard AS (
	select *,
		ROW_NUMBER() OVER (ORDER BY Total_Points DESC, Sit_Points DESC, RFP_Points DESC) AS RegionRank
	from IonSF.MarchMadnessWildcard mmw 
	WHERE Setter NOT IN(SELECT R4Winner FROM IonSF.MarchMadnessTableR4 mmtr)
),
WildcardPoints AS (
	select *
	from IonSF.MarchMadnessWildcardD2
	WHERE Setter NOT IN (select R4Winner from R4Winner)
		AND Setter NOT IN (select Setter from D1Wildcard WHERE RegionRank <= 4)
),
TopWildcards AS (
	select *,
		ROW_NUMBER() OVER (ORDER BY Total_Points DESC, Sit_Points DESC, RFP_Points DESC) AS RegionRank
	from WildcardPoints
),
Combined AS (
	SELECT
		R4Winner AS Setter,
		Winner_Region AS Setter_Region
	FROM R4Winner
	UNION ALL
	SELECT
		Setter,
		Setter_Region
	FROM TopWildcards
	WHERE RegionRank <= 4
),
Ranked AS (
	SELECT 
	c.Setter AS Setter1,
	c.Setter_Region AS Region,
	mmw.RFP_Points,
	mmw.Sit_Points,
	mmw.Sale_Points,
	mmw.Total_Points,
		ROW_NUMBER() OVER (ORDER BY mmw.Total_Points DESC, mmw.Sit_Points DESC, mmw.RFP_Points DESC) AS Seed
	FROM Combined c
	LEFT JOIN IonSF.MarchMadnessWildcardD2 mmw ON c.Setter = mmw.Setter AND c.Setter_Region = mmw.Setter_Region
),
R5Matchups AS (
	SELECT
		a.Setter1 AS Setter_A,
		a.Seed AS Seed_A,
		a.Region AS Region_A,
		b.Setter1 AS Setter_B,
		b.Seed AS Seed_B,
		b.Region AS Region_B
	FROM Ranked a
	INNER JOIN Ranked b ON a.Seed + b.Seed = 17
		AND a.Seed < b.Seed
),
R5Winner AS (
	SELECT 
		Setter_A,
		Seed_A,
		Region_A,
		a.R5_Total_Points AS R5_Total_Points_A,
		Setter_B,
		Seed_B,
		Region_B,
		b.R5_Total_Points AS R5_Total_Points_B,
		CASE 
			WHEN CURDATE() >= '2024-03-21' THEN		
				CASE 
		            WHEN a.R5_Total_Points > b.R5_Total_Points THEN Setter_A
		            WHEN a.R5_Total_Points < b.R5_Total_Points THEN Setter_B
		            WHEN a.R5_Total_Points = b.R5_Total_Points THEN
		                CASE 
		                    WHEN a.R5_Sit_Points > b.R5_Sit_Points THEN Setter_A
		                    WHEN a.R5_Sit_Points < b.R5_Sit_Points THEN Setter_B
		                    WHEN a.R5_Sit_Points = b.R5_Sit_Points THEN
		                        CASE 
		                            WHEN a.R5_RFP_Points < b.R5_RFP_Points THEN Setter_B
		                            ELSE Setter_A
		                        END -- This END closes the innermost CASE
		                END -- This END closes the second CASE
                END
            ELSE 'Round Not Started'
        END AS R5Winner -- This END closes the first CASE
	FROM R5Matchups rm
	LEFT JOIN IonSF.MarchMadnessPointsTable a ON rm.Setter_A = a.Setter
	LEFT JOIN IonSF.MarchMadnessPointsTable b ON rm.Setter_B = b.Setter
)
select *,
	Seed_A AS InheritedSeed,
	CASE 
		WHEN R5Winner = Setter_A THEN Region_A
		ELSE Region_B
	END AS Region	
from R5Winner



CREATE TABLE IonSF.MarchMadnessR6D2Table AS
    WITH R5Winner AS (
		SELECT *
		FROM IonSF.MarchMadnessTableR5D2 
	),
	R6Matchups AS (
		SELECT 
			a.R5Winner AS Setter_A,
			a.InheritedSeed AS Seed_A,
			a.Region AS Region_A,
			b.R5Winner AS Setter_B,
			b.InheritedSeed AS Seed_B,
			b.Region AS Region_B
		FROM R5Winner a
		INNER JOIN R5Winner b ON a.InheritedSeed + b.InheritedSeed = 9
			AND a.InheritedSeed < b.InheritedSeed
	),
	R6Winner AS (
		SELECT 
			Setter_A,
			Seed_A,
			Region_A,
			a.R6_Total_Points AS Total_Points_A,
			Setter_B,
			Seed_B,
			Region_B,
			b.R6_Total_Points AS Total_Points_B,
			CASE 
				WHEN CURDATE() >= '2024-03-21' THEN 
					CASE 
			            WHEN a.R6_Total_Points > b.R6_Total_Points THEN Setter_A
			            WHEN a.R6_Total_Points < b.R6_Total_Points THEN Setter_B
			            WHEN a.R6_Total_Points = b.R6_Total_Points THEN
			                CASE 
			                    WHEN a.R6_Sit_Points > b.R6_Sit_Points THEN Setter_A
			                    WHEN a.R6_Sit_Points < b.R6_Sit_Points THEN Setter_B
			                    WHEN a.R6_Sit_Points = b.R6_Sit_Points THEN
			                        CASE 
			                            WHEN a.R6_RFP_Points > b.R6_RFP_Points THEN Setter_A
			                            ELSE Setter_B
			                        END -- This END closes the innermost CASE
			                END -- This END closes the second CASE
	                END
                ELSE 'Round Not Started'
	        END AS R6Winner -- This END closes the first CASE
		FROM R6Matchups r
		LEFT JOIN IonSF.MarchMadnessPointsTable a ON r.Setter_A = a.Setter
		LEFT JOIN IonSF.MarchMadnessPointsTable b ON r.Setter_B = b.Setter
	)
	SELECT *,
		Seed_A AS InheritedSeed,
		CASE 
			WHEN R6Winner = Setter_A THEN Region_A
			ELSE Region_B 
		END AS Region
	FROM R6Winner

	
	
DROP VIEW IonSF.MarchMadnessTableR7D2 ;
CREATE TABLE IonSF.MarchMadnessTableR7D2 AS
WITH R6Winner AS (
	SELECT *
	FROM IonSF.MarchMadnessR6D2Table
),
R7Matchups AS (
	SELECT 
		a.R6Winner AS Setter_A,
		a.InheritedSeed AS Seed_A,
		a.Region AS Region_A,
		b.R6Winner AS Setter_B,
		b.InheritedSeed AS Seed_B,
		b.Region AS Region_B
	FROM R6Winner a
	INNER JOIN R6Winner b ON a.InheritedSeed + b.InheritedSeed = 5
		AND a.InheritedSeed < b.InheritedSeed
),
R7Winner AS (
	SELECT 
		Setter_A,
		Seed_A,
		Region_A,
		a.R7_Total_Points AS R7_Total_Points_A,
		Setter_B,
		Seed_B,
		Region_B,
		b.R7_Total_Points AS R7_Total_Points_B,
		CASE 
			WHEN CURDATE() >= '2024-03-28' THEN
				CASE 
		            WHEN a.R7_Total_Points > b.R7_Total_Points THEN Setter_A
		            WHEN a.R7_Total_Points < b.R7_Total_Points THEN Setter_B
		            WHEN a.R7_Total_Points = b.R7_Total_Points THEN
		                CASE 
		                    WHEN a.R7_Sit_Points > b.R7_Sit_Points THEN Setter_A
		                    WHEN a.R7_Sit_Points < b.R7_Sit_Points THEN Setter_B
		                    WHEN a.R7_Sit_Points = b.R7_Sit_Points THEN
		                        CASE 
		                            WHEN a.R7_RFP_Points > b.R7_RFP_Points THEN Setter_A
		                            ELSE Setter_B
		                        END -- This END closes the innermost CASE
		                END -- This END closes the second CASE
                END
            ELSE 'Round Not Started'
        END AS R7Winner -- This END closes the first CASE
	FROM R7Matchups r
	LEFT JOIN IonSF.MarchMadnessPointsTable a ON r.Setter_A = a.Setter
	LEFT JOIN IonSF.MarchMadnessPointsTable b ON r.Setter_B = b.Setter
)
SELECT *,
	Seed_A AS InheritedSeed,
	CASE 
		WHEN R7Winner = Setter_A THEN Region_A
		ELSE Region_B
	END AS Region	
FROM R7Winner

DROP VIEW IonSF.MarchMadnessTableR8D2 ;
CREATE TABLE IonSF.MarchMadnessTableR8D2 AS
WITH R7Winner AS (
	SELECT *
	FROM IonSF.MarchMadnessTableR7D2
),
R8Matchups AS (
	SELECT 
		a.R7Winner AS Setter_A,
		a.InheritedSeed AS Seed_A,
		a.Region AS Region_A,
		b.R7Winner AS Setter_B,
		b.InheritedSeed AS Seed_B,
		b.Region AS Region_B
	FROM R7Winner a
	INNER JOIN R7Winner b ON a.InheritedSeed + b.InheritedSeed = 3
		AND a.InheritedSeed < b.InheritedSeed
),
R8Winner AS (
	SELECT 
		Setter_A,
		Seed_A,
		Region_A,
		a.R8_Total_Points AS R8_Total_Points_A,
		Setter_B,
		Seed_B,
		Region_B,
		b.R8_Total_Points AS R8_Total_Points_B,
		CASE 
			WHEN CURDATE() >= '2024-03-28' THEN
				CASE 
		            WHEN a.R8_Total_Points > b.R8_Total_Points THEN Setter_A
		            WHEN a.R8_Total_Points < b.R8_Total_Points THEN Setter_B
		            WHEN a.R8_Total_Points = b.R8_Total_Points THEN
		                CASE 
		                    WHEN a.R8_Sit_Points > b.R8_Sit_Points THEN Setter_A
		                    WHEN a.R8_Sit_Points < b.R8_Sit_Points THEN Setter_B
		                    WHEN a.R8_Sit_Points = b.R8_Sit_Points THEN
		                        CASE 
		                            WHEN a.R8_RFP_Points > b.R8_RFP_Points THEN Setter_A
		                            ELSE Setter_B
		                        END -- This END closes the innermost CASE
		                END -- This END closes the second CASE
                END
            ELSE 'Round Not Started'
        END AS R8Winner -- This END closes the first CASE
	FROM R8Matchups r
	LEFT JOIN IonSF.MarchMadnessPointsTable a ON r.Setter_A = a.Setter
	LEFT JOIN IonSF.MarchMadnessPointsTable b ON r.Setter_B = b.Setter
)
SELECT *,
	CASE 
		WHEN R8Winner = Setter_A THEN Region_A
		ELSE Region_B
	END AS ChampionRegion
FROM R8Winner

