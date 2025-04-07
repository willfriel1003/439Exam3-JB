#!/usr/bin/env bash

#Usage: Given a csv from Project Feederwatch, will output two files: 
#       1. A file containing all instances of a species that is observed only once
#       2. A file containing all instances of a species that is observed once in a single year

#How to run: find_rare_birds.sh [list of csv files]

# Assigning a name to the input file
input_file="$1"

# Adding path to info connecting species_code to common and scientific name
bird_info="$HOME/../shared/439539/birds/bird-info"

# Output file for species observed once in all observations
output_once_ever="species_once_all_time.csv"
# Output file for species observed once in a specific year
output_once_in_year="species_once_in_year.csv"

# Adding headers to the output files
echo "SPECIES_CODE,scientific_name,common_name,Year,LOC_ID,LATITUDE,LONGITUDE,SUBNATIONAL1_CODE" > "$output_once_ever"
echo "SPECIES_CODE,scientific_name,common_name,Year,LOC_ID,LATITUDE,LONGITUDE,SUBNATIONAL1_CODE" > "$output_once_in_year"

# Part 1: Find species observed exactly once across all years
echo "Processing species observed once across all data"

# Finding species codes that appear only once in the input file 
# Tail ignores header, then cut species codes, sort them, get a count of unique codes, print only codes appearing once
tail -n +2 "$input_file" | cut -d',' -f12 | sort | uniq -c | awk '$1 == 1 {print $2}' | while read species_code; do
    # Remove surrounding quotes from species_code if present
    species_code=$(echo "$species_code" | sed 's/"//g')

    # Skip invalid or placeholder species_code like "species_code"
    if [[ "$species_code" == "species_code" || -z "$species_code" ]]; then
        continue
    fi

    # Find the species info from the bird_info file
    species_info=$(grep -i "\"$species_code\"" "$bird_info")

    # Debugging output for species info
    if [ -n "$species_info" ]; then

        # Extract the scientific_name and common_name based on their column positions in the bird_info file
        scientific_name=$(echo "$species_info" | cut -d',' -f4 | sed 's/"//g')  # sed removes any surrounding quotes
        common_name=$(echo "$species_info" | cut -d',' -f5 | sed 's/"//g')  # sed removes any surrounding quotes
        
        # Now, loop through the input file again to find the specific observation for this species
        grep "$species_code" "$input_file" | while IFS=',' read -r line; do
            loc_id=$(echo "$line" | cut -d',' -f1)               
            latitude=$(echo "$line" | cut -d',' -f2)              
            longitude=$(echo "$line" | cut -d',' -f3)             
            subnational1_code=$(echo "$line" | cut -d',' -f4)     
            Year=$(echo "$line" | cut -d',' -f10)  


            # Write the output to the CSV file for species observed once in all data
            echo "$species_code,$scientific_name,$common_name,$Year,$loc_id,$latitude,$longitude,$subnational1_code" >> "$output_once_ever"
        done

    fi

done

# Part 2: Find species observed once in a specific year
echo "Processing species observed once in a specific year"

# Tail ignores first row (headers of input), cutting columns for year and species_code, sorting them, extracting only lines with single instances of unique combinations of both
# After single instances of a species in a year are found, loops through bird-info to match common + scientific name
tail -n +2 "$input_file" | cut -d',' -f10,12 | sort | uniq -c | awk '{print $1 "," $2}' | while IFS=',' read count Year_column species_code_column; do
    # Remove surrounding quotes from species_code if present
    species_code=$(echo "$species_code_column" | sed 's/"//g')
    Year_column=$(echo "$Year_column")
    
    # Skip invalid or placeholder species_codes and years like "species_code" or "year"
    if [[ "$species_code_column" == "species_code" || -z "$species_code_column" || -z "$Year_column" ]]; then
        continue
    fi

#conditional only runs observation through loop if the species-year combination is unique
  if [ "$count" -eq 1 ]; then
  
    # Find the species info from the bird_info file
    species_info=$(grep -i "\"$species_code\"" "$bird_info")

    if [ -n "$species_info" ]; then
        # Extract the scientific_name and common_name based on their column positions in the bird_info file
        scientific_name=$(echo "$species_info" | cut -d',' -f4 | sed 's/"//g')  # Remove any surrounding quotes
        common_name=$(echo "$species_info" | cut -d',' -f5 | sed 's/"//g')  # Remove any surrounding quotes

        # Now, looping through the input file again to extract the relevant info of each species code and year identified earlier
        grep -w "$species_code" "$input_file" | grep -w "$Year_column" | while IFS=',' read -r line; do
            loc_id=$(echo "$line" | cut -d',' -f1)
            latitude=$(echo "$line" | cut -d',' -f2)
            longitude=$(echo "$line" | cut -d',' -f3)
            subnational1_code=$(echo "$line" | cut -d',' -f4)


            # Write the output to the CSV file for species observed once in the specific year
            echo "$species_code,$scientific_name,$common_name,$Year_column,$loc_id,$latitude,$longitude,$subnational1_code"  >> "$output_once_in_year"
        done 
    fi
  fi
done


# Completion message 
echo "Processing complete."
echo "Output files:"
echo "$output_once_ever"
echo "$output_once_in_year"
