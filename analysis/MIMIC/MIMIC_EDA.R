install.packages(("DataExplorer"))
library(DataExplorer)


read_csv("./MIMIC_all_CCU_patients.csv")
ccu <- ccu%>%select(-X1)

# EDA

plot_missing(ccu[, 1:20],geom_label_args = list("size" = 0.5, "label.padding" = unit(0.1, "lines")))
plot_histogram(ccu[, 50:100])
plot_density(choco)
plot_bar(ccu, theme_config = aes(fill=factor(ccu$icu_mortality)))
plot_correlation(ccu[,1:10], type = 'continuous')
plot_scatterplot(ccu, by = "icu_mortality", sampled_rows = 1000L)

create_report(data=ccu, y="icu_mortality")

