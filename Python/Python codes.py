# splitting the directors and writers columns from title.crew dataset
import pandas as pd

title_crew = pd.read_csv('title.crew.tsv', sep='\t')

# Split the 'directors' column
title_directors = title_crew.assign(directors=title_crew['directors'].str.split(',')) \
                            .explode('directors') \
                            .rename(columns={'directors': 'director_id'}) \
                            .dropna(subset=['director_id'])

print(title_directors[['tconst', 'director_id']])

# Split the 'writers' column
title_writers = title_crew.assign(writers=title_crew['writers'].str.split(',')) \
                          .explode('writers') \
                          .rename(columns={'writers': 'writer_id'}) \
                          .dropna(subset=['writer_id'])

print(title_writers[['tconst', 'writer_id']])

title_directors[['tconst', 'director_id']].to_csv('title.directors.tsv', sep='\t', index=False)

title_writers[['tconst', 'writer_id']].to_csv('title.writers.tsv', sep='\t', index=False)



# File Splitter for Large TSV
import os

input_file = "title_principals.tsv" 
output_dir = "title_principals"   
lines_per_file = 1000000       

os.makedirs(output_dir, exist_ok=True)

with open(input_file, "r", encoding="utf-8") as infile:
    header = infile.readline()  
    file_count = 0
    lines = []

    for line_number, line in enumerate(infile, start=1):
        lines.append(line)
        if line_number % lines_per_file == 0:
            with open(f"{output_dir}/part_{file_count}.tsv", "w", encoding="utf-8") as outfile:
                outfile.write(header) 
                outfile.writelines(lines)
            lines = []
            file_count += 1

    
    if lines:
        with open(f"{output_dir}/part_{file_count}.tsv", "w", encoding="utf-8") as outfile:
            outfile.write(header)
            outfile.writelines(lines)


# Batch TSV Importer to MySQL
import os
import mysql.connector
import pymysql

conn = pymysql.connect(
    host="localhost",
    user="root",
    password="SSSS",
    database="IMDb",
)
cursor = conn.cursor()

folder_path = "title_akas"

files = [f for f in os.listdir(folder_path) if f.endswith(".tsv")]
print(files)

for file in files:
    file_path = os.path.join(folder_path, file)
    print(f"Importing: {file_path}")
    
    query = f"""
    LOAD DATA LOCAL INFILE '{file_path.replace("\\", "/")}'
    INTO TABLE title_akas
    FIELDS TERMINATED BY '\\t'
    LINES TERMINATED BY '\\n'
    IGNORE 1 ROWS;
    """
    try:
        cursor.execute(query)
        conn.commit()
        print(f"Import file {file} was successful")
    except Exception as e:
        print(f"Error in importing {file}: {e}")

cursor.close()
conn.close()


