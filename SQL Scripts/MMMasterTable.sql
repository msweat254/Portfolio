CREATE OR REPLACE VIEW IonSF.MMMasterTable AS
SELECT *,
	'R1' AS RoundNum
FROM IonSF.MarchMadnessTableR1Locked mmtrl 
GROUP BY Setter_A  
UNION ALL 
SELECT *,
	'R2' AS RoundNum
FROM IonSF.MarchMadnessTableR2 mmtr 
GROUP BY Setter_A 
UNION ALL
SELECT *,
	'R3' AS RoundNum
FROM IonSF.MarchMadnessR3Table mmrt 
GROUP BY WINNER_A
UNION ALL 
SELECT *,
	'R4' AS RoundNum
FROM IonSF.MarchMadnessTableR4 mmtr2 
GROUP BY Setter_A 
UNION ALL 
SELECT *,
	'R5' AS RoundNum
FROM IonSF.MarchMadnessTableR5 mmtr2 
GROUP BY Setter_A 
UNION ALL 
SELECT *,
	'R6' AS RoundNum
FROM IonSF.MarchMadnessR6Table mmrt2 
UNION ALL 
SELECT *,
	'R7' AS RoundNum
FROM IonSF.MarchMadnessTableR7 mmtr2 
UNION ALL 
SELECT *,
	'R8' AS RoundNum
FROM IonSF.MarchMadnessTableR8 mmtr2 