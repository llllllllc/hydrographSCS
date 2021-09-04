SwmmTimeSeries<-function(hydMatrix){
  #START OF 為分割集水區SWMM Time Series格式檔案輸出
  t<-as.matrix(read.table("tempcsv/times.csv",sep=",",encoding="UTF-8"))
  sink("output/subHyd.inp")#建立一個inp檔案
  for (i in c(2:ncol(hydMatrix))) {#分別依三個重現期距計算2/5/10yr
    
    for (y in (1:144)) {#逐步寫入名稱歷線(依照SWMM格式模擬)
      cat(paste(hydMatrix[1,i]
                ,"               "
                ,t[y,1]," ",t[y,2]
                ,"      ",hydMatrix[y+1,i]
                ,sep=""))
      cat("\n")
    }
    
    cat(";")
    cat("\n")
  }
  sink()#關閉檔案
  #END OF 為分割集水區SWMM Time Series格式檔案輸出
  print("逕流歷線SWMM Time Series格式檔案輸出")
}