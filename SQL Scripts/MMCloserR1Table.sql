DROP PROCEDURE IF EXISTS IonSF.UpdateMMCloserR1Table;
SHOW PROCEDURE STATUS WHERE Db = 'IonSF';
DROP EVENT IonSF.UpdateMMCloserR1Table;
CREATE EVENT IonSF.UpdateMMCloserR1Table
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO CALL IonSF.UpdateMMCloserR1Table(); 
SELECT * FROM information_schema.events;
CALL IonSF.UpdateMMCloserR1Table();
DELIMITER //
CREATE PROCEDURE IonSF.UpdateMMCloserR1Table()
BEGIN
	-- Drop the new table if it exists from a previous incomplete run
    DROP TABLE IF EXISTS IonSF.MMCloserR1Table_New;
    -- Create the new table with a temporary name
    CREATE TABLE IonSF.MMCloserR1Table_New AS
    WITH R1Matchups AS (
	SELECT 
		a.Closer AS Closer_A,
		a.Seed AS Seed_A,
		b.Closer AS Closer_B,
		b.Seed AS Seed_B
	FROM IonSF.MMCloserSeeding a
	INNER JOIN IonSF.MMCloserSeeding b ON a.Seed + b.Seed = 65
		AND a.Seed < b.Seed
	),
	R1Winner AS (
		SELECT 
			Closer_A,
			Seed_A,
			a.R1_Total_Points AS R1_Total_Points_A,
			Closer_B,
			Seed_B,
			b.R1_Total_Points AS R1_Total_Points_B,
			CASE 
				WHEN CURDATE() >= '2024-03-10' THEN
					CASE 
			            WHEN a.R1_Total_Points > b.R1_Total_Points THEN Closer_A
			            WHEN a.R1_Total_Points < b.R1_Total_Points THEN Closer_B
			            WHEN a.R1_Total_Points = b.R1_Total_Points THEN
			                CASE 
			                    WHEN a.R1_SelfGens > b.R1_SelfGens THEN Closer_A
			                    WHEN a.R1_SelfGens < b.R1_SelfGens THEN Closer_B
			                    WHEN a.R1_SelfGens = b.R1_SelfGens THEN
			                        CASE 
			                            WHEN a.R1_Kws < b.R1_Kws THEN Closer_B
			                            ELSE Closer_A
			                        END -- This END closes the innermost CASE
			                END -- This END closes the second CASE
			        END
		        ELSE 'Round Not Started'
	        END AS R1Winner -- This END closes the first CASE
	    FROM R1Matchups R1
	    LEFT JOIN IonSF.MMCloserPointsTable a ON R1.Closer_A = a.Closer
	    LEFT JOIN IonSF.MMCloserPointsTable b ON R1.Closer_B = b.Closer
	)
	SELECT *,
		Seed_A AS InheritedSeed	
	FROM R1Winner
		;
	
    -- Start transaction
    START TRANSACTION;

    -- Rename the original table to a temporary name
    RENAME TABLE IonSF.MMCloserR1Table TO IonSF.MMCloserR1Table_Old;

    -- Rename the new table to the original table's name
    RENAME TABLE IonSF.MMCloserR1Table_New TO IonSF.MMCloserR1Table;

    -- Drop the old table
    DROP TABLE IF EXISTS IonSF.MMCloserR1Table_Old;

    -- Commit the transaction
    COMMIT;
END //
DELIMITER ;