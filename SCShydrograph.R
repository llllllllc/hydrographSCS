#START OF SCS無因次逕流歷線計算function
hydrograph<-function(horner,R24,Area,Tc,CN,fName){#子集水區流歷線計算
  "
  horner:horner參數輸入
  R24:24hr暴雨
  Area:集水面積km^2
  Tc:集流時間
  CN:集水區平均CN值
  fName：降雨逕流歷線的名稱或編號
  "

  
  #雨型參數輸入
  hornerA <- horner[1]
  hornerB <- horner[2]
  hornerC <- horner[3]
  if(R24==(-1)){
    R24=hornerA/(24*60+hornerB)^hornerC*24#若無24小時最大降雨量則自行以horner公式計算
  }
  #相關參數計算
  D<-1/6#單位降雨延時10min
  S<-(25400/CN-254)
  Tlag<-0.6*Tc
  Tp<-D/2+Tlag
  qp<-2.08*Area/Tp
  
  #單位歷線計算
  #原始無因次單位歷線表格
  tTp<-c(0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2,2.2,2.4,2.6,2.8,3,3.2,3.4,3.6,3.8,4,4.5,5,100)
  qqp<-c(0,0.03,0.1,0.19,0.31,0.47,0.66,0.82,0.93,0.99,1,0.99,0.93,0.86,0.78,0.68,0.56,0.46,0.39,0.33,0.28,0.207,0.147,0.107,0.077,0.055,0.04,0.029,0.021,0.015,0.011,0.005,0,0)
  oneCmUnitHyd<-data.frame(t=tTp*Tp,q=qqp*qp)
  interpolate_oneCmUnitHyd <- data.frame(t=c(0:40)*D,q=NA)
  q<-approx(oneCmUnitHyd[,'t'], oneCmUnitHyd[,'q'],xout =interpolate_oneCmUnitHyd[,'t'])
  interpolate_oneCmUnitHyd [,'q']<-q$y
  interpolate_oneCmUnitHyd<-as.matrix(interpolate_oneCmUnitHyd)#單位歷線
  
  #設計雨型計算
  ReMatrix<-matrix(NA,144,12)#僅計算前24小時間隔為10分鐘(24*6=144)
  colnames(ReMatrix)<-c("時間","降雨強度","累積降雨","單位降雨","%","排列%","降雨量(mm)","P","Ia","Fa","Pe","超滲降雨RE (cm)")
  for (i in c(1:144)) {
    ReMatrix[i,1]<-i*D
    ReMatrix[i,2]<-hornerA/(hornerB+60*ReMatrix[i,1])^hornerC
    ReMatrix[i,3]<-ReMatrix[i,1]*ReMatrix[i,2]
    if ( i==1 ){
      ReMatrix[1,4]<-ReMatrix[1,3]
    }
    else{
      ReMatrix[i,4]<-ReMatrix[i,3]-ReMatrix[i-1,3]
    }
    ReMatrix[i,5]<-ReMatrix[i,4]/(144*D*hornerA/(hornerB+60*144*D)^hornerC)
    ReMatrix[nrow(ReMatrix)/2+(-1)^i*i%/%2,6]<-ReMatrix[i,5]
    ReMatrix[nrow(ReMatrix)/2+(-1)^i*i%/%2,7]<-R24*ReMatrix[nrow(ReMatrix)/2+(-1)^i*i%/%2,6]
  }
  #超滲降雨計算
  Y<-25400/CN-254
  Ia<-0.2*Y
  for (i in c(1:144)) {
    ReMatrix[i,8]<-sum(ReMatrix[1:i,7])
    
    if(ReMatrix[i,8]<Ia){
      ReMatrix[i,9]<-ReMatrix[i,8]
    }
    else{
      ReMatrix[i,9]<-Ia
    }
    
    if(ReMatrix[i,8]<Ia){
      ReMatrix[i,10]<-0
    }
    else{
      ReMatrix[i,10]<-S*(ReMatrix[i,8]-Ia)/(ReMatrix[i,8]-Ia+S)
    }
    
    ReMatrix[i,11]<-ReMatrix[i,8]-ReMatrix[i,9]-ReMatrix[i,10]
    if( i==1 ){
      ReMatrix[1,12]<-ReMatrix[1,11]
    }
    else{
      ReMatrix[i,12]<-(ReMatrix[i,11]-ReMatrix[i-1,11])*0.1
    }
  }
  
  
  Re<-as.matrix(cbind(ReMatrix[,1],ReMatrix[,12]))#設計雨型(超滲降雨)
  
  #以設計雨型之超滲降雨&單位歷線計算計算出流歷線
  hydMatrix<-matrix(0,(24/D),(24/D))#出流歷線計算矩陣(僅計算前24小時)
  hydrograph<-matrix(NA,24/D,2)
  
  hydrograph[,1]<-Re[,1]
  colnames(hydMatrix)<-c(1:(24/D))
  for (i in c(1:(24/D))) {#將降雨延時（24 小時）時段中已扣除滲漏損失之每一個單位時間降雨量，套入單位歷線，並依序錯開一個單位時間疊加之。
    if((i+nrow(interpolate_oneCmUnitHyd))>(24/D)){
      jMax<-(24/D)+1-i
    }
    else{
      jMax<-41
    }
    
    for (j in c(1:jMax)) {
      hydMatrix[i+j-1,i]<-Re[i,2]*interpolate_oneCmUnitHyd[j,2]
      
    }
    hydrograph[i,2]<-sum(hydMatrix[i,])
  }

  #輸出有效降雨量的計算過程以及逕流歷線計算結果
  outputmatrix<-as.data.frame(cbind(ReMatrix,hydrograph[,-1]))
  colnames(outputmatrix)<-c("時間(hr)","降雨強度(mm/hr)","累積降雨(mm)","單位時間降雨(mm)","單位時間降雨百分比(%)","設計雨型(%)","設計雨型(mm)","P","Ia","Fa","Pe","超滲降雨RE (cm)","降雨逕流(cms)")
  
  filename<-paste("./output/",fName,".csv",sep = "")
  write.table(outputmatrix,filename,sep = ",",row.names = F)
  
  #輸出單位歷線
  #讀取原本的單位歷線檔案，刪掉原本的，重新寫入新的單位歷線後存檔
  interpolate_oneCmUnitHyd<-round(interpolate_oneCmUnitHyd,digits = 4)
  qOut<-as.data.frame(interpolate_oneCmUnitHyd)
  colnames(qOut)<-c("t",fName)
  colnames(interpolate_oneCmUnitHyd)<-c("t",fName)
  firstTry<-1

  if(file.exists("./output/SCSq.csv")){
    qOut<-as.matrix(read.table("./output/SCSq.csv",sep=",",encoding="UTF-8"))
    colVector<-as.character(qOut[1,])
    colVector<-append(colVector,fName)
    qOut<-as.matrix(read.table("./output/SCSq.csv",sep=",",encoding="UTF-8",skip = 1))
    unlink("./output/SCSq.csv", recursive = TRUE)
    qOut<-as.data.frame( cbind(qOut,interpolate_oneCmUnitHyd[,2]) )
    colnames(qOut)<-colVector
  }
  write.table(qOut,"./output/SCSq.csv",sep = ",",row.names = F)
  
  return(hydrograph)
}
#END OF SCS無因次逕流歷線計算function