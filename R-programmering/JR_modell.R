
# Regressionsanalys - Kunskapskontroll ----------------------------------------

# install.packages("fastDummies")
# install.packages("tidyverse")
# install.packages("moderndive")
# install.packages("caret")
# install.packages("pxweb")
# install.packages("corrplot")

library("readxl")
library("fastDummies")
library("ggplot2")
library(dplyr)
library(car)
library(moderndive)
library(caret)
library(leaps)
library(corrplot)
library(MASS)

library(pxweb)
# Hämta data från SCB med API och skapa plot
url <- "https://api.scb.se/OV0104/v1/doris/sv/ssd/START/TK/TK1001/TK1001A/FordonTrafik"
pxq <- pxweb_query("C:/Users/jakob/Blandat/Utbildning/Data Science/6_R-programmering/kunskapskontroll/query1.json")
pxd <- pxweb_get(url, pxq)
df_scb1 <- as.data.frame(pxd, column.name.type="text", variable.value.type="text")

names(df_scb1)[names(df_scb1) == 'Fordon i trafik'] <- 'Fordon_i_trafik'
ggplot(df_scb1, aes(år, Fordon_i_trafik)) +
  geom_line(aes(group=1), linewidth=2)

# Ladda in data
file_path <- "C:/Users/jakob/Blandat/Utbildning/Data Science/6_R-programmering/kunskapskontroll/data_insamling.xlsx"
raw_data <- read_excel(file_path) 

dim(raw_data)
head(raw_data)
str(raw_data)
summary(raw_data) 


# Städa data -----------------------------------------------------------

# ta bort "datum insamlad data"
raw_data <- subset(raw_data, select= -Datum_insamlad_data)

# kolla dubbletter och ta bort
sum(duplicated(raw_data[-1]))
unique_data <- unique(raw_data[-1])
dim(unique_data)

# ta bort "Datum i trafik" (vi har dagar i trafik)
# Ta bort Märke (alla är Volvo)
unique_data <- subset(unique_data, select = c(-Datum_i_trafik, -Märke))
dim(unique_data)

# döp om kolumn
colnames(unique_data)[colnames(unique_data) == "Försäljningspris"] <- "Pris"

# kolla saknade värden
colSums(is.na(unique_data))

# Inom vilka Bränsletyper återfinns NaN som Motorstorlek? Alla elbilar.
ggplot(unique_data, aes(is.na(Motorstorlek), fill=Bränsle)) +
  geom_bar()

unique_data$Motorstorlek[is.na(unique_data$Motorstorlek)] <- 0

# saknade värden
colSums(is.na(unique_data))
unique_data[!complete.cases(unique_data),c(4, 8, 9, 10, 12)]
# ta bort resterande saknade värden
data <- na.omit(unique_data)
colSums(is.na(data))
dim(data)

# Gör om Modellår till Ålder för bilen
max(data$Modellår)
data$Modellår <- (2024 - data$Modellår)
colnames(data)[colnames(data) == "Modellår"] <- "Ålder"

# Uteslut bilar äldre än 25 år
sum(data$Ålder > 25) # 19 st
data <- data[data$Ålder <= 25,]
dim(data)

# kolla efter extremer
summary(data) 

# Miltal har ett maxvärde (190724) som är nästan 10 gånger större än 3rd Q.
# Inte rimligt. Orsak är troligtvis felangivelse i annonsen (kilometer?).
# Dela med 10 och runda av till heltal för ett rimligare värde.
ggplot(data, aes(y=Miltal)) + geom_boxplot()
sum(data$Miltal>80000)
data$Miltal[data$Miltal > 80000] <- round(max(data$Miltal)/10)

# Fördelningen av antal bilar per biltyp
ggplot(data, aes(Biltyp)) + geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-1)

# gruppera Cab, Coupé, Familjebuss och Halvkombi i Övriga
data$Biltyp[data$Biltyp %in% c("Cab", "Coupé", "Familjebuss", "Halvkombi")] <- "Övriga"
ggplot(data, aes(Biltyp)) + geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-1)


# Exploratory Data Analysis -----------------------------------------------

# Vilka variabler hänger ihop med vilka? Vilka kan vi ta bort?
# pairplot all numeric. Miltal, Ålder och Dagar i trafik har liknande utseenden
num_cols <- select_if(data, is.numeric)
pairs(num_cols, data=data)

# Ålder vs Dagar i trafik. Nästan perfekt korrelation, räcker med den ena
# Miltal och Dagar i trafik har mycket hög korrelation.
cor(num_cols[c(1, 2, 3, 6)])

# pairplots avseende Säljare
pairs(num_cols[-3], data=data, col=factor(data$Säljare))
par(xpd=TRUE)
legend("bottomright", inset = 0.04, fill = unique(factor(data$Säljare)), legend = c(unique(factor(data$Säljare))))

# plot prisskillnad efter dagar i trafik, avseende Säljare
ggplot(data, aes(Dagar_i_trafik, Pris, col=Säljare)) +
  geom_point() +
  geom_smooth(method="lm", formula = y ~ poly(x, 3), se=FALSE)

# pairplots avseende Bränsle
pairs(num_cols[-3], data=data, col=factor(data$Bränsle))
par(xpd=TRUE)
legend("bottomright", inset = 0.02, fill = unique(factor(data$Bränsle)), legend = c(unique(factor(data$Bränsle))))

# plot prisskillnad efter dagar i trafik, avseende Bränsle
ggplot(data, aes(Dagar_i_trafik, Pris, col=Bränsle)) +
  geom_point() +
  geom_smooth(method="lm", formula = y ~ poly(x, 3), se=FALSE)

# pairplots avseende Växellåda
pairs(num_cols[-3], data=data, col=factor(data$Växellåda))
par(xpd=TRUE)
legend("bottomright", inset = 0.04, fill = unique(factor(data$Växellåda)), legend = c(unique(factor(data$Växellåda))))

# plot prisskillnad efter dagar i trafik, avseende Växellåda
ggplot(data, aes(Dagar_i_trafik, Pris, col=Växellåda)) +
  geom_point() +
  geom_smooth(method="lm", formula = y ~ poly(x, 3), se=FALSE)

# pairplots avseende Biltyp
pairs(num_cols[-3], data=data, col=factor(data$Biltyp))
par(xpd=TRUE)
legend("bottomright", inset = 0.04, fill = unique(factor(data$Biltyp)), legend = c(unique(factor(data$Biltyp))))

# plot prisskillnad efter dagar i trafik, avseende Biltyp
ggplot(data, aes(Dagar_i_trafik, Pris, col=Biltyp)) +
  geom_point() +
  geom_smooth(method="lm", formula = y ~ poly(x, 3), se=FALSE)

# pairplots avseende Drivning
pairs(num_cols[-3], data=data, col=factor(data$Drivning))
par(xpd=TRUE)
legend("bottomright", inset = 0.04, fill = unique(factor(data$Drivning)), legend = c(unique(factor(data$Drivning))))

# plot prisskillnad efter dagar i trafik, avseende Drivning
ggplot(data, aes(Dagar_i_trafik, Pris, col=Drivning)) +
  geom_point() +
  geom_smooth(method="lm", formula = y ~ poly(x, 3), se=FALSE)

# Spelar färgen roll på priset? Inget tydligt mönster
ggplot(data, aes(Ålder, Pris, col=Färg)) + geom_point()
ggplot(data, aes(Biltyp, Pris, col=Färg)) + geom_point()

# Spelar Modell roll? Biltyp och modell hänger ihop.
ggplot(data, aes(Dagar_i_trafik, Pris, col=Modell)) + geom_point()
ggplot(data, aes(Biltyp, Pris, col=Modell)) + geom_point()
ggplot(data, aes(Bränsle, Pris, col=Modell)) + geom_point()

# Kolla bara modeller inom SUV
ggplot(data, aes(Dagar_i_trafik, Pris)) + geom_point() +
  geom_point(data=subset(data, Biltyp == "SUV"), aes(col=Modell))
ggplot(data, aes(Dagar_i_trafik, Pris, col=Modell)) +
  geom_point(data=subset(data, Biltyp == "SUV")) +
  geom_smooth(data=subset(data, Biltyp == "SUV"), method="lm", se=FALSE)

# Kolla bara modeller inom Kombi
ggplot(data, aes(Dagar_i_trafik, Pris)) + geom_point() +
  geom_point(data=subset(data, Biltyp == "Kombi"), aes(col=Modell))
ggplot(data, aes(Dagar_i_trafik, Pris, col=Modell)) +
  geom_point(data=subset(data, Biltyp == "Kombi")) +
  geom_smooth(data=subset(data, Biltyp == "Kombi"), method="lm", se=FALSE)


# Skapa Dummy för XC90 (gör samma för val och test???)
data$XC90 <- ifelse(data$Modell == "XC90", 1, 0)

# Hänger Växellåda ihop med Biltyp? SUV mest automat
ggplot(data, aes(Växellåda, fill=Biltyp)) + geom_bar()
ggplot(data, aes(Biltyp, fill=Växellåda)) + geom_bar()

# Hänger Drivning ihop med Biltyp? Fyrhjulsdriven mest SUV + Kombi
ggplot(data, aes(Drivning, fill=Biltyp)) + geom_bar()
ggplot(data, aes(Biltyp, fill=Drivning)) + geom_bar()

# Spelar Motorstorlek roll? 
ggplot(data, aes(Pris, Motorstorlek)) + geom_point()

# Hänger Motorstorlek ihop med Hästkrafter? Inget tydligt samband
ggplot(data, aes(Hästkrafter, Motorstorlek, col=Drivning)) +
  geom_point()

# Med avseende på Biltyp
ggplot(data, aes(Ålder, Pris, col=Biltyp)) +
  geom_point() +
  geom_smooth(method="lm", se = FALSE) +
  scale_y_sqrt() +
  facet_wrap(~Biltyp)

ggplot(data, aes(Pris, Biltyp, col=Biltyp)) + geom_boxplot()

ggplot(data, aes(Ålder, fill=Biltyp)) + geom_bar()


# Filtrera bort Färg, Modell och Ålder
sapply(data, class)
selected_data <- subset(data, select = c(-Färg, -Modell, -Ålder))
sapply(selected_data, class)

# Undersök relationerna mellan Pris och de numeriska variablerna

# Relationen Pris vs Dagar i trafik. 
ggplot(selected_data, aes(Dagar_i_trafik, Pris)) +
  geom_point() +
  geom_smooth(method="lm", formula= y ~ x + I(x^1.3), color="red", se = FALSE)

# Relationen Pris vs Miltal
ggplot(selected_data, aes(Miltal, Pris)) +
  geom_point() +
  geom_smooth(method="lm", formula= y ~ poly(x, 3, raw=TRUE), color="red", se = FALSE)

# Reationen Pris vs Hästkrafter 
ggplot(selected_data, aes(Hästkrafter, Pris)) +
  geom_point() +
  geom_smooth(method="lm", color="red", se = FALSE)

# Relationen Pris vs Dagar i trafik, avseende på Bränsle
ggplot(selected_data, aes(Dagar_i_trafik, Pris, col=Bränsle)) +
  geom_point() +
  geom_smooth(method="lm", formula = y ~ poly(x, 3, raw=TRUE), se = FALSE) +
  facet_wrap(~Bränsle)


ggplot(selected_data, aes(Biltyp, fill=Bränsle)) + geom_bar()

ggplot(selected_data, aes(Bränsle, fill=Växellåda)) + geom_bar()

ggplot(selected_data, aes(Bränsle, fill=Växellåda)) +
  geom_bar(position="fill") +
  ylab("proportion")

ggplot(selected_data, aes(Växellåda, fill=Bränsle)) +
  geom_bar(position="fill") +
  ylab("proportion")


# Skapa Dummy variabler
num_data <- dummy_cols(selected_data, remove_first_dummy = TRUE, remove_selected_columns = TRUE)
sapply(num_data, class)
head(num_data)
summary(num_data)

# pairs(num_data)
# round(cor(num_data), 3)

# plot correlation matrix
par(mfrow = c(1, 1))
matrix <- cor(num_data) # Miltal och Dagar_i_trafik har stark negativ korrelation till Pris
corrplot(matrix, method = "number")


# Train/Validate/Test split -----------------------------------------------

# Dela upp data i training (80%) och test (20%)
spec = c(train = .8, test = .2)

set.seed(123)
result = split(num_data, sample(cut(
  seq(nrow(data)), nrow(data) * cumsum(c(0, spec)), labels = names(spec)
)))

train_data <- result$train
test_data <- result$test

dim(train_data)
dim(test_data)



# -------------------------------------------------------------------------

# Val av modell -----------------------------------------------------------

# -------------------------------------------------------------------------



# Modell 1 ----------------------------------------------------------------


# best subset selection - base
regfit_full <- regsubsets(Pris~., data = train_data, nvmax = 20)
sum_full <- summary(regfit_full)
sum_full
# Dagar i trafik, Hästkrafter, Miltal, Biltyp_SUV, XC90 / Bränsle_El

# Skapa modell utifrån best subset top 5.
lm_1 <- lm(Pris ~ Dagar_i_trafik + Hästkrafter + Miltal + XC90 + Bränsle_El, data = train_data)
summary(lm_1)

# kolla residualer
par(mfrow = c(1, 2))
plot(lm_1$residuals, pch = 16, col = "red")
hist(lm_1$residuals, main = "Histogram - residuals", breaks = 30)
# Residual plot visar ojämn fördelning av residualerna
# Histogram visar en tendens av right-scewed fördelning

par(mfrow = c(2, 2))
plot(lm_1)
vif(lm_1)

# Kolla outliers med studentized
par(mfrow = c(1, 1))
plot(train_data$Pris, studres(lm_1), ylab="Studentized Residuals", xlab="y")

# Residual plot visar på att modellen inte är linjär, tendens till kurvatur.
# Residual plot visar på heteroskedasticitet? Variansen hos residualerna är inte konstant.
# QQplot visar på avvikelse från normalfördelning
# Visar på möjliga outliers


# Modell 2 ----------------------------------------------------------------


# Förbättra modellen med transformering av X-variabler
lm_2 <- lm(Pris ~ Dagar_i_trafik + I(Dagar_i_trafik^1.2) + Miltal +I(Miltal^1.1) + Hästkrafter + XC90 + Bränsle_El, data = train_data)
summary(lm_2)

# kolla residualer
par(mfrow = c(1, 2))
plot(lm_2$residuals, pch = 16, col = "red")
hist(lm_2$residuals, main = "Histogram - residuals", breaks = 30)

par(mfrow = c(2, 2))
plot(lm_2)
vif(lm_2, type="predictor")

# Kolla outliers med studentized
par(mfrow = c(1, 1))
plot(train_data$Pris, studres(lm_2), ylab="Studentized Residuals", xlab="y")



# Modell 3 ----------------------------------------------------------------


# best subset selection
regfit_sqrt <- regsubsets(sqrt(Pris)~., data = train_data, nvmax = 20)
sum_sqrt <- summary(regfit_sqrt)
sum_sqrt
# Dagar i trafik, Hästkrafter, Miltal, XC90, Biltyp_SUV, Växellåda_Manuell

# Testa transformera Y-variabeln och X-variabler.
lm_3 <- lm(sqrt(Pris) ~ Dagar_i_trafik + I(Dagar_i_trafik^1.2) + Miltal + I(Miltal^3) + I(Hästkrafter^2) + XC90, data = train_data)
summary(lm_3)

# kolla residualer
par(mfrow = c(1, 2))
plot(lm_3$residuals, pch = 16, col = "red")
hist(lm_3$residuals, main = "Histogram - residuals", breaks = 30)

par(mfrow = c(2, 2))
plot(lm_3)
vif(lm_3, type="predictor")

# Kolla outliers med studentized
par(mfrow = c(1, 1))
plot(train_data$Pris, studres(lm_3), ylab="Studentized Residuals", xlab="y")

print(train_data[179,])

# Modell 4 ----------------------------------------------------------------


# best subset selection - transformation + interactions
regfit_inter <- regsubsets(sqrt(Pris)~Miltal*Dagar_i_trafik*Hästkrafter*Biltyp_SUV*XC90, data = train_data, nvmax = 20, really.big=TRUE)
sum_inter <- summary(regfit_inter)
sum_inter
# Dagar i trafik, Hästkrafter, Miltal, XC90, Miltal:Dagar_i_trafik

# Testa med interactions.
lm_4 <- lm(sqrt(Pris) ~ Hästkrafter + Miltal*Dagar_i_trafik + XC90 + Säljare_Privat, data = train_data)
summary(lm_4)

# kolla residualer
par(mfrow = c(1, 2))
plot(lm_4$residuals, pch = 16, col = "red")
hist(lm_4$residuals, main = "Histogram - residuals", breaks = 30)

par(mfrow = c(2, 2))
plot(lm_4)
vif(lm_4, type="predict")

# Kolla outliers med studentized
par(mfrow = c(1, 1))
plot(train_data$Pris, studres(lm_4), ylab="Studentized Residuals", xlab="y")


# Testa med poly
lm_5 <- lm(sqrt(Pris) ~ I(Dagar_i_trafik^1.1) + poly(Miltal, 3, raw=TRUE) + I(Hästkrafter^1.2) + XC90 + Säljare_Privat, data = train_data)
summary(lm_5)

# kolla residualer
par(mfrow = c(1, 2))
plot(lm_5$residuals, pch = 16, col = "red")
hist(lm_5$residuals, main = "Histogram - residuals", breaks = 30)

par(mfrow = c(2, 2))
plot(lm_5)
vif(lm_5)

# Kolla outliers med studentized
par(mfrow = c(1, 1))
plot(train_data$Pris, studres(lm_5), ylab="Studentized Residuals", xlab="y")




# Utvärdera modellerna 3, 4 och 5 med cross-validation ---------------------------------

formula_3 <- sqrt(Pris) ~ Dagar_i_trafik + I(Dagar_i_trafik^1.2) + Miltal + 
  I(Miltal^3) + I(Hästkrafter^2) + XC90
formula_4 <- sqrt(Pris) ~ Hästkrafter + Miltal*Dagar_i_trafik + XC90 + Säljare_Privat
formula_5 <- sqrt(Pris) ~ I(Dagar_i_trafik^1.1) + poly(Miltal, 3, raw = TRUE) + 
  I(Hästkrafter^1.2) + Biltyp_SUV * XC90 + Säljare_Privat

set.seed(123) 

# Repeated K-fold cross-validation
# Ställ upp cross validation med k=5 och 3 repetitioner
train_control <- trainControl(method = "repeatedcv", number = 10, repeats = 3)

# Träna modellerna
model_3 <- train(formula_3, data = train_data, method = "lm", trControl = train_control)
model_4 <- train(formula_4, data = train_data, method = "lm", trControl = train_control)
model_5 <- train(formula_5, data = train_data, method = "lm", trControl = train_control)

# Resultat
print(model_3$results)
print(model_4$results)
print(model_5$results)

# Model 4 visar bäst resultat



# Prediktion av testdata --------------------------------------------------

predictions <- predict(lm_4, test_data)^2
RMSE(test_data$Pris, predictions)


# Inferens ---------------------------------------------------

# Hypothesprövning
summary(lm_4)  


# Konfidensintervall och prediktionsintervall 
conf_intervals <- predict(lm_4, newdata = test_data, interval = "confidence", level = 0.95)^2
pred_intervals <- predict(lm_4, newdata = test_data, interval = "prediction", level = 0.95)^2

# plot prediktionsintervallen jmf sanna värden
ggplot(data=pred_intervals, aes(x=1:nrow(pred_intervals))) +
  geom_errorbar(aes(ymax = pred_intervals[,3], ymin = pred_intervals[,2])) +
  geom_point(aes(y=pred_intervals[,1]), shape=1) +
  geom_point(aes(y=test_data$Pris), size=2, color="red") +
  ylab("Price") +
  xlab("Prediction intervals and actual price (red)") +
  theme(axis.text.x=element_blank(), axis.ticks.x=element_blank())


lm_4$coefficients
confint(lm_4)
