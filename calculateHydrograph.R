setwd("./")
source("SCShydrograph.R")
source("SwmmTimeSeries.R")
source("SwmmInflow.R")

print("將excel輸入轉換為csv")

#STAR OF檔案清除
tryCatch({
  unlink("output", recursive = TRUE)
}
)
dir.create("output")
print("重新生成output資料夾")
#END OF檔案清除



#STAR OF參數輸入
#匯入檔案
subcatchment<-as.matrix(read.csv("tempcsv/subcatchment.csv"))#子集水區參數
sornot<-as.numeric(subcatchment[3,1])
if (sornot==1){#如果有要分割的話
  separate<-as.matrix(read.csv("tempcsv/separate.csv"))#將子集水區的出流歷線以面積等比例分割
  numberOfsep<-as.numeric(separate[1,5])#切割後集水區數量
  separate<-separate[1:numberOfsep,]#只保留要的data以免有空白被轉入
  separate<-separate[,-5]
  separate[,3]<-as.numeric(separate[,3])/100#輸入是ha要先轉換成km^2

  print("使否將子集水區的出流歷線以面積等比例分割(或放大):是")
}else{#如果沒有要分割的話
  print("使否將子集水區的出流歷線以面積等比例分割(或放大):否")
  }
rainfall<-as.matrix(read.csv("tempcsv/rainfall.csv",header = F))#雨量參數
#雨型參數輸入
horner <- apply(rainfall[2:4,2:4],2, as.numeric)#horner雨型參數,依2yr,5yr,10yr排列
R24<-as.numeric(rainfall[5,2:4])#24hr最大降雨量,依2yr,5yr,10yr排列
T=c(2,5,10)#分別採2yr/5yr/10yr重現期,依2yr,5yr,10yr排列
#子集水區參數輸入
numberOfsub<-as.numeric(subcatchment[1,1])#集水區數量
Area<-as.numeric(subcatchment[1:numberOfsub,4])/100#(km^2)集水區面積,依子集水區排列
                                                  #輸入是ha要先轉換成km^2
Tc<-as.numeric(subcatchment[1:numberOfsub,6])#(hr)開發後集流時間,依子集水區排列
CN<-as.numeric(subcatchment[1:numberOfsub,5])#CN值，,依子集水區排列
subID=subcatchment[1:numberOfsub,2]#集水區ID，,依子集水區排列
#計算及儲存用矩陣
hydrographMatrix<-matrix(NA,145,numberOfsub*3+1)#分割前子集水區計算成果存放區
#END OF參數輸入


#START OF SCS逕流歷線計算
print("逕流歷線計算")
hydrographMatrix[1,1]<-"t"#第一欄為時間(間隔1/6小時)
for (i in c(1:3)) {#分別依三個重現期距計算2/5/10yr
  
  for (j in c(1:numberOfsub)) {#分別依不同子集水區計算
    filenameOutput<-paste(subID[j],"_",T[i],"y",sep = "")#集水區ID作為檔案名稱
    temp<-hydrograph(as.numeric(horner[,i]),R24[i],Area[j],Tc[j],CN[j],filenameOutput)#計算子集水區出流歷線
    hydrographMatrix[1,(i-1)*numberOfsub+j+1] <-paste(subID[j],"_",T[i],"y",sep = "")#集水區ID作為表頭
    hydrographMatrix[2:145,(i-1)*numberOfsub+j+1]<-temp[,2]#逐一放入出流歷線
    hydrographMatrix[2:145,1]<-temp[,1]#第一欄為時間
    cat(hydrographMatrix[1,(i-1)*numberOfsub+j+1])
    cat(" horner:");cat(horner[,i])
    cat(paste("  R24(mm):",R24[i],"  Area(ha):",Area[j]*100,"  Tc(hr):",Tc[j],"  CN:",CN[j]),sep="")
    cat("\n")
    
  }
}
#END OF SCS無因次逕流歷線計算



#START OF 線性分割(或放大)歷線(以比流量觀念)
print("線性分割(或放大)歷線(以比流量觀念),若無則跳過")
if (sornot==1){#如果有要線性分割的話
  sepInflowMatrix<-matrix(NA,numberOfsep*3,6)
  sepArea<-as.numeric( separate[,3])#要分割的面積
  inputIDArray<- separate[,1]
  outputIDArray<- separate[,2]
  outputNodeArray<-separate[,4]
  sepInflowMatrix[,1]=outputNodeArray
  sepInflowMatrix[,2]="FLOW"
  sepInflowMatrix[,4]="FLOW"
  sepInflowMatrix[,5]=1
  for (i in c(1:3)) {
    for (x in c(1:numberOfsep)) {
      inputID<-paste(separate[x,1],"_",T[i],"y",sep = "")#要被切的出流歷線名字
      sepRate=sepArea[x]/Area[which(subID == inputIDArray[x], arr.ind = TRUE)]
      sepInflowMatrix[(i-1)*numberOfsep+x,6]<-sepRate
      sepInflowMatrix[(i-1)*numberOfsep+x,3]<-inputID
      cat(paste("node=",sepInflowMatrix[(i-1)*numberOfsep+x,1]," INFLOW=",inputID,"rate=",sepRate))
      cat("\n")
    }
  }
}
#END OF 線性分割(或放大)歷線(以比流量觀念)



#START OF 逕流歷線SWMM Time Series格式檔案輸出
SwmmTimeSeries(hydrographMatrix)
#END OF 逕流歷線SWMM Time Series格式檔案輸出




#START OF SWMM INFLOW資料格式檔案輸出
if (sornot==1){#如果有要線性分割的話
  
  write.table(sepInflowMatrix,"./output/inflow.txt",sep = "       ",row.names=F,col.names=F, quote = FALSE)
  
}else{#如果沒有要線性分割的話
  SwmmInflow(subID,subcatchment[,7],T)
}
#END OF SWMM INFLOW資料格式檔案輸出




#START OF 檔案輸出
write.table(hydrographMatrix,"./output/降雨逕流.csv",sep = ",",row.names=F,col.names=F)
print("輸出降雨逕流")
#END OF 檔案輸出


#START OF 檔案整理
#輸入參數
summaryData<-subcatchment[c(1:numberOfsub),c(2:5)]
addMa<-matrix(NA,nrow=numberOfsub,ncol = 3)
colnames(addMa)=c("2年","5年","10年")
summaryData<-cbind(summaryData,addMa)

maxData<-as.matrix(hydrographMatrix[1:2,-1])
maxData[2,]<-0
for (i in c(1:ncol(maxData))) {
  
  maxData[2,i]<-max(as.numeric(hydrographMatrix[c(2:nrow(hydrographMatrix)),i+1]))
  
}

for (i in c(1:numberOfsub)) {
  
  summaryData[i,5]<-maxData[2,i]
  summaryData[i,6]<-maxData[2,i+numberOfsub]
  summaryData[i,7]<-maxData[2,i+2*numberOfsub]
  
}
write.table(summaryData,"./output/降雨逕流summary.csv",sep = ",",row.names=F)
print("輸出降雨逕流summary")
#END OF 檔案整理


cat("\n")
print("calculation complete")
cat("\n")









