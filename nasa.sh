#!/bin/bash

# Author: Duy Phuc Tran
# Student #: 10418791
# Edith Cowan University


# Check NASA website is available or not. If not, exit the system.
websiteURL="apod.nasa.gov"
ping -q -c 1 -W 1 "$websiteURL" | echo -e "\nConnecting to nasa.gov...\n"
if [ $? = 0 ]; then
    echo ""
else
    echo "NASA website is now unavailable!"
    exit 1
fi


# This function receive 3 parameters: 1. Type of detail, 2. Command-line option, 3. Specific date
getDetailInfo () {
    #Check 2nd parameter is "-d" or "--date"
    if [ "$2" == "-d" ] || [ "$2" == "--date" ]; then
        doCheckValidDate $3 
        local date=$(doModifyDate "$3")
        dateContent=$(getWebsiteContent $date)
        getWebsiteDetail "$1" "$dateContent"
    else
        echo "Invalid command-line option for date. Please type --help for more information!"
        exit 0
    fi
}

# This function receive only 1 parameter: Specific date
doCheckValidDate () {
    local dateFormat=$(echo "$1" | grep -E '^([0-9]{4}-[0-9]{2}-[0-9]{2})+$')
    if [ "$dateFormat" == "" ]; then
        echo "Invalid date format! Must be yyyy-mm-dd. Please type --help for more information!"
        exit 1
    fi
}

# This function receive only 1 parameter: Specific date
# Return modified date
doModifyDate () {
    local date="${1:2:8}" # Substring date string starting from position 2 and take 8 characters after
    local date=$(echo "$date" | sed 's/-//g') # Remove "-" character
    echo "$date" 
}

# This function receive 1 parameter: 1. Specific date
# Return website content
getWebsiteContent () {
    local imageURL="https://apod.nasa.gov/apod/ap$1.html"
    echo $(curl -s "$imageURL") 
}

# This function receive 2 parameters: 1. Type of detail, 2. Command-line option
# Display image information 
getWebsiteDetail () {
    title=$(echo "$2" | sed -n 's:.*<title>\(.*\)</title>.*:\1:p' | awk 'BEGIN{FS="-"}{print $2}') 
    explanation=$(echo "$2" | grep -o '<b> Explanation.*<p> <center>' | sed -e 's/<[^>]*>//g' | sed "s/Explanation://g")
    credit=$(echo "$2" | grep -o '<b> Image Credit.*</center> <p> ' | sed -e 's/<[^>]*>//g' | sed 's/ Image Credit & Copyright: //')
    
    # Display detailed info 
    if [ $1 == "details" ]; then
        echo -e "TITLE: $title\nEXPLANATION:\n$explanation\nIMAGE CREDIT: $credit\nFinished."
    elif [ $1 == "explanation" ]; then 
        echo -e "$explanation\nFinished."
    fi
}

# This function receive 1 parameter: 1. Specific date
# Download image to local folder
doDownloadImage () {
    pageContent=$(getWebsiteContent $1)
    imgName=$(echo "$pageContent" | sed -n 's:.*<title>\(.*\)</title>.*:\1:p' | awk 'BEGIN{FS="-"}{print $2}') 
    imgURL=$(echo "$pageContent" | sed -E -n '/<IMG/s/.*SRC="([^"]*)".*/\1/p')
    echo "Downloading \"$imgName\""
    wget -qO "$imgName.jpg" "apod.nasa.gov/apod/$imgURL"
}

# Main process
case $1 in
    -h|--help) # Help menu
        echo -e "\nThese shell commands are defined internally.  Type 'help' to see this list.\n"
        echo -e "-d|--date [date]: \n\tType this to download the image posted on that date"
        echo -e "\tExample: -d 2019-01-01\n"
        echo -e "-t|--type [detail|explanation] -d|--date [date]: \n\tType this to download the title, explanation text and credit posted on that date"
        echo -e "\tExample: --type explanation --date 2019-01-01\n"
        echo -e "-r|--range [startDate] [endDate]: \n\tType this to download all images ported between startDate to endDate"
        echo -e "\tExample: --range 2019-01-01 2019-01-04\n";;

    -d|--date) # Download an image on specific date
        doCheckValidDate $2
        date=$(doModifyDate "$2")
        doDownloadImage $date
        echo "Finished.";;        

    -r|--range) # Download images between two specific dates
        if [ $# -eq 3 ]; then
            doCheckValidDate $2
            doCheckValidDate $3
            if [ $(date -d $3 +%s) -ge $(date -d $2 +%s) ]; then # Compare endDate is greater than startDate
                tempDate=$2
                count=0
                while [ $(date -d $tempDate +%s) -le $(date -d $3 +%s) ]; do # Loop until temporary date equals endDate 
                    date=$(doModifyDate "$tempDate")
                    doDownloadImage $date
                    count=$((count+1))
                    if [ $count -ge 10 ]; then
                        break
                    fi
                    tempDate=$(date -I -d "$tempDate + 1 day") # Increase temporary date by 1 day
                done
                echo "Finished."
            else
                echo "StartDate must lower than EndDate. Please type --help for more information!"
            fi
        else
            echo "Invalid input option for range. Please type --help for more information!"
            exit 1
        fi;;

    -t|--type) # Display details like title, explanation or credit on specific date
        if [ $2 == "details" ]; then          
            getDetailInfo "details" "$3" "$4"
        elif [ $2 == "explanation" ]; then
            getDetailInfo "explanation" "$3" "$4"            
        else
            echo "Invalid command-line option for type. Please type --help for more information!"
            exit 1
        fi;;
        
    *)
        echo "Invalid input. Please type --help for more information!"
        exit 1;;
esac