SwmmInflow<-function(inflowArea,inflowNode,T){
  sink("output/inflow.inp")
  for (i in c(1:3)) {
    for (j in (1:length(inflowArea))) {
      cat(inflowNode[j])#Node
      cat("          FLOW             ")
      cat(paste(inflowArea[j],"_",T[i],"y",sep = ""))#Time Series
      cat("     FLOW     1.0      1.0              ")
      cat("\n")
    }
  }
  sink()
  print("SWMM INFLOW資料格式檔案輸出")
}