DROP PROCEDURE IF EXISTS IonSF.UpdateMMCloserPointsTable;
SHOW PROCEDURE STATUS WHERE Db = 'IonSF';
DROP EVENT IonSF.UpdateMMCloserPointsTable;
CREATE EVENT IonSF.UpdateMMCloserPointsTable
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO CALL IonSF.UpdateMMCloserPointsTable(); 
SELECT * FROM information_schema.events;
CALL IonSF.UpdateMMCloserPointsTable();
DELIMITER //
CREATE PROCEDURE IonSF.UpdateMMCloserPointsTable()
BEGIN
	-- Drop the new table if it exists from a previous incomplete run
    DROP TABLE IF EXISTS IonSF.MMCloserPointsTable_New;
    -- Create the new table with a temporary name
    CREATE TABLE IonSF.MMCloserPointsTable_New AS
    WITH Points AS (
	SELECT 
		Closer,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-03-09' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS Seeding_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-03-09' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS Seeding_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-03-09' THEN contract_date END) AS Seeding_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-03-09' THEN System_Size END) AS Seeding_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-03-09' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-02-15' AND '2024-03-09' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS Seeding_Total_Points,
    	COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS R1_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS R1_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN contract_date END) AS R1_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' THEN System_Size END) AS R1_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-03-10' AND '2024-03-13' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS R1_Total_Points,
    	COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS R2_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS R2_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN contract_date END) AS R2_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' THEN System_Size END) AS R2_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-03-14' AND '2024-03-16' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS R2_Total_Points,
    	COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS R3_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS R3_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' THEN contract_date END) AS R3_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' THEN System_Size END) AS R3_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-03-17' AND '2024-03-20' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS R3_Total_Points,
    	COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS R4_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS R4_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' THEN contract_date END) AS R4_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' THEN System_Size END) AS R4_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-03-21' AND '2024-03-23' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS R4_Total_Points,
    	COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS R5_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS R5_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' THEN contract_date END) AS R5_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' THEN System_Size END) AS R5_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-03-24' AND '2024-03-27' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS R5_Total_Points,
    	COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' AND Sales_Channel = 'Self Gen' THEN contract_date END) AS R6_SelfGens,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' AND Sales_Channel != 'Self Gen' THEN contract_date END) AS R6_NormalSales,
		COUNT(CASE WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' THEN contract_date END) AS R6_TotalSales,
		SUM(CASE WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' THEN System_Size END) AS R6_Kws,
        SUM(CASE 
		        WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' AND Sales_Channel = 'Self Gen' THEN 27 
		        WHEN Contract_Date BETWEEN '2024-03-28' AND '2024-03-30' AND Sales_Channel != 'Self Gen' THEN 15  
	        	ELSE 0 
        	END) AS R6_Total_Points
	FROM IonSF.Sales_Info_Table sit 
	WHERE Closer NOT LIKE '%Closer%'
		AND Closer IS NOT NULL
	GROUP BY Closer
	ORDER BY Seeding_Total_Points DESC,Seeding_Kws DESC
	)
	SELECT *
	FROM Points
	GROUP By Closer
		;
	
    -- Start transaction
    START TRANSACTION;

    -- Rename the original table to a temporary name
    RENAME TABLE IonSF.MMCloserPointsTable TO IonSF.MMCloserPointsTable_Old;

    -- Rename the new table to the original table's name
    RENAME TABLE IonSF.MMCloserPointsTable_New TO IonSF.MMCloserPointsTable;

    -- Drop the old table
    DROP TABLE IF EXISTS IonSF.MMCloserPointsTable_Old;

    -- Commit the transaction
    COMMIT;
END //
DELIMITER ;