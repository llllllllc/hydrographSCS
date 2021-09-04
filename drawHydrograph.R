library(ggpmisc)
library(ggplot2)


#STAR OF檔案清除
setwd("./")
tryCatch({
  unlink("outputPicture", recursive = TRUE)
})
dir.create("outputPicture")
#END OF檔案清除



#####START OF 畫逕流歷線
print("畫到一半啦.......")
subcatchment<-as.matrix(read.csv("tempcsv/subcatchment.csv"))#子集水區參數
subNum<-as.numeric(subcatchment[1,1])#####輸入集水區數量
dir.create("outputPicture/Hyd")#新增資料夾
inputData<-read.csv("output/降雨逕流.csv",header=T)
for (i in c(1:subNum)) {
  data<-inputData[,c(1,i+1,subNum+i+1,subNum*2+i+1)]
  subName<-strsplit(names(data)[2],"_")
  subName<-as.character( subName[[1]])
  subName<-as.character( subName[[1]])
  longData<-reshape(data, 
                    direction = "long",
                    varying = names(data)[2:ncol(data)],
                    v.names = "Q",
                    idvar = "t",
                    timevar = "legend",
                    times = c("2年","5年","10年"))
  
  longData$legend = factor(longData$legend, levels = c("2年","5年","10年"))
  
  pic<-ggplot(longData,aes(t,Q,group=legend,colour=legend))+
    geom_line()+ 
    xlab(paste("時間(hr)",paste(subName,"集水區",sep=""),sep="\n")) + ylab("流量(CMS)")+
    #ggtitle(paste(subName,"集水區",sep=""))+
    stat_peaks(colour = "black",strict = TRUE)+
    stat_peaks(geom = "text", data=longData[longData$legend=='2年',], colour = "black",strict = TRUE,position = "identity", 
               size=22/.pt,aes(label =paste(..y.label..,"CMS" )) ,#paste("t=",..x.label.., "hr,Q=",..y.label..,"CMS")) ,
               vjust = 0.5,hjust = -0.1)+
    stat_peaks(geom = "text", data=longData[longData$legend=='5年',], colour = "black",strict = TRUE,position = "identity", 
               size=22/.pt,aes(label =paste(..y.label..,"CMS" )) ,#paste("t=",..x.label.., "hr,Q=",..y.label..,"CMS")) ,
               vjust = 1,hjust = -0.1)+
    stat_peaks(geom = "text", data=longData[longData$legend=='10年',], colour = "black",strict = TRUE,position = "identity", 
               size=22/.pt,aes(label =paste(..y.label..,"CMS" )) ,#paste("t=",..x.label.., "hr,Q=",..y.label..,"CMS")) ,
               vjust = -0.5,hjust = -0.1)+
    theme( text = element_text(size = 22))
  
  picName<-paste("outputPicture/Hyd/",subName,".png",sep = "")
  ggsave(paste("outputPicture/Hyd/",subName,".png",sep = ""),pic,width = 15, height =10)
  
  
  
  
}
rm(list=ls())
#####END OF 畫逕流歷線



####START OF 畫單位歷線
subcatchment<-as.matrix(read.csv("tempcsv/subcatchment.csv"))#子集水區參數
subNum<-as.numeric(subcatchment[1,1])#####取得集水區數量
dir.create("outputPicture/unitHyd")#新增資料夾
inputData<-read.csv("output/SCSq.csv",header=T)
for (i in c(1:subNum)) {
  data<-inputData[,c(1,i+1)]
  subName<-strsplit(names(data)[2],"_")
  subName<-as.character( subName[[1]])
  subName<-as.character( subName[[1]])
  longData<-reshape(data, 
                    direction = "long",
                    varying = names(data)[2],
                    v.names = "q",
                    idvar = "t",
                    timevar = "legend",
                    times ="q")
  
  pic<-ggplot(longData,aes(t,q,group=legend,colour=legend))+
    geom_line()+ 
    xlab(paste("時間(hr)",paste(subName,"集水區",sep=""),sep="\n")) + ylab("流量(CMS)")+
    geom_point(data = longData[longData$q ==max(longData$q), ], colour="black") + 
    geom_text(data = longData[longData$q ==max(longData$q), ], colour = "black", 
              size=12/.pt ,vjust = 0.5,hjust = -0.2, aes(label = paste0(q,"CMS"))) +
    theme( text = element_text(size = 12))
  
  picName<-paste("outputPicture/unitHyd/",subName,".png",sep = "")
  ggsave(paste("outputPicture/unitHyd/",subName,".png",sep = ""),pic,width = 8, height = 5)
  
  
  
  
}
print("畫完了!!!")
####END OF 畫單位歷線


