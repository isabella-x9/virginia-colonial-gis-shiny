# Load libraries
library(dplyr)
library(readr)

# Read the raw csv file
entities <- read_csv("/Users/izzi/Desktop/Duke/Data+/RShiny/entities.csv")

# Preview
print(head(entities))

# Removal of obvious chunky entities
entities_clean <- entities %>%
  filter(
    !grepl(
      "Vol|St\\.?|pp|III|II|No\\.|MS|TT|esq|Certification|Volume|fig|Pan|4 7|Zao",
      `ENTITY NAME`,
      ignore.case = TRUE
    ),
    nchar(`ENTITY NAME`) > 2  # filter out tiny tokens
  )

# Add a suspicious flag
entities_clean <- entities_clean %>%
  mutate(
    suspicious = case_when(
      grepl("[0-9]", `ENTITY NAME`) & LABEL != "CARDINAL" ~ TRUE,
      LABEL == "PERSON" & grepl("\\d", `ENTITY NAME`) ~ TRUE,
      LABEL %in% c("GPE", "LOC") & grepl("\\d", `ENTITY NAME`) ~ TRUE,
      TRUE ~ FALSE
    )
  )

# Print out the suspicious rows
print(entities_clean %>% filter(suspicious))

# Output a file for manual review
write_csv(entities_clean %>% filter(suspicious), "suspect_entities.csv")

# Also save the cleaned file for mapping
write_csv(entities_clean, "entities_clean.csv")

