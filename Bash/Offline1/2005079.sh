#!/opt/homebrew/bin/bash


#################################################################
# Create or clear directories
#################################################################
mkdir -p issues checked temp
rm -rf issues/* checked/* temp/*
issues_dir="issues"
checked_dir="checked"
temp_dir="temp"
csv_file="marks.csv"
> "$csv_file"
echo "Student ID, Marks, Marks Deducted, Total Marks, Remarks" >> "$csv_file"


#################################################################
# Check if input file is provided
#################################################################
if [ $# -eq 0 ]; 
then
    echo "No input file provided"
    exit 1
fi
input_file=$1


#################################################################
# Read and check the input file
#################################################################
if [ -f "$input_file" ]; 
then
	i=1
	while IFS=$'\r\n' read -r line || [ -n "$line" ]; 
    do
        case $i in 
        1)
            if [ "$line" == "true" ] || [ "$line" == "false" ]; 
            then 
                archived_status=$line
                echo "Archive status: $line"
            else 
                echo "Input file information error in archive format."
                exit 1
            fi
            ;;
        2)
            read -a zip_formats <<< "$line"
            for format in ${zip_formats[@]} 
            do
                if [ "$format" != "zip" ] && [ "$format" != "rar" ] && [ "$format" != "tar" ]; 
                then
                    echo "Input file information error in allowed archive format."
                    exit 1
                fi
            done
            echo "Allowed archived formats: ${zip_formats[@]}"
            ;;
        3)
            read -a langs <<< "$line"
            for lang in ${langs[@]} 
            do
                if [ "$lang" != "c" ] && [ "$lang" != "cpp" ] && [ "$lang" != "python" ] && [ "$lang" != "sh" ]; 
                then
                    echo "Input file information error in allowed programming languages."
                    exit 1
                fi
            done
            echo "Allowed programming languages: ${langs[@]}"
            ;;
        4)
            if [[ "$line" =~ ^[0-9]+$ ]]; 
            then
                total_marks=$line
                echo "Total marks: $total_marks"
            else
                echo "Input file information error in total marks."
                exit 1
            fi
            ;;
        5)
            if [[ "$line" =~ ^[0-9]+$ ]]; 
            then
                output_penalty=$line
                echo "Output penalty: $output_penalty"
            else
                echo "Input file information error in output penalty."
                exit 1
            fi
            ;;
        6)
            if [ -d "$line" ]; 
            then
                working_dir=$line 
                echo "Working directory: $working_dir"
            else
                echo "Input file information error, $line is not a valid directory."
                exit 1
            fi
            ;;
        7) 
            read -a roll <<< "$line"
            if [ ${#roll[@]} -eq 2 ] && [[ "${roll[0]}" =~ ^[0-9]+$ ]] && [[ "${roll[1]}" =~ ^[0-9]+$ ]] && [[ ${roll[0]} -lt ${roll[1]} ]]; 
            then
                first_roll=${roll[0]}
                last_roll=${roll[1]}
                echo "First student ID: $first_roll, Last student ID: $last_roll"
            else
                echo "Input file information error in student ID range."
                exit 1
            fi
            ;;
        8)
            if [ -f "$line" ]; 
            then
                expected_output_file=$line 
                echo "Output file location: $expected_output_file"
            else
                echo "Input file information error, no file found at $line."
                exit 1
            fi
            ;;
        9)
            if [[ "$line" =~ ^[0-9]+$ ]]; 
            then
                submission_penalty=$line
                echo "Submission guideline violation penalty: $submission_penalty"
            else
                echo "Input file information error in submission guideline violation penalty."
                exit 1
            fi
            ;;
        10)
            if [ -f "$line" ]; 
            then
                plagiarism_file_path=$line 
                echo "Plagiarism analysis file location: $plagiarism_file_path"
            else
                echo "Input file information error, no file found at $line."
                exit 1
            fi
            ;;
        11)
            if [[ "$line" =~ ^[0-9]+$ ]]; 
            then
                plagiarism_penalty=$line
                echo "Plagiarism penalty: $plagiarism_penalty"
            else
                echo "Input file information error in Plagiarism penalty."
                exit 1
            fi
            ;;
        esac
		((i++))
	done < "$input_file"
    echo ""
    # Change extention to py
    for (( i=0; i<${#langs[@]}; i++ )); 
    do
        if [ "${langs[$i]}" == "python" ]; 
        then
            langs[$i]="py"
            break
        fi
    done
else
	echo "Enter a valid file name"
	exit
fi


#################################################################
# Check the plagiarism file
#################################################################
mapfile -t plagiarism_id < "$plagiarism_file_path"
check_plagiarism() {
    id=$1
    remark=$2
    obtained_marks=$3
    for (( i=0; i<${#plagiarism_id[@]}; i++ )); 
    do
        if [ "${plagiarism_id[$i]}" == "$id" ]; 
        then
            remark+="Plagiarism detected (-$plagiarism_penalty%)."
            obtained_marks=$(( (plagiarism_penalty * total_marks / 100) * -1 ))
            break
        fi
    done
}


#################################################################
# Function to unarchive and move files 
#################################################################
unarchive() {
    submission_path=$1
    student_id=$2
    deducted_marks=$3
    remark=$4
    case "$submission_path" in
    *.zip) 
        unzip "$submission_path" -d "$temp_dir" 
        ;;
    *.rar) 
        unrar x "$submission_path" "$temp_dir" 
        ;;
    *.tar) 
        tar -xf "$submission_path" -C "$temp_dir" 
        ;;
    esac
    extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d)
    # Check if the extracted directory name matches the student id
    if [ "$(basename "$extracted_dir")" != "$student_id" ]; 
    then
        mv "$extracted_dir" "$issues_dir/$student_id"
        ((deducted_marks += $submission_penalty))
        remark+="Issue 4: The extracted folder name does not match the student ID. "
    else
        mv "$extracted_dir" "$issues_dir"
    fi
}


#################################################################
# Function to process submission
#################################################################
process_submission() {
    local student_id=$1
    local submission_path=$2
    local submission_file=$3
    local deducted_marks=0
    local obtained_marks=0
    local remark=""
    # Handle folder submission
    if [[ -d "$submission_path" ]]; 
    then
        cp -rp "$submission_path" "$issues_dir"
        ((deducted_marks += $submission_penalty))
        remark+="Issue 1: The submission is a folder. "
    # Handle files
    else 
        match_found=false
        extension="${submission_path##*.}"
        for format in "${zip_formats[@]}"; 
        do
            if [[ "$extension" == "$format" ]]; 
            then
                match_found=true
                break
            fi
        done
        # Handle zipped file 
        if $match_found; 
        then
            unarchive "$submission_path" "$student_id" "$deducted_marks" "$remark"
        # Handle other files
        else
            if [ $archived_status == "true" ]; 
            then
                remark+="Issue 2: The submitted file is not in an allowed archive format."
            else 
                mkdir -p "$issues_dir/$student_id"
                cp -rp "$submission_path" "$issues_dir/$student_id"
            fi
        fi
    fi
    run_code "$student_id" "$issues_dir/$student_id" "$deducted_marks" "$remark" "$obtained_marks"
}


#################################################################
# Function to run code
#################################################################
run_code() {
    local student_id=$1
    local student_folder=$2
    local deducted_marks=$3
    local remark=$4
    local obtained_marks=$5
    for lang in "${langs[@]}"; 
    do
        code_file=$(find "$student_folder" -name "*.$lang")
        if [ -n "$code_file" ];
        then 
            break 
        fi 
    done
    extension="${code_file##*.}"
    case "$extension" in
    c) 
        gcc "$code_file" -o "$student_folder/$student_id.out"
        ./"$student_folder/$student_id.out" > "$student_folder/${student_id}_output.txt"
        ;;
    cpp) 
        g++ "$code_file" -o "$student_folder/$student_id.out"
        ./"$student_folder/$student_id.out" > "$student_folder/${student_id}_output.txt"
        ;;
    py) 
        python "$code_file" > "$student_folder/${student_id}_output.txt"
        ;;
    sh) 
        bash "$code_file" > "$student_folder/${student_id}_output.txt"
        ;;
    *)
        if  [ -z "$remark" ];
        then 
            remark+="Issue 3: The submitted file is not in an allowed programming language."
        fi 
        ((deducted_marks += $submission_penalty))
        ((obtained_marks = $obtained_marks - deducted_marks))
        ;;
    esac
    compare_output "$student_id" "$student_folder" "$student_folder/${student_id}_output.txt" "$deducted_marks" "$remark" "$obtained_marks"
}


#################################################################
# Function to compare output
#################################################################
compare_output() {
    local student_id=$1
    local student_folder=$2
    local student_output=$3
    local deducted_marks=$4
    local remark=$5
    local marks=0
    local deduct=0
    local obtained_marks=$6
    if [ -f "$student_output" ]; 
    then
        while IFS=$'\r\n' read -r expected_line; 
        do
            if ! grep -Fxq "$expected_line" "$student_output"; 
            then
                ((deduct += $output_penalty))
            fi
        done < "$expected_output_file"
        ((marks += $total_marks))
        ((marks -= $deduct))
        # Move the folders to the checked directory
        mv "$student_folder" "$checked_dir"
        obtained_marks=$((marks - deducted_marks))
        check_plagiarism "$student_id" "$remark" "$obtained_marks"
    # else
        # remark="Submission error. " 
    fi
    # Write in the marks.csv report
    echo "$student_id, $marks, $deducted_marks, $obtained_marks, $remark" >> $csv_file
}


#################################################################
# Processing submissions 
#################################################################
for (( id=$first_roll; id<=$last_roll; id++ )); 
do 
    found=false
    for submission in "$working_dir"/*; 
    do
        student_id=$(basename "$submission" | cut -d. -f1)
        if [[ "$student_id" == $id ]];
        then
            found=true
            process_submission "$student_id" "$submission" "$(basename "$submission")"
            break 
        fi
    done
    if [[ "$found" == false ]]; 
    then
        echo "$id, 0, 0, $total_marks, "Submission not found."" >> $csv_file
    fi
done


#################################################################
# End evaluation
#################################################################
rmdir "$temp_dir"
echo ""
echo "Grading complete."
echo "Check the marks.csv file and the 'issues' and 'checked' directories."
echo ""
