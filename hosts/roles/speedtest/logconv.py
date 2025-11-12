import csv


# used to convert old fast.csv to one with channel column

input_path = "fast.csv"
output_path = input_path + ".tmp"

with open(input_path, newline="", encoding="utf-8") as inf, \
     open(output_path, "w", newline="", encoding="utf-8") as outf:
    reader = csv.DictReader(inf, delimiter='\t')
    # add the new column name to the output fieldnames
    fieldnames = reader.fieldnames + ["channels"]
    writer = csv.DictWriter(outf, fieldnames=fieldnames, delimiter="\t")
    writer.writeheader()

    for row in reader:
        new_value = "X" 
        row['channels'] = new_value
        writer.writerow(row)

# replace the original file atomically
#os.replace(output_path, input_path)
