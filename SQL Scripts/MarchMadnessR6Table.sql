DROP PROCEDURE IF EXISTS IonSF.UpdateMarchMadnessR6Table;
SHOW PROCEDURE STATUS WHERE Db = 'IonSF';
DROP EVENT IonSF.UpdateMarchMadnessR6Table;
CREATE EVENT IonSF.UpdateMarchMadnessR6Table
ON SCHEDULE EVERY 1 HOUR
STARTS '2024-03-21 00:00:00'
DO CALL IonSF.UpdateMarchMadnessR6Table();
SELECT * FROM information_schema.events;
CALL IonSF.UpdateMarchMadnessR6Table();
DELIMITER //
CREATE PROCEDURE IonSF.UpdateMarchMadnessR6Table()
BEGIN
	-- Drop the new table if it exists from a previous incomplete run
    DROP TABLE IF EXISTS IonSF.MarchMadnessR6Table_New;
    -- Create the new table with a temporary name
    CREATE TABLE IonSF.MarchMadnessR6Table_New AS
    WITH R5Winner AS (
		SELECT *
		FROM IonSF.MarchMadnessTableR5 
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
			Region_A,
			Seed_A,
			a.R6_Total_Points AS Total_Points_A,
			Setter_B,
			Region_B,
			Seed_B,
			b.R6_Total_Points AS Total_Points_B,
			CASE 
				WHEN CURDATE() >= '2024-03-24' THEN 
					CASE 
			            WHEN a.R6_Total_Points > b.R6_Total_Points THEN Setter_A
			            WHEN a.R6_Total_Points < b.R6_Total_Points THEN Setter_B
			            WHEN a.R6_Total_Points = b.R6_Total_Points THEN
			                CASE 
			                    WHEN a.R6_Sit_Points > b.R6_Sit_Points THEN Setter_A
			                    WHEN a.R6_Sit_Points < b.R6_Sit_Points THEN Setter_B
			                    WHEN a.R6_Sit_Points = b.R6_Sit_Points THEN
			                        CASE 
			                            WHEN a.R6_RFP_Points < b.R6_RFP_Points THEN Setter_B
			                            ELSE Setter_A
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
		;
	
    -- Start transaction
    START TRANSACTION;

    -- Rename the original table to a temporary name
    RENAME TABLE IonSF.MarchMadnessR6Table TO IonSF.MarchMadnessR6Table_Old;

    -- Rename the new table to the original table's name
    RENAME TABLE IonSF.MarchMadnessR6Table_New TO IonSF.MarchMadnessR6Table;

    -- Drop the old table
    DROP TABLE IF EXISTS IonSF.MarchMadnessR6Table_Old;

    -- Commit the transaction
    COMMIT;
END //
DELIMITER ;