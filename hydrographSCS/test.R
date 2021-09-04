setwd("./")
result<-as.matrix(read.csv("output/降雨逕流.csv"))#運算成果
testdata<-as.matrix(read.csv("test/testdata.csv"))#測試資料
testing<-result-testdata
testing<- round(testing, 4)
if(sum(testing>0)==0){
  cat("Passed the test")
}
