library(gridExtra)
library(ggthemes)

ScriptDir = "Rscripts"

source(paste0(ScriptDir,"/Main Slope Correlation.R"))


# Creating the Age Filter
Age_filter <- unique(Dat_pt$Age)[order(unique(Dat_pt$Age))%in%seq(3,10,1)]

# Creating the Gene Filter ranked by Average Life
Gene_filtered <- Dat_pt%>%
  mutate(Age = paste0("H",Age))%>%
  select(-c(ProtExp,TranExp))%>%
  spread(key = Age,value = ProtTranRatio)%>%   # spread to order the set in avglife
  arrange(desc(AvgLife))%>%
  select(Feature)

write.csv(Gene_filtered, paste0(outDir,"/Filtered Gene List.csv"), row.names = F)

GeneRank <- Gene_filtered%>%
  mutate(gRowNum = as.integer(row.names(Gene_filtered)))

# Creating the dataset needed to plot
Dat_plot <- Dat_pt%>%
  filter(Feature %in% Gene_filtered$Feature)%>%
  inner_join(y = GeneRank, by = c("Feature" = "Feature"))%>%
  select(c(gRowNum,Feature, ORF,AvgLife, Age,ProtExp,TranExp,ProtTranRatio))

# Normalizing Function
normalize <-function(x){ (x-min(x))/(max(x)-min(x)) }
# Generate a list of plots for each gene
p<-list()

for( i in GeneRank$gRowNum)
{
  Dat_s <- Dat_plot[Dat_plot$gRowNum == i , ]
  
  p[[i]]<- ggplot(Dat_s) + 
    geom_line(aes(x= Age, y=ProtTranRatio), col="green",size =2) +
    geom_point(aes(x= Age, y=ProtTranRatio),color = "red",fill = "blue", shape = 24, size =4) +
    geom_hline(aes(yintercept=1), colour="red", linetype=1, size =2) +
    geom_vline(aes(xintercept=Age_filter[1]), colour="blue", linetype="dashed", size =1) +
    geom_vline(aes(xintercept=Age_filter[8]), colour="blue", linetype="dashed", size =1)+
    ggtitle(paste(Dat_s$Feature[1],":",Dat_s$ORF[1],":",round(Dat_s$AvgLife[1],2))) + 
    ylab("Proteomic Transcriptomic Ratio") + 
    theme(axis.title.x = element_text( color="black",size=10)) + 
    theme(axis.title.y = element_text( color="black",size=10))+
    theme(axis.text.y = element_text(face="bold", color="black",size=12))
}

pn <- list()
for( i in GeneRank$gRowNum)
{
  Dat_s <- Dat_plot[Dat_plot$gRowNum == i , ]%>% 
    mutate(normPTRatio = normalize(ProtExp)-normalize(TranExp))
  
  pn[[i]]<- ggplot(Dat_s) + 
    geom_line(aes(x= Age, y=normPTRatio), col="green",size =2) +
    geom_point(aes(x= Age, y=normPTRatio),color = "red",fill = "blue", shape = 24, size =4) +
    geom_hline(aes(yintercept=0), colour="red", linetype=1, size =2) +
    geom_vline(aes(xintercept=Age_filter[1]), colour="blue", linetype="dashed", size =1) +
    geom_vline(aes(xintercept=Age_filter[8]), colour="blue", linetype="dashed", size =1)+
    ggtitle(paste(Dat_s$Feature[1],":",Dat_s$ORF[1],":",round(Dat_s$AvgLife[1],2))) + 
    ylab("Proteomic Transcriptomic Diff") + 
    theme_gdocs() + 
    theme(axis.title.x = element_text( color="black",size=10)) + 
    theme(axis.title.y = element_text( color="black",size=10))+
    theme(axis.text.y = element_text(face="bold", color="black",size=12))
}

# Print the plots to a PDF file arranging them in 2x2 plots per page

pdf(paste0(plotDir, "/", "GenePlots_Rohit.pdf")) 

for( i in seq(0,length(p)-4,4))
{ grid.arrange(p[[i+1]],p[[i+2]],p[[i+3]],p[[i+4]], nrow =2, ncol=2, newpage = TRUE ) }

dev.off()

pdf(paste0(plotDir, "/", "GenePlotsNorm_Rohit.pdf")) 

for( i in seq(0,length(pn)-4,4))
{ grid.arrange(pn[[i+1]],pn[[i+2]],pn[[i+3]],pn[[i+4]], nrow =2, ncol=2, newpage = TRUE ) }

dev.off()

