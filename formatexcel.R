# Load the openxlsx library if not already installed
# if (!requireNamespace("openxlsx", quietly = TRUE)) {
#  install.packages("openxlsx")
# }
library(openxlsx)

# Set the directory where your Excel files are located
input_directory <- "~/Downloads/MCJCHVMatrices"

# User-defined column widths
col1_width <- 18 #name
col2_width <- 10 #dept
col3_width <- 8
col4_width <- 8
col5_width <- 8
col6_width <- 8
col7_width <- 8
col8_width <- 8
col9_width <- 8
col10_width <- 8
col11_width <- 8
col12_width <- 8
col13_width <- 8
col14_width <- 8
col15_width <- 8
col16_width <- 8
col17_width <- 25 #Primary template
col18_width <- 25
col19_width <- 25
col20_width <- 25
col21_width <- 25
col22_width <- 25
col23_width <- 25
col24_width <- 25
col25_width <- 8 #last access
col26_width <- 10 #compliance
col27_width <- 16 #security rec
row1_height <- 84 #header
rows_height <- 80 #user rows 

# List all Excel files in the directory
excel_files <- list.files(path = input_directory, pattern = "\\.xlsx$", full.names = TRUE)

# Check if any Excel files were found
if (length(excel_files) == 0) {
  stop("No Excel files (.xlsx) found in the specified directory.")
}

# Loop through each Excel file
for (file in excel_files) {
  # Check if the file exists
  if (!file.exists(file)) {
    cat("File does not exist:", file, "\n")
    next  # Skip to the next file
  }  # Load the Excel file
  wb <- loadWorkbook(file, xlsxFile = NULL)
  
  # Get the names of all sheets in the Excel file (assuming one sheet here)
  sheet_names <- getSheetNames(file)
  
  # Read the data from the first sheet
  sheet <- read.xlsx(wb, sheet = sheet_names[1])
  sheet <- subset(sheet, select = -1)
  name=sheet[2]
  sheet <- subset(sheet, select = -2)
  sheet=cbind(name, sheet)
  
  # Add conditional field 
  sheet$Compliance <- rep("", nrow(sheet))  # Default to "Yes"
  colnames(sheet)[ncol(sheet)] <- "Compliance"
  
  # Create a drop-down list for "Compliance" column
  compliance_choices <- c("Yes", "No")
  dataValidation(wb, 1, col = 26, rows = 2:(nrow(sheet)+1), type = "list", value = '",Yes,No"')
  
  # Add "Notes" column
  sheet$Notes <- ""  # Initialize with empty strings
  colnames(sheet)[ncol(sheet)] <- "Security Recommendation"
 
  # Set Column widths and Row heights
  setColWidths(wb, sheet = sheet_names[1], cols = 1:ncol(sheet), widths = c(col1_width, col2_width, col3_width, col4_width, col5_width, col6_width, col7_width, col8_width, col9_width, col10_width, col11_width, col12_width, col13_width, col14_width, col15_width, col16_width, col17_width, col18_width, col19_width, col20_width, col21_width, col22_width, col23_width, col24_width, col25_width, col26_width, col27_width))
  setRowHeights(wb, sheet = sheet_names[1], rows = 1, heights = row1_height )
  setRowHeights(wb, sheet = sheet_names[1], rows = 2:nrow(sheet), heights = rows_height )
  
  # Reformat the sheet
  alternating_color <- c("white", "lightsteelblue1")
  unique_users <- unique(sheet$Epic.User.Name)
  
  user_colors <- alternating_color[seq_along(unique_users) %% 2 + 1]
  
  for (i in 1:length(unique_users)) {
    rows_to_format <- which(sheet$Epic.User.Name == unique_users[i])
    for (j in rows_to_format) {
      addStyle(wb, sheet = sheet_names[1], style = createStyle(fgFill = user_colors[i], wrapText = TRUE, halign = "left", valign = "center",fontName = "Arial", fontSize = 8), rows = j + 1, cols = 1:ncol(sheet))
     }
  }
  
  # Create header
  addStyle(wb, sheet = sheet_names[1], style = createStyle(fgFill = "lightgrey", halign = "center", valign = "center", wrapText = TRUE, textDecoration = "bold", fontName = "Arial", fontSize = 8), rows = 1, cols = 1:27)
  # Remove dots from header
  names(sheet) <- gsub(x = names(sheet), pattern = "\\.", replacement = " ")  
  
  # Add conditional formatting
  yescolor <- createStyle(bgFill = "green")
  nocolor <- createStyle(bgFill = "red")
  conditionalFormatting(wb, 1, cols = 26, rows = 1:nrow(sheet), type = "contains",  rule = "Yes", style = yescolor)
  conditionalFormatting(wb, 1, cols = 26, rows = 1:nrow(sheet), type = "contains",  rule = "No", style = nocolor)
  
  # Write the modified dataframe back to the Excel file
  writeData(wb, sheet = sheet_names[1],x = sheet)
  writeData
  
  # Save the reformatted Excel file with "_formatted" appended to the filename
  output_file <- sub(".xlsx$", "_formatted.xlsx", file)
  saveWorkbook(wb, file = output_file)
  cat("File saved:", output_file, "\n")
}