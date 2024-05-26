CREATE OR REPLACE VIEW IonSF.MMWinners AS
WITH Combined AS (
	SELECT 
		R1Winner AS Winner
		,'D1' AS Division
		,'R1' AS RoundNum
	FROM IonSF.MarchMadnessTableR1Locked mmtrl 
	UNION ALL
	SELECT 
		R2Winner AS Winner
		,'D1' AS Division
		,'R2' AS RoundNum
	FROM IonSF.MarchMadnessTableR2
	UNION ALL
	SELECT 
		R3Winner AS Winner
		,'D1' AS Division
		,'R3' AS RoundNum
	FROM IonSF.MarchMadnessR3Table
	UNION ALL
	SELECT 
		R4Winner AS Winner
		,'D1' AS Division
		,'R4' AS RoundNum
	FROM IonSF.MarchMadnessTableR4
	UNION ALL
	SELECT 
		R5Winner AS Winner
		,'D1' AS Division
		,'R5' AS RoundNum
	FROM IonSF.MarchMadnessTableR5
	UNION ALL
	SELECT 
		R6Winner AS Winner
		,'D1' AS Division
		,'R6' AS RoundNum
	FROM IonSF.MarchMadnessR6Table
	UNION ALL
	SELECT 
		R7Winner AS Winner
		,'D1' AS Division
		,'R7' AS RoundNum
	FROM IonSF.MarchMadnessTableR7
	UNION ALL
	SELECT 
		R8Winner AS Winner
		,'D1' AS Division
		,'Final Round' AS RoundNum
	FROM IonSF.MarchMadnessTableR8
	UNION ALL
	SELECT 
		R1Winner AS Winner
		,'D2' AS Division
		,'R1' AS RoundNum
	FROM IonSF.MarchMadnessTableR1D2Locked mmtrl 
	UNION ALL
	SELECT 
		R2Winner AS Winner
		,'D2' AS Division
		,'R2' AS RoundNum
	FROM IonSF.MarchMadnessTableR2D2
	UNION ALL
	SELECT 
		R3Winner AS Winner
		,'D2' AS Division
		,'R3' AS RoundNum
	FROM IonSF.MarchMadnessR3D2Table
	UNION ALL
	SELECT 
		R4Winner AS Winner
		,'D2' AS Division
		,'R4' AS RoundNum
	FROM IonSF.MarchMadnessTableR4D2
	UNION ALL
	SELECT 
		R5Winner AS Winner
		,'D2' AS Division
		,'R5' AS RoundNum
	FROM IonSF.MarchMadnessTableR5D2
	UNION ALL
	SELECT 
		R6Winner AS Winner
		,'D2' AS Division
		,'R6' AS RoundNum
	FROM IonSF.MarchMadnessR6D2Table
	UNION ALL
	SELECT 
		R7Winner AS Winner
		,'D2' AS Division
		,'R7' AS RoundNum
	FROM IonSF.MarchMadnessTableR7D2
	UNION ALL
	SELECT 
		R8Winner AS Winner
		,'D2' AS Division
		,'Final Round' AS RoundNum
	FROM IonSF.MarchMadnessTableR8D2
	UNION ALL
	SELECT
		R1Winner AS Winner
		,'Closer' AS Division
		,'R1' AS RoundNum
	FROM IonSF.MMCloserR1Table mrt 
	UNION ALL
	SELECT
		R2Winner AS Winner
		,'Closer' AS Division
		,'R2' AS RoundNum
	FROM IonSF.MMCloserR2
	UNION ALL
	SELECT
		R3Winner AS Winner
		,'Closer' AS Division
		,'R3' AS RoundNum
	FROM IonSF.MMCloserR3
	UNION ALL
	SELECT
		R4Winner AS Winner
		,'Closer' AS Division
		,'R4' AS RoundNum
	FROM IonSF.MMCloserR4
	UNION ALL
	SELECT
		R5Winner AS Winner
		,'Closer' AS Division
		,'R5' AS RoundNum
	FROM IonSF.MMCloserR5
	UNION ALL
	SELECT
		R6Winner AS Winner
		,'Closer' AS Division
		,'Final Round' AS RoundNum
	FROM IonSF.MMCloserR6
)
SELECT 
	RoundNum
	,Division
	,Winner
	,rit.active__c
	,rit.Shirt_Size
	,rit.Hat_Size 
	,rit.Pant_Short_Size 
	,rit.Pant_Length 
	,rit.Pant_Waist 
	,rit.Shoe_Size 
FROM Combined c
LEFT JOIN IonSF.Rep_Info_Table rit ON rit.name = c.Winner
GROUP BY 1,3