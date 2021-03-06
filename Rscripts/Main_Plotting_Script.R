### Manage directories
#setwd("~/Thomas/12_timepoints")
##setwd("D:/Tang/Rohit")
inputDir = "InputData"
plotDir  = "OutputPlots"        
fileDir  = "OutputFiles"

source("Rscripts/utils.R")

### Read in data ###


geneNames<-read.csv(paste0(inputDir, "/InTransANDinProt_GeneNamesOnly.csv"), stringsAsFactors=F)

#typeof(geneNames)



# Main data
prot = read.csv(paste0(inputDir, "/Proteomic.csv"), stringsAsFactors=F)
tran = read.csv(paste0(inputDir, "/Transcriptomic.csv"), stringsAsFactors=F)

# Additional Info
gene     = read.csv(paste0(inputDir, "/AllChr.csv"),  stringsAsFactors = F)
path     = read.csv(paste0(inputDir, "/BiochemicalPathways.tab"),
                    stringsAsFactors = F, sep = "\t")
life     = read.csv(paste0(inputDir, "/lifespan.tsv"),
                    stringsAsFactors = F, sep = "\t")
goYeast  = read.csv(paste0(inputDir, "/gene_association.sgd"), sep = "\t",
                    stringsAsFactors = F)
goLookUp = scan(paste0(inputDir, "/go.obo"), what = "", sep = "\t")



### Pre-processing ###
colnames(tran)[-1] = gsub("H", "t", colnames(tran)[-1])
colnames(prot)[-1] = gsub("H", "p", colnames(prot)[-1])

prot = prot[!grepl(";", prot$ORF),]

# Get proportion of references claiming pro, anti, fitness 
# for each gene in the lifespan data
lGenes           = unique(life$Gene.Symbol)
lProbs           = data.frame(matrix(nrow=length(lGenes), ncol=4))
colnames(lProbs) = c("CommonName", "pro", "anti", "fitness")

for(i in 1:length(lGenes)){
  sub            = life[life$Gene.Symbol == lGenes[i], ]
  Pr             = sapply(c("pro", "anti", "fitness"), function(x) 
    sum(sub$Longevity.Influence == x)/nrow(sub))
  lProbs[i, 1]   = lGenes[i]
  lProbs[i, 2:4] = Pr
}
lProbs[,2:4]     = sapply(lProbs[, 2:4], as.numeric)


# Arrange the pathway data so there is one row per gene
pathGenes = unique(clean(path$Gene))
uniqPaths = as.data.frame(matrix(nrow = length(pathGenes), ncol = 3))
for(i in 1:length(pathGenes)){
  sel             = path$Pathway[clean(path$Gene) == clean(pathGenes[i])]
  uniqPaths[i, 1] = pathGenes[i]
  uniqPaths[i, 2] = length(sel)
  uniqPaths[i, 3] = paste(sel, collapse = "; ")
}
colnames(uniqPaths) = c("Gene", "Npathways", "Pathways")


# Get GO IDs for each gene
geneGO = aggregate(GoTerm~Gene, goYeast, function(x) 
  gsub("GO:", "", paste(x, collapse = "; ")))
#There is a gene called 1-Oct in geneGo. Is that right?


# Convert the GO obo file to R list
#goLookUp = oboToList(goLookUp)


# Combine the various data sources into one data frame
dat = combine(tran, prot,      "ORF",     "ORF")
dat = combine(dat,  gene,      "ORF",     "Feature.Systematic.Name")
dat = combine(dat,  uniqPaths, "Feature", "Gene")
dat = combine(dat,  lProbs,    "Feature", "CommonName")
dat = combine(dat,  geneGO,    "Feature", "Gene")


# Remove undesirable rows/columns
# Determine the columns containing expression data
expColmns  = getExpColmns(dat)
tExpColmns = expColmns$tExpColmns
pExpColmns = expColmns$pExpColmns
Hrs        = expColmns$Hrs


# Remove rows without any expression data
remRows = apply(dat[, c(tExpColmns, pExpColmns)], 1, function(x) all(is.na(x)))
dat     = dat[!remRows, ]
rownames(dat)=1:nrow(dat)

# Reorder columns so that expression data is last
dat = dat[, c(1:(tExpColmns[1] - 1), 
              (pExpColmns[length(Hrs)] + 1):ncol(dat), 
              tExpColmns, pExpColmns) ]

# 5231 rows and 36 columns in dat

# Remove columns not being used (for now)
remCols = sapply(dat, function(x) 
  length(unique(x)))  == 1 | colnames(dat) %in% c("Npathways")
dat     = dat[, !remCols]

# 5231 rows and 36 columns in dat -- Only Npathways column was removed! Why is this done? what was the idea here?


# Columns have been reordered so get expression columns again
expColmns  = getExpColmns(dat)
tExpColmns = expColmns$tExpColmns
pExpColmns = expColmns$pExpColmns

# dat needs to be cleaned up to include only relevant information and fewer NA's

## Make the plots



# Plot panels of selected genes
plotChoices(geneNames,  nr = 3, nc = 3, 
            makePDF = T, PDFdim = c(12, 9), 
            PDFname = "Stephen2coupling.pdf",   
            lwd = 2,                cex = 2, 
            cex.x.axis = 0.8,         cex.y.axis = 2, 
            pch1  = 24,               pch2 = 23,  
            ylab1 = "mRNA Levels",    col1 = "blue", 
            ylab2 = "Protein Levels", col2 = "green", 
            plotOnly = "both", 
            main = "", addToPrev = F, norm = T)


# What is attempted here? No plot is generated

# Plot selected genes on one chart
plotChoicesMulti(geneNames,  nr = 1, nc = 1, 
                 makePDF = T, PDFdim = c(12, 9), 
                 PDFname = "Stephen1m.pdf",   
                 lwd = 2,                  cex = 2, 
                 cex.x.axis = 0.8,         cex.y.axis = 2, 
                 pch1  = 24,               pch2 = 23,  
                 ylab1 = "mRNA Levels",    col1 = rainbow(length(geneNames)), 
                 ylab2 = "Protein Levels", col2 = "green", 
                 plotOnly = "tran", 
                 main = "Choices", addToPrev = F, norm = T)



difSum = data.frame(Feature = dat$Feature, stringsAsFactors = F)
tpDif = t(apply(dat[,tExpColmns], 1, normalize)) - t(apply(dat[,pExpColmns], 1, normalize))
difSum$Sum = rowSums(abs(tpDif))
tpDif2 = tpDif[order(difSum$Sum),]
difSum = difSum[order(difSum$Sum),]
difSum = difSum[!is.na(difSum$Sum),]
tpDif2 = tpDif2[!is.na(tpDif2[,1]),]

dev = apply(tpDif2,1,function(x) coef(lm(abs(x)~Hrs))[2])
ord.dev = order(dev)
difSum = cbind(difSum[ord.dev,],dev)
tpDif2 = tpDif2[ord.dev,]



pdf(paste0(plotDir, "/Trans-Prot_abs4_Hist.pdf"), width = 12, height = 9)
hist(dev, breaks = 20, col="brown", labels = TRUE,xlab = "Slope: Change Per Hour", main = c("Linear Trend in Divergence", "Between mRNA and Protein Expression Levels"))
par(mfrow=c(3,3))
for(i in 1:nrow(tpDif2)){
  plotLevels(Hrs, abs(tpDif2[i,]), main = c(difSum$Feature[i],"Trans-Prot Magnitude"), col="red")
  #abline(h=0,lty=1,col="purple",lwd=3)
  abline(lm(abs(tpDif2[i,])~Hrs), lty=1, col= "orange", lwd=3)
}
dev.off()

# increasing slope means decoupling

dat_inner = cbind(difSum,tpDif2)

write.csv(dat, "dat file.csv", row.names = F)
write.csv(dat_inner, "dat inner file.csv", row.names = F)












