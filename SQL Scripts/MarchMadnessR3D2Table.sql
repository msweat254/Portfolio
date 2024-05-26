DROP PROCEDURE IF EXISTS IonSF.UpdateMarchMadnessR3D2Table;
SHOW PROCEDURE STATUS WHERE Db = 'IonSF';
DROP EVENT IonSF.UpdateMarchMadnessR3D2Table;
CREATE EVENT IonSF.UpdateMarchMadnessR3D2Table
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO CALL IonSF.UpdateMarchMadnessR3D2Table();
SELECT * FROM information_schema.events;
CALL IonSF.UpdateMarchMadnessR3D2Table();
DELIMITER //
CREATE PROCEDURE IonSF.UpdateMarchMadnessR3D2Table()
BEGIN
	-- Drop the new table if it exists from a previous incomplete run
    DROP TABLE IF EXISTS IonSF.MarchMadnessR3D2Table_New;
    -- Create the new table with a temporary name
    CREATE TABLE IonSF.MarchMadnessR3D2Table_New AS
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
			COALESCE(a.R3_Total_Points,0) AS R3_Total_Points_A,
			Winner_B,
			Region_B,
			Seed_B,
			b.R3_Total_Points AS R3_Total_Points_B,
			CASE 
				WHEN CURDATE() >= '2024-03-10' THEN
					CASE 
			            WHEN a.R3_Total_Points > b.R3_Total_Points THEN Winner_A
			            WHEN a.R3_Total_Points < b.R3_Total_Points THEN Winner_B
			            WHEN a.R3_Total_Points IS NULL THEN Winner_B
			            WHEN a.R3_Total_Points = b.R3_Total_Points THEN
			                CASE 
			                    WHEN a.R3_Sit_Points > b.R3_Sit_Points THEN Winner_A
			                    WHEN a.R3_Sit_Points < b.R3_Sit_Points THEN Winner_B
			                    WHEN a.R3_Sit_Points = b.R3_Sit_Points THEN
			                        CASE 
			                            WHEN a.R3_RFP_Points < b.R3_RFP_Points THEN Winner_B			                           
			                            ELSE Winner_A
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
	GROUP BY Winner_A
		;
	
    -- Start transaction
    START TRANSACTION;

    -- Rename the original table to a temporary name
    RENAME TABLE IonSF.MarchMadnessR3D2Table TO IonSF.MarchMadnessR3D2Table_Old;

    -- Rename the new table to the original table's name
    RENAME TABLE IonSF.MarchMadnessR3D2Table_New TO IonSF.MarchMadnessR3D2Table;

    -- Drop the old table
    DROP TABLE IF EXISTS IonSF.MarchMadnessR3D2Table_Old;

    -- Commit the transaction
    COMMIT;
END //
DELIMITER ;