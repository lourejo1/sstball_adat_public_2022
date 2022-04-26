#!/usr/bin/env Rscript
###### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ######
###### Novartis Somalogic SomaScan tarball unpacking and eSet build
###### joseph.loureiro@novartis.com
############# output feeds into somaTechQCv3.x.Rmd
############# optional arg to pass for ABC123 projectCode to embed in output
############# Rscript somaTechQCv3.x.Rmd ABC123

###### setup

  options(stringsAsFactors = FALSE)
  
  library(dplyr)
  library(Biobase)
  library(SomaDataIO)
  library(rjson)
  library(tools)

# helper function to find adat files 
  adat_filter <- function(x){x<- x[which(grepl(".adat$" , x))];return(x)}
  
# read baseAnnotation into memory - will be useful to develop pin or other more robust method
  baseAnnot.v4 <- readRDS("SomaScan_v4.1_annotationsPUBLIC2022_vlite.RDS")
  
# make a folder for processing output
  system( "mkdir ../tech/", intern = TRUE)

# find the adats
  adat.ref <- data.frame(adat = adat_filter(dir(path = "../data/")) , 
                    	 adat.char = nchar(adat_filter(dir(path = "../data/"))))
# if provided, pull project code from arg1, otherwise parse novartis format
  args <- commandArgs(trailingOnly=TRUE)
  # test if there is at least one argument: if not, return an error
  if (length(args)==0) {
    projectCode <- substr(adat.ref[1,1], 10, 15)
  } else if (length(args)==1) {
    # default output file
    projectCode <- args[1]
  }
  # 
  # insert arg1 - suggest ABC123 format

# md5check and warn if any don't match 
if(file.exists(file = "../data/adat.md5")){  
  md.id <- read.table(file = "../data/adat.md5" , sep = "\t")
    md.id$adat.char <- nchar(md.id$V2)
    md.id <- md.id[order(as.integer(md.id$adat.char)),]
    
  md.check <- unlist(md5sum(paste0("../data/" , adat.ref$adat)))
    if(any(c(md.id[,1] %in% md5sum(paste0("../data/" , adat.ref$adat))) == FALSE)){
      warning("At least one adat failed verification")}else{print("md5check PASS")}
}else{print("No adat.md5 file found.  CHECK SKIPPED.  Look both ways.")}

# read in RAW and MOST_PROCESSED adats and generate eSet object with conditional on number of adats available
  tb_list <- c(adat.ref[which(adat.ref$adat.char == min(adat.ref$adat.char)),1] ,
             adat.ref[which(adat.ref$adat.char == max(adat.ref$adat.char)),1])

  # Condition on whether there is only one adat or whether there are multiple.  
  # Only logical if all adats are of the same study and represent norm steps. 
  # Smallest filename character length is data at or clesest to raw available.
  sscanSet <- NULL ; sscanSetNorm <- NULL
if(tb_list[1] != tb_list[2]){   
  sscanSet <- adat2eSet(read.adat(paste0("../data/" , tb_list[1])))
  sscanSetNorm <- adat2eSet(read.adat(paste0("../data/" , tb_list[2])))

      # 1.4.4 add to apply seq.####.## format
        rownames(sscanSet) <- make.names(paste0("seq.",as.vector(unlist(fData(sscanSet)[,"SeqId"]))))
        rownames(sscanSetNorm) <- make.names(paste0("seq.",as.vector(unlist(fData(sscanSetNorm)[,"SeqId"]))))
      
      #io_id should match colnames on eSet object and will return warning if the don't
        pData(sscanSet)$io_id <- paste0(pData(sscanSet)$SlideId,"_",pData(sscanSet)$Subarray)
          if(any(c(colnames(sscanSet) == pData(sscanSet)$io_id) == FALSE)) warning("Mismatch io_id render - verify sample metadata")
        pData(sscanSetNorm)$io_id <- paste0(pData(sscanSetNorm)$SlideId,"_",pData(sscanSetNorm)$Subarray)
          if(any(c(colnames(sscanSetNorm) == pData(sscanSetNorm)$io_id) == FALSE)) warning("Mismatch io_id render - verify sample metadata")
      
      
      # add human readable labels
        pData(sscanSet)$label <- make.names(paste(pData(sscanSet)$SampleType , 
                                                substring(pData(sscanSet)$ScannerID,nchar(pData(sscanSet)$ScannerID)-2) ,
                                                substring(pData(sscanSet)$PlateId,nchar(pData(sscanSet)$PlateId)-2) ,
                                                pData(sscanSet)$Barcode ,
                                                sep = ".")) # 
      
        pData(sscanSetNorm)$label <- make.names(paste(pData(sscanSetNorm)$SampleType , 
                                                substring(pData(sscanSetNorm)$ScannerID,nchar(pData(sscanSetNorm)$ScannerID)-2) ,
                                                substring(pData(sscanSetNorm)$PlateId,nchar(pData(sscanSetNorm)$PlateId)-2) ,
                                                pData(sscanSetNorm)$Barcode ,
                                                sep = ".")) # 
      
      # join v4.1 baseAnnotation
        fData(sscanSet) <- left_join(as.data.frame(fData(sscanSet)) , baseAnnot.v4 , by = c("SeqId" = "CORE_ID"))
        fData(sscanSetNorm) <- left_join(as.data.frame(fData(sscanSetNorm)) , baseAnnot.v4 , by = c("SeqId" = "CORE_ID"))
        pData(sscanSet)$SOURCE <- projectCode
        pData(sscanSetNorm)$SOURCE <- projectCode
        
        # render .RDS
        saveRDS(list(sscanSetRaw = sscanSet ,
                     sscanSetNorm = sscanSetNorm) ,
                file = paste0("../somaSet_QCout_" , projectCode , ".RDS"))
        print("Two adats processed")
}else{
  sscanSetNorm <- adat2eSet(read.adat(paste0("../data/" , tb_list[1])))
  
        # 1.4.4 add to apply seq.####.## format
        rownames(sscanSetNorm) <- make.names(paste0("seq.",as.vector(unlist(fData(sscanSetNorm)[,"SeqId"]))))
        
        #io_id should match colnames on eSet object and will return warning if the don't
        pData(sscanSetNorm)$io_id <- paste0(pData(sscanSetNorm)$SlideId,"_",pData(sscanSetNorm)$Subarray)
        if(any(c(colnames(sscanSetNorm) == pData(sscanSetNorm)$io_id) == FALSE)) warning("Mismatch io_id render - verify sample metadata")
        
        
        # add human readable labels
      
        pData(sscanSetNorm)$label <- make.names(paste(pData(sscanSetNorm)$SampleType , 
                                                      substring(pData(sscanSetNorm)$ScannerID,nchar(pData(sscanSetNorm)$ScannerID)-2) ,
                                                      substring(pData(sscanSetNorm)$PlateId,nchar(pData(sscanSetNorm)$PlateId)-2) ,
                                                      pData(sscanSetNorm)$Barcode ,
                                                      sep = ".")) # 
        
        # join v4.1 baseAnnotation
        fData(sscanSetNorm) <- left_join(as.data.frame(fData(sscanSetNorm)) , baseAnnot.v4 , by = c("SeqId" = "CORE_ID"))
        pData(sscanSetNorm)$SOURCE <- projectCode
      
#       render .RDS
        saveRDS(list(sscanSetNorm = sscanSetNorm) ,
              file = paste0("../somaSet_QCout_" , projectCode , ".RDS"))
        print("One adat processed")
}

###### output expressionSet .RDS, json formated content of header, and text files 
  print("Tech files written to tech folder")
  sink(file = paste0("../tech/qcsummary" , projectCode , ".json") , type = "output")
    print(sscanSetNorm@experimentData@other$ReportConfig)
  sink()

  sink(file = paste0("../tech/" , projectCode , "_dataset_integrity.and.shape.txt") , type = "output")
  if(file.exists(file = "../data/adat.md5")){   
  print("md5 check details")
    for(i in 1:length(adat.ref$adat)){
      print(i)
      print(paste0("Local file md5sum : ",names(md.check[i])," : ",md.check[i]))
      print(paste0("From Somalogic : ",md.id[i,]))
      print(paste0("MD5 check : ", (md.check[i] == md.id[i,1])))
      print("")
    }
  }
    print("")
    print("Somascans by sampleType")   
    print(table(pData(sscanSetNorm)$SampleType))
    print("")
    print("Somascans by ScannerID_PlateId")  
    print(table(paste0(pData(sscanSetNorm)$ScannerID ,"_",pData(sscanSetNorm)$PlateId))) 
    print("")
    print("Somascan PlateId distribution across Scanner summary table") 
    print("")
    print(table(pData(sscanSetNorm)$PlateId , pData(sscanSetNorm)$ScannerID))
    print("")
    print(table(pData(sscanSetNorm)$PlateId , pData(sscanSetNorm)$SampleType))
    print("")
  if(!is.null(sscanSet)){ 
    print(paste0("RAW data : " , tb_list[1]))  
    print(summary(sscanSet))  
    print(head(sscanSet , max.level = 3))
    print("")
  }
    print(paste0("NORMALIZED data : " , tb_list[2]))  
    print(summary(sscanSetNorm)) 
    print(head(sscanSetNorm , max.level = 3))
  sink()

  sink(file = paste0("../tech/tarballUnpack.and.processing.technical.txt")  , type = "output")
    print("Settings and environment")
    print("")
    print("getwd")  
    print(getwd())
    print("")
    print("sessionInfo")  
    print(sessionInfo())
    print("")
    print("Warnings")  
    print(warnings())
    print("")
    print("Sys.getenv")  
    print(Sys.getenv())
  sink()

  ###### ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ######
