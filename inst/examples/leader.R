#unpack leader 

# 06 - Type of record
df.orig$type_of_record <- substr(df.orig$leader, start =  7, stop =  7)

df.orig <- df.orig %>%
  mutate(type_of_record = case_when(
    type_of_record == 'a' ~ 'Language material',
    type_of_record == 'c' ~ 'Notated music',
    type_of_record == 'd' ~ 'Manuscript notated music',
    type_of_record == 'e' ~ 'Cartographic material',
    type_of_record == 'f' ~ 'Manuscript cartographic material',
    type_of_record == 'g' ~ 'Projected medium',
    type_of_record == 'i' ~ 'Nonmusical sound recording',
    type_of_record == 'j' ~ 'Musical sound recording',
    type_of_record == 'k' ~ 'Two-dimensional nonprojectable graphic',
    type_of_record == 'm' ~ 'Computer file',
    type_of_record == 'o' ~ 'Kit',
    type_of_record == 'p' ~ 'Mixed materials',
    type_of_record == 'r' ~ 'Three-dimensional artifact or naturally occurring object',
    type_of_record == 't' ~ 'Manuscript language material'
  ))


# 07 - Bibliographic level
df.orig$bibliographic_level <- substr(df.orig$leader, start =  8, stop =  8)

df.orig <- df.orig %>%
  mutate(bibliographic_level = case_when(
    bibliographic_level == 'a' ~ 'Monographic component part',
    bibliographic_level == 'b' ~ 'Serial component part',
    bibliographic_level == 'c' ~ 'Collection',
    bibliographic_level == 'd' ~ 'Subunit',
    bibliographic_level == 'i' ~ 'Integrating resource',
    bibliographic_level == 'm' ~ 'Monograph/Item',
    bibliographic_level == 's' ~ 'Serial'
    # Add more conditions here if needed
  ))


