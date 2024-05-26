DROP PROCEDURE IF EXISTS IonSF.UpdateMarchMadnessPointsTable;
SHOW PROCEDURE STATUS WHERE Db = 'IonSF';
DROP EVENT IonSF.UpdateMarchMadnessPointsTable;
CREATE EVENT IonSF.UpdateMarchMadnessPointsTable
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO CALL IonSF.UpdateMarchMadnessPointsTable();
SELECT * FROM information_schema.events;
CALL IonSF.UpdateMarchMadnessPointsTable();
DELIMITER //
CREATE PROCEDURE IonSF.UpdateMarchMadnessPointsTable()
BEGIN
	-- Drop the new table if it exists from a previous incomplete run
    DROP TABLE IF EXISTS IonSF.MarchMadnessPointsTable_New;
    -- Create the new table with a temporary name
    CREATE TABLE IonSF.MarchMadnessPointsTable_New AS
    WITH Points AS (
	    SELECT
	        Setter,
	        Setter_Region,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-02-15' AND '2024-02-29' THEN 2 ELSE 0 END) AS Seeding_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-02-15' AND '2024-02-29' THEN 10 ELSE 0 END) AS Seeding_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-02-29' THEN 15 ELSE 0 END) AS Seeding_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-03' AND '2024-03-06' THEN 2 ELSE 0 END) AS R1_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-03' AND '2024-03-06' THEN 10 ELSE 0 END) AS R1_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-03' AND '2024-03-06' THEN 15 ELSE 0 END) AS R1_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 2 ELSE 0 END) AS R2_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-07' AND '2024-03-09' THEN 10 ELSE 0 END) AS R2_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-07' AND '2024-03-09' THEN 15 ELSE 0 END) AS R2_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 2 ELSE 0 END) AS R3_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-10' AND '2024-03-13' THEN 10 ELSE 0 END) AS R3_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN 15 ELSE 0 END) AS R3_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 2 ELSE 0 END) AS R4_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-14' AND '2024-03-16' THEN 10 ELSE 0 END) AS R4_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN 15 ELSE 0 END) AS R4_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-17' AND '2024-03-20' THEN 2 ELSE 0 END) AS R5_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-17' AND '2024-03-20' THEN 10 ELSE 0 END) AS R5_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' THEN 15 ELSE 0 END) AS R5_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-21' AND '2024-03-23' THEN 2 ELSE 0 END) AS R6_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-21' AND '2024-03-23' THEN 10 ELSE 0 END) AS R6_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' THEN 15 ELSE 0 END) AS R6_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-24' AND '2024-03-27' THEN 2 ELSE 0 END) AS R7_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-24' AND '2024-03-27' THEN 10 ELSE 0 END) AS R7_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' THEN 15 ELSE 0 END) AS R7_Sale_Points,
	        SUM(CASE WHEN RFP_Date BETWEEN '2024-03-28' AND '2024-03-30' THEN 2 ELSE 0 END) AS R8_RFP_Points,
	        SUM(CASE WHEN DATE(Sit_Date) BETWEEN '2024-03-28' AND '2024-03-30' THEN 10 ELSE 0 END) AS R8_Sit_Points,
	        SUM(CASE WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' THEN 15 ELSE 0 END) AS R8_Sale_Points
	    FROM
	        IonSF.Sales_Info_Table sit
	    WHERE Setter_Region IS NOT NULL
	        AND Setter NOT LIKE '%Corporate%'
	        AND Setter NOT LIKE '%Landon Cater%' AND Setter NOT LIKE '%Richard Wright%'
	        AND ((lead_channel != 'Inside') OR (lead_channel ='Inside' AND Inside_Setter = 'Spencer Van Ausdal'))
	    GROUP BY
	        Setter, Setter_Region
    )
	SELECT *,
    	SUM(Seeding_RFP_Points + Seeding_Sit_Points + Seeding_Sale_Points) AS Seeding_Total_Points,
    	SUM(R1_RFP_Points + R1_Sit_Points + R1_Sale_Points) AS R1_Total_Points,
    	SUM(R2_RFP_Points + R2_Sit_Points + R2_Sale_Points) AS R2_Total_Points,
    	SUM(R3_RFP_Points + R3_Sit_Points + R3_Sale_Points) AS R3_Total_Points,
    	SUM(R4_RFP_Points + R4_Sit_Points + R4_Sale_Points) AS R4_Total_Points,
    	SUM(R5_RFP_Points + R5_Sit_Points + R5_Sale_Points) AS R5_Total_Points,
    	SUM(R6_RFP_Points + R6_Sit_Points + R6_Sale_Points) AS R6_Total_Points,
    	SUM(R7_RFP_Points + R7_Sit_Points + R7_Sale_Points) AS R7_Total_Points,
    	SUM(R8_RFP_Points + R8_Sit_Points + R8_Sale_Points) AS R8_Total_Points
	FROM Points
	GROUP BY Setter, Setter_Region
		;
	
    -- Start transaction
    START TRANSACTION;

    -- Rename the original table to a temporary name
    RENAME TABLE IonSF.MarchMadnessPointsTable TO IonSF.MarchMadnessPointsTable_Old;

    -- Rename the new table to the original table's name
    RENAME TABLE IonSF.MarchMadnessPointsTable_New TO IonSF.MarchMadnessPointsTable;

    -- Drop the old table
    DROP TABLE IF EXISTS IonSF.MarchMadnessPointsTable_Old;

    -- Commit the transaction
    COMMIT;
END //
DELIMITER ;