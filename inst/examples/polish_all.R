message("Entry identifier to match back to the originals")
df.preprocessed <- data.frame(melinda_id = df.orig$melinda_id)

# List how raw data fields will be converted into
# preprocessed data fields
conversions <- list()

# Define the fields
update.fields <- setdiff(names(df.orig), c("melinda_id", "physical_dimensions"))

# Harmonize title field
source("physical_dimensions.R")

# ---------------------------------------------------

# Harmonize the rest of the fields
for (field in update.fields) {

    message(field)

    # Run the processing script for this field
    source(paste0(field, ".R"))

    # List the output fields for this input field to output fields
    conversions[[field]] <- names(df.tmp)

    # Add the newly preprocessed field
    # FIXME: collect afterwards
    df.preprocessed <- cbind(df.preprocessed, df.tmp)

    # Remove the temporary data.frame for clarity
    rm(df.tmp)

}

message("Field preprocessing ok.")



