#url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/sadun_lista_0423.csv"
#download.file(url, destfile = "sadun_lista.csv")

satu_list <- read.csv(file = "sadun_lista.csv", 
                      header = TRUE, 
                      sep = ";", 
                      fileEncoding = "ISO-8859-1", 
                      stringsAsFactors = FALSE)

satu_list <- satu_list[-nrow(satu_list), ]

# Load necessary library
library(ggplot2)

# Count the number of publications per year
data <- as.data.frame(table(satu_list$Publication.year))

# Rename columns for clarity
colnames(data) <- c("PublicationYear", "PublicationCount")

# Convert PublicationYear to numeric for proper plotting
data$PublicationYear <- as.numeric(as.character(data$PublicationYear))


#     title = "Fennican kaunokirjallisuusnimikkeiden julkaisumäärät 1809-1917",
#     subtitle = "N = 9211",
#     caption = "Koonti: Satu Niininen, kaavio: Julia Matveeva (2024)",


p2 <- ggplot(data, 
             aes(x = factor(PublicationYear), y = PublicationCount)) +
  geom_bar(stat = "identity", fill = "black" , width = 0.5) +
  labs(
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    x = NULL,
    y = "Julkaisumäärä (N)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, vjust = 1),
    plot.subtitle = element_text(hjust = 0.5, vjust = 0.5),
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 10),  # Horizontal labels with center alignment
    axis.ticks.x = element_line(color = "black", linewidth = 0.5)       # Darker and more visible tick marks
  ) +
  scale_x_discrete(drop = FALSE, breaks = c(1809, seq(1820, 1917, by = 10), 1917)) +
  theme(axis.text.x = element_text(angle = 0, hjust = 1, size = 9))+
  annotate("text", x = 5, y = max(data$PublicationCount) + 50, label = "N = 9211", hjust = 0, vjust = 1, size = 4)


show(p2)


###################################################

# Load necessary library
library(ggplot2)
# Data
Kaikki <- 9211
Lasten.kirj <- 1017
Kaikki.aik <- 8194
Aik.kirj.kotimaisilla.kielillä <- 4467
Aik.kirj.kotimaisille.käännetyt <- 2046
Aik.kirj.vieraskieliset <- 123
Aik.kirj.muut.käännökset <- 826
Aik.kirj.epäselvät <- 732


# Create a data frame
data <- data.frame(
  Category = c("Kotimaisilla kielillä",
               "Kotimaisille käännetyt", 
               "Vieraskieliset", 
               "Muut käännökset",
               "Epäselvät"),
  Value = c(Aik.kirj.kotimaisilla.kielillä,
            Aik.kirj.kotimaisille.käännetyt, 
            Aik.kirj.vieraskieliset, 
            Aik.kirj.muut.käännökset, 
            Aik.kirj.epäselvät)
)

# Add a new column for percentage
data$Percentage <- (data$Value / Kaikki.aik) * 100

# Set the order of bars
data$Category <- factor(data$Category, levels = c(
  "Epäselvät",
  "Muut käännökset",
  "Vieraskieliset", 
  "Kotimaisille käännetyt",
  "Kotimaisilla kielillä"
))

# Create the bar plot
plot <- ggplot(data, aes(x = Value, y = Category)) +
  geom_bar(stat = "identity", fill = "gray30", width = 0.4) +
  # Add text annotations with percentage
  geom_text(aes(label = paste(Value, " (", round(Percentage, 1), "%)", sep = "")), 
            vjust = ifelse(data$Value > 3000, 0.5, 0.4),  # Place labels inside for large values, above for small ones
            hjust = ifelse(data$Value < 3000, -0.1, 1.1),  # Align text left for large values, right for small ones
            color = ifelse(data$Category %in% c("Kotimaisille käännetyt", "Vieraskieliset", "Epäselvät", "Muut käännökset"), "black", "white"),
            size = 3.5)+
  labs(
    x = "Julkaisumäärä (N)",
    y = NULL
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 1)
  ) +
  # Add the total annotation in the upper-right corner
  annotate("text", 
           x = max(data$Value) + 65,  # Add an offset to the max x value
           y = 1,                      # Position at the top (y value adjusted accordingly)
           label = paste("N = ", Kaikki.aik), 
           hjust = 1,                  # Align text to the right
           vjust = 1,                  # Align text to the top
           size = 4)                    # Text size for the annotation


# Print the plot
print(plot)

#N = 9211
ggsave("publication_plot_1.png", 
       plot = plot, 
       width = 7, 
       height = 3, 
       dpi = 300, 
       bg = "white")  # Set background color to white

#N = 8194
ggsave("publication_plot_1.1.png", 
       plot = plot, 
       width = 7, 
       height = 3, 
       dpi = 300, 
       bg = "white")  # Set background color to white

ggsave("publication_plot_2.png", 
       plot = p2, 
       width = 8, 
       height = 4, 
       dpi = 300, 
       bg = "white")  # Set background color to white