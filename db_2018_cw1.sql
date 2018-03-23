-- Q1 returns (name,father,mother)
SELECT name, father, mother
FROM person
WHERE dod <     (SELECT dod
		FROM person AS person_father
		WHERE person_father.name = person.father)
AND dod < 	(SELECT dod
		FROM person AS person_mother
		WHERE person_mother.name = person.mother)
;

-- Q2 returns (name)
SELECT name
FROM monarch
WHERE house IS NOT NULL
UNION
SELECT name
FROM prime_minister
ORDER BY name
;

-- Q3 returns (name)
SELECT monarch.name
FROM monarch
JOIN person
ON monarch.name = person.name
WHERE EXISTS(	SELECT name
		FROM monarch AS comparison
		WHERE comparison.accession > monarch.accession
		AND comparison.accession < person.dod)
AND house IS NOT NULL
ORDER BY name
;

-- Q4 returns (house,name,accession)
SELECT house, name, accession
FROM monarch
WHERE accession <= ALL(	SELECT accession
			FROM monarch AS comparison
			WHERE comparison.house = monarch.house)
AND house IS NOT NULL
ORDER BY accession
;

-- Q5 returns (first_name,popularity)
SELECT CASE WHEN name LIKE '% %' THEN SUBSTRING(name FROM 1 FOR POSITION(' ' IN name)-1)
	ELSE name END as first_name,
	COUNT(name) AS popularity
FROM person
GROUP BY 1
HAVING COUNT(name)>1
ORDER BY COUNT(name) DESC
;

-- Q6 returns (house,seventeenth,eighteenth,nineteenth,twentieth)
SELECT house, 
       COUNT(CASE WHEN CAST(accession AS CHAR(10)) LIKE '16%' THEN 
	accession ELSE null END) AS seventeenth,
       COUNT(CASE WHEN CAST(accession AS CHAR(10)) LIKE '17%' THEN
	accession ELSE null END) AS eighteenth,
       COUNT(CASE WHEN CAST(accession AS CHAR(10)) LIKE '18%' THEN
	accession ELSE null END) AS nineteenth,
       COUNT(CASE WHEN CAST(accession AS CHAR(10)) LIKE '19%' THEN
	accession ELSE null END) AS twentieth
       FROM monarch
       WHERE house IS NOT NULL
       GROUP BY 1
;

-- Q7 returns (father,child,born)
SELECT father, child, CASE WHEN child IS NOT NULL THEN 
	RANK() OVER (PARTITION BY father ORDER BY child_dob)
	ELSE NULL END AS born
FROM(
SELECT men.name AS father, fathers.name AS child, fathers.dob AS child_dob
FROM person AS men
LEFT JOIN person AS fathers
ON men.name = fathers.father
WHERE men.gender = 'M') AS father_child_dob
;

-- Q8 returns (monarch,prime_minister)
SELECT DISTINCT royal.name as monarch, pm.name as prime_minister
FROM(
SELECT name, entry, 
	COALESCE(LAG(entry) OVER (ORDER BY entry DESC),CURRENT_DATE-1) AS exit
FROM prime_minister) as pm
JOIN(
SELECT name, accession, 
	CASE WHEN name NOT IN(
		SELECT monarch.name
		FROM monarch
		JOIN person
		ON monarch.name = person.name
		WHERE EXISTS(	SELECT name
				FROM monarch AS comparison
				WHERE comparison.accession > monarch.accession
				AND comparison.accession < person.dod))
		AND house IS NOT NULL
	THEN COALESCE(dod,CURRENT_DATE-1) 
	ELSE LEAD(accession) OVER (ORDER BY accession) END AS step_down
FROM monarch
NATURAL JOIN person) as royal
ON royal.accession < pm.exit
AND royal.step_down > pm.entry
ORDER BY 1,2
;
